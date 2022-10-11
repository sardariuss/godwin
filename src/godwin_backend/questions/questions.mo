import Types "../types";
import PerPool "perPool";
import PerCategorization "perCategorization";
import Queries "queries";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Time = Time.Time;
  type Iter<T> = Iter.Iter<T>;
  // For convenience: from types module
  type Question = Types.Question;
  type Pool = Types.Pool;
  type Categorization = Types.Categorization;
  // For convenience: from other modules
  type QuestionsPerPool = PerPool.QuestionsPerPool;
  type QuestionsPerCategorization = PerCategorization.QuestionsPerCategorization;
  type QuestionKey = Queries.QuestionKey;
  type OrderBy = Queries.OrderBy;
  type QueryDirection = Queries.QueryDirection;

  type Register = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
    per_pool: QuestionsPerPool;
    per_categorization : QuestionsPerCategorization;
  };

  public func emptyRegister() : Register {
    {
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
      per_pool = PerPool.empty();
      per_categorization = PerCategorization.empty();
    };
  };

  public func empty() : Questions {
    Questions(emptyRegister());
  };

  public class Questions(register: Register) {

    var register_ = register;

    public func getRegister() : Register {
      register_;
    };

    public func getQuestion(question_id: Nat) : Question {
      switch(findQuestion(question_id)){
        case(null) { Debug.trap("@todo"); };
        case(?question) { question; };
      };
    };

    public func findQuestion(question_id: Nat) : ?Question {
      Trie.get(register_.questions, Types.keyNat(question_id), Nat.equal);
    };

    public func getQuestionsInPool(pool: Pool, order_by: OrderBy, direction: QueryDirection) : Iter<(QuestionKey, ())> {
      switch(pool){
        case(#SPAWN){ Queries.entries(register_.per_pool.spawn_rbts, order_by, direction); };
        case(#REWARD){ Queries.entries(register_.per_pool.reward_rbts, order_by, direction); };
        case(#ARCHIVE){ Queries.entries(register_.per_pool.archive_rbts, order_by, direction); };
      };
    };

    public func getQuestionsInCategorization(categorization: Categorization, order_by: OrderBy, direction: QueryDirection) : Iter<(QuestionKey, ())> {
      switch(categorization){
        case(#PENDING) { Queries.entries(register_.per_categorization.pending_rbts, order_by, direction); }; 
        case(#ONGOING) { Queries.entries(register_.per_categorization.ongoing_rbts, order_by, direction); }; 
        case(#DONE(_)) { Queries.entries(register_.per_categorization.done_rbts, order_by, direction); }; 
      };
    };

    public func createQuestion(author: Principal, title: Text, text: Text) : Question {
      let time_now = Time.now();
      let question = {
        id = register_.question_index;
        author = author;
        title = title;
        text = text;
        date = time_now;
        endorsements = 0;
        pool = { current = { date = time_now; pool = #SPAWN;}; history = []; };
        categorization = { current = {date = time_now; categorization = #PENDING;}; history = []; };
      };
      register_ := {
        questions = Trie.put(register_.questions, Types.keyNat(question.id), Nat.equal, question).0;
        question_index = register_.question_index + 1;
        per_pool = PerPool.addQuestion(register_.per_pool, question);
        per_categorization = PerCategorization.addQuestion(register_.per_categorization, question);
      };
      question;
    };

    public func replaceQuestion(question: Question) {
      let (questions, removed_question) = Trie.put(register_.questions, Types.keyNat(question.id), Nat.equal, question);
      switch(removed_question){
        case(null) { Debug.trap("Cannot replace a question that does not exist"); };
        case(?old_question) {
          register_ := {
            questions = questions;
            question_index = register_.question_index;
            per_pool = PerPool.replaceQuestion(register_.per_pool, old_question, question);
            per_categorization = PerCategorization.replaceQuestion(register_.per_categorization, old_question, question);
          };
        };
      };
    };

  };

  public func nextQuestion(questions: Questions, iter: Iter<(QuestionKey, ())>) : ?Question {
    switch(iter.next()){
      case(null) { null; };
      case(?(question_key, _)){ ?questions.getQuestion(question_key.id); };
    };
  };

};