import Types "../types";
import Vote "../votes/vote";
import Queries "queries";

import Trie "mo:base/Trie";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Iter<T> = Iter.Iter<T>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;

  public type Register = {
    var questions: Trie<Nat32, Question>;
    var question_index: Nat32;
    var rbts: Queries.QuestionRBTs;
  };

  public func initRegister() : Register {
    var rbts = Queries.init();
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#CANDIDATE));
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#OPEN(#OPINION)));
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#OPEN(#CATEGORIZATION)));
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#CLOSED));
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#REJECTED));
    rbts := Queries.addOrderBy(rbts, #INTEREST);
    {
      var questions = Trie.empty<Nat32, Question>();
      var question_index = 0;
      var rbts;
    };
  };

  public class Questions(register: Register) {

    let register_ = register;

    public func getQuestion(question_id: Nat32) : Question {
      switch(findQuestion(question_id)){
        case(null) { Debug.trap("The question does not exist."); };
        case(?question) { question; };
      };
    };

    public func findQuestion(question_id: Nat32) : ?Question {
      Trie.get(register_.questions, Types.keyNat32(question_id), Nat32.equal);
    };

    public func createQuestion(author: Principal, date: Int, title: Text, text: Text) : Question {
      let question = {
        id = register_.question_index;
        author;
        title;
        text;
        date;
        status = #CANDIDATE(Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = 0; }));
        interests_history = [];
        vote_history = [];
      };
      register_.questions := Trie.put(register_.questions, Types.keyNat32(question.id), Nat32.equal, question).0;
      register_.question_index := register_.question_index + 1;
      register_.rbts := Queries.add(register_.rbts, question);
      question;
    };

    public func replaceQuestion(question: Question) {
      let (questions, removed_question) = Trie.put(register_.questions, Types.keyNat32(question.id), Nat32.equal, question);
      switch(removed_question){
        case(null) { Debug.trap("Cannot replace a question that does not exist"); };
        case(?old_question) {
          register_.questions := questions;
          register_.rbts := Queries.replace(register_.rbts, old_question, question);
        };
      };
    };

    public func removeQuestion(question_id: Nat32) : Question {
      let (questions, removed_question) = Trie.remove(register_.questions, Types.keyNat32(question_id), Nat32.equal);
      switch(removed_question){
        case(null) { Debug.trap("Cannot remove a question that does not exist"); };
        case(?old_question){
          register_.questions := questions;
          register_.rbts := Queries.remove(register_.rbts, old_question);
          old_question;
        };
      };
    };

    public func iter(order_by: Queries.OrderBy, direction: Queries.QueryDirection) : Iter<(Queries.QuestionKey, ())>{
      Queries.entries(register_.rbts, order_by, direction);
    };

    public func next(iter: Iter<(Queries.QuestionKey, ())>) : ?Question {
      switch(iter.next()){
        case(null) { null; };
        case(?(question_key, _)){ 
          ?getQuestion(question_key.id); 
        };
      };
    };

    public func first(order_by: Queries.OrderBy, direction: Queries.QueryDirection) : ?Question {
      next(iter(order_by, direction));
    };

    public func queryQuestions(
      order_by: Queries.OrderBy,
      direction: Queries.QueryDirection,
      limit: Nat,
      previous_id: ?Nat32
    ) : Queries.QueryQuestionsResult {
      let bound = Option.chain(previous_id, func(id: Nat32) : ?Queries.QuestionKey {
        Queries.initQuestionKey(getQuestion(id), order_by);
      });
      switch(direction){
        case(#fwd){
          Queries.queryQuestions(register_.rbts, order_by, bound, null, direction, limit);
        };
        case(#bwd){
          Queries.queryQuestions(register_.rbts, order_by, null, bound, direction, limit);
        };
      };
    };

  };

};