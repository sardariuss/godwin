import Types "types";
import Pool "pool";

import RBT "mo:stableRBT/StableRBTree";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Time.Time;
  type Order = Order.Order;
  type Iter<T> = Iter.Iter<T>;

  // For convenience: from types module
  type Question = Types.Question;
  type Categorization = Types.Categorization;
  type Pool = Types.Pool;

  func compareDateEntry(a: DateEntry, b: DateEntry) : Order {
    if (a.date < b.date) {
      return #less;
    } else if (a.date > b.date) {
      return #greater;
    } else {
      if (a.question_id < b.question_id) {
        return #less;
      } else if (a.question_id > b.question_id) {
        return #greater;
      } else {
        return #equal;
      };
    };
  };

  type DateEntry = {
    date: Time;
    question_id: Nat;
  };

  func compareEndorsementEntry(a: EndorsementEntry, b: EndorsementEntry) : Order {
    if (a.endorsement < b.endorsement) {
      return #less;
    } else if (a.endorsement > b.endorsement) {
      return #greater;
    } else {
      if (a.question_id < b.question_id) {
        return #less;
      } else if (a.question_id > b.question_id) {
        return #greater;
      } else {
        return #equal;
      };
    };
  };

  type EndorsementEntry = {
    endorsement: Nat;
    question_id: Nat;
  };

  type QuestionRegister = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
    questions_by_date: RBT.Tree<DateEntry, ()>;
    questions_by_endorsement: RBT.Tree<EndorsementEntry, ()>;
  };

  public func empty() : QuestionRegister {
    {
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
      questions_by_date = RBT.init<DateEntry, ()>();
      questions_by_endorsement = RBT.init<EndorsementEntry, ()>();
    };
  };

  public func createQuestion(register: QuestionRegister, author: Principal, title: Text, text: Text) : (QuestionRegister, Question) {
    let question = {
      id = register.question_index;
      author = author;
      title = title;
      text = text;
      endorsements = 0;
      pool = {
        current = {date = Time.now(); pool = #SPAWN;};
        history = [{date = Time.now(); pool = #SPAWN;}];
      };
      categorization = #PENDING;
    };
    (
      {
        questions = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question).0;
        question_index = register.question_index + 1;
        questions_by_date = RBT.put(register.questions_by_date, compareDateEntry, {date = Time.now(); question_id = question.id; }, ());
        questions_by_endorsement = RBT.put(register.questions_by_endorsement, compareEndorsementEntry, {endorsement = question.endorsements; question_id = question.id; }, ());
      },
      question
    );
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };
  
  public func getQuestion(register: QuestionRegister, question_id: Nat) : Result<Question, GetQuestionError> {
    switch(Trie.get<Nat, Question>(register.questions, Types.keyNat(question_id), Nat.equal)){
      case(null){
        #err(#QuestionNotFound);
      };
      case(?question){
        #ok(question);
      };
    };
  };

  public func iter(register: QuestionRegister) : Iter<(Nat, Question)> {
    return Trie.iter(register.questions);
  };

  public func replaceQuestion(register: QuestionRegister, question: Question) : (QuestionRegister, ?Question) {
    let (questions, removed_question) = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question);
    var questions_by_endorsement = register.questions_by_endorsement;
    switch(removed_question){
      case(null){};
      case(?old_question){
        if (old_question.endorsements != question.endorsements){
          questions_by_endorsement := RBT.remove(questions_by_endorsement, compareEndorsementEntry, {endorsement = old_question.endorsements; question_id = question.id; }).1;
          questions_by_endorsement := RBT.put(questions_by_endorsement, compareEndorsementEntry, {endorsement = question.endorsements; question_id = question.id; }, ());
        };
      };
    };
    (
      {
        questions = questions;
        question_index = register.question_index;
        questions_by_date = register.questions_by_date;
        questions_by_endorsement = questions_by_endorsement;
      },
      removed_question
    );
  };

  public func updateCategorization(register: QuestionRegister, question: Question, categorization: Categorization) : (QuestionRegister, ?Question) {
    let updated_question = {
      id = question.id;
      author = question.author;
      endorsements = question.endorsements;
      title = question.title;
      text = question.text;
      pool = question.pool;
      categorization = categorization;
    };
    replaceQuestion(register, updated_question);
  };

  public func getMostEndorsed(register: QuestionRegister, pool: Pool) : ?Question {
    for ((endorsement_entry, _) in RBT.entriesRev(register.questions_by_endorsement)){
      switch(Trie.get<Nat, Question>(register.questions, Types.keyNat(endorsement_entry.question_id), Nat.equal)){
        case(null){ 
          Debug.trap("Cannot find question in questions_by_endorsement linked to EndorsementEntry");
        };
        case(?question){
          if (question.pool.current.pool == pool) {
            return ?question;
          };
        };
      };
    };
    return null;
  };

};