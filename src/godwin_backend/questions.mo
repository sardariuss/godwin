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

  public type QuestionRegister = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
    questions_by_date: RBT.Tree<DateEntry, ()>;
  };

  public func empty() : QuestionRegister {
    {
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
      questions_by_date = RBT.init<DateEntry, ()>();
    }
  };

  public func createQuestion(register: QuestionRegister, author: Principal, title: Text, text: Text) : (QuestionRegister, Question) {
    let question = {
      id = register.question_index;
      author = author;
      title = title;
      text = text;
      categories = [];
      pool_history = Pool.initPoolHistory();
    };
    (
      {
        questions = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question).0;
        question_index = register.question_index + 1;
        questions_by_date = RBT.put(register.questions_by_date, compareDateEntry, {date = Time.now(); question_id = question.id; }, ());
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
    let put_result = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question);
    (
      {
        questions = put_result.0;
        question_index = register.question_index;
        questions_by_date = register.questions_by_date;
      },
      put_result.1
    );
  };

};