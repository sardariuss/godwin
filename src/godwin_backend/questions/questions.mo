import Types "../types";
import PerPool "perPool";
import PerCategorization "perCategorization";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Time = Time.Time;

  // For convenience: from types module
  type Question = Types.Question;

  // For convenience: from other modules
  type QuestionsPerPool = PerPool.QuestionsPerPool;
  type QuestionsPerCategorization = PerCategorization.QuestionsPerCategorization;

  public type QuestionRegister = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
    per_pool: QuestionsPerPool;
    per_categorization : QuestionsPerCategorization;
  };

  public func empty() : QuestionRegister {
    {
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
      per_pool = PerPool.empty();
      per_categorization = PerCategorization.empty();
    };
  };

  public func createQuestion(register: QuestionRegister, author: Principal, title: Text, text: Text) : (QuestionRegister, Question) {
    let question = {
      id = register.question_index;
      author = author;
      title = title;
      text = text;
      endorsements = 0;
      pool = { current = { date = Time.now(); pool = #SPAWN;}; history = []; };
      categorization = { current = {date = Time.now(); categorization = #PENDING;}; history = []; };
    };
    (
      {
        questions = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question).0;
        question_index = register.question_index + 1;
        per_pool = PerPool.addQuestion(register.per_pool, question);
        per_categorization = PerCategorization.addQuestion(register.per_categorization, question);
      },
      question
    );
  };

  public func replaceQuestion(register: QuestionRegister, question: Question) : QuestionRegister {
    let (questions, removed_question) = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question);
    switch(removed_question){
      case(null) { Debug.trap("Cannot replace a question that does not exist"); };
      case(?old_question) {
        {
          questions = questions;
          question_index = register.question_index;
          per_pool = PerPool.replaceQuestion(register.per_pool, old_question, question);
          per_categorization = PerCategorization.replaceQuestion(register.per_categorization, old_question, question);
        };
      };
    };
  };

};