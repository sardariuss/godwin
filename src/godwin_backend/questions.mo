import Types "types";
import Pools "pools";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Time.Time;

  // For convenience: from types module
  type Question = Types.Question;

  // @todo
  type QuestionPools = Pools.QuestionPools;

  type QuestionRegister = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
    pools: QuestionPools;
  };

  public func empty() : QuestionRegister {
    {
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
      pools = Pools.empty();
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
        pools = Pools.addQuestion(register.pools, question);
      },
      question
    );
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };
  
  public func getQuestion(register: QuestionRegister, question_id: Nat) : Result<Question, GetQuestionError> {
    switch(Trie.get(register.questions, Types.keyNat(question_id), Nat.equal)){
      case(null){ #err(#QuestionNotFound); };
      case(?question){ #ok(question); };
    };
  };

  public func replaceQuestion(register: QuestionRegister, question: Question) : QuestionRegister {
    let (questions, removed_question) = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question);
    switch(removed_question){
      case(null) { Debug.trap("Cannot replace a question that does not exist"); };
      case(?old_question) {
        {
          questions = questions;
          question_index = register.question_index;
          pools = Pools.replaceQuestion(register.pools, old_question, question);
        };
      };
    };
  };

};