import Types "../types";
import Interests "../votes/interests";
import Vote "../votes/vote";
import Queries "queries";

import Trie "mo:base/Trie";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Iter<T> = Iter.Iter<T>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  type Vote<B, A> = Types.Vote<B, A>;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;

  type Time = Int;

  public type Register = {
    questions: Trie<Nat32, Question>;
    question_index: Nat32;
    rbts: Queries.QuestionRBTs;
  };

  public func empty() : Register {
    var rbts = Queries.init();
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#CANDIDATE));
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#OPEN(#OPINION)));
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#OPEN(#CATEGORIZATION)));
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#CLOSED));
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#REJECTED));
    rbts := Queries.addOrderBy(rbts, #INTEREST);
    {
      questions = Trie.empty<Nat32, Question>();
      question_index = 0;
      rbts;
    };
  };

  public func getQuestion(register: Register, question_id: Nat32) : Question {
    switch(findQuestion(register, question_id)){
      case(null) { Debug.trap("The question does not exist."); };
      case(?question) { question; };
    };
  };

  public func findQuestion(register: Register, question_id: Nat32) : ?Question {
    Trie.get(register.questions, Types.keyNat32(question_id), Nat32.equal);
  };

  public func createQuestion(register: Register, author: Principal, date: Time, title: Text, text: Text) : (Register, Question) {
    let question = {
      id = register.question_index;
      author;
      title;
      text;
      date;
      status = #CANDIDATE(Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = 0; }));
      interests_history = [];
      vote_history = [];
    };
    (
      {
        questions = Trie.put(register.questions, Types.keyNat32(question.id), Nat32.equal, question).0;
        question_index = register.question_index + 1;
        rbts = Queries.add(register.rbts, question);
      },
      question
    );
  };

  public func replaceQuestion(register: Register, question: Question) : Register {
    let (questions, removed_question) = Trie.put(register.questions, Types.keyNat32(question.id), Nat32.equal, question);
    switch(removed_question){
      case(null) { Debug.trap("Cannot replace a question that does not exist"); };
      case(?old_question) {
        { register with questions; rbts = Queries.replace(register.rbts, old_question, question); };
      };
    };
  };

  public func removeQuestion(register: Register, question_id: Nat32) : (Register, Question) {
    let (questions, removed_question) = Trie.remove(register.questions, Types.keyNat32(question_id), Nat32.equal);
    switch(removed_question){
      case(null) { Debug.trap("Cannot remove a question that does not exist"); };
      case(?old_question){
        (
          { register with questions; rbts = Queries.remove(register.rbts, old_question); },
          old_question
        );
      };
    };
  };

  public func iter(register: Register, order_by: Queries.OrderBy, direction: Queries.QueryDirection) : Iter<(Queries.QuestionKey, ())>{
    Queries.entries(register.rbts, order_by, direction);
  };

  public func next(register: Register, iter: Iter<(Queries.QuestionKey, ())>) : ?Question {
    switch(iter.next()){
      case(null) { null; };
      case(?(question_key, _)){ 
        ?getQuestion(register, question_key.id); 
      };
    };
  };

  public func first(register: Register, order_by: Queries.OrderBy, direction: Queries.QueryDirection) : ?Question {
    next(register, iter(register, order_by, direction));
  };

  public func queryQuestions(
    register: Register,
    order_by: Queries.OrderBy,
    direction: Queries.QueryDirection,
    limit: Nat
  ) : Queries.QueryQuestionsResult {
    Queries.queryQuestions(register.rbts, order_by, null, null, direction, limit);
  };

};