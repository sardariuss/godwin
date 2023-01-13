import Types "../types";
import Vote "../votes/vote";
import Queries "queries";
import Observers "../observers";

import Trie "mo:base/Trie";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Hash "mo:base/Hash";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Iter<T> = Iter.Iter<T>;
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;
  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;

  public type Register = {
    var questions: Trie<Nat32, Question>;
    var question_index: Nat32;
  };

  public func initRegister() : Register {
    {
      var questions = Trie.empty<Nat32, Question>();
      var question_index = 0;
    };
  };

  type UpdateType = {
    #QUESTION_ADDED;
    #QUESTION_REMOVED;
  };

  type UpdateCallback = (Question) -> ();

  func equalUpdateType(obs_a: UpdateType, obs_b: UpdateType) : Bool {
    obs_a == obs_b;
  };

  func hashUpdateType(obs: UpdateType) : Hash {
    switch(obs){
      case(#QUESTION_ADDED) { 0; };
      case(#QUESTION_REMOVED) { 1; };
    };
  };

  public class Questions(register: Register) {

    let register_ = register;
    let observers_ = Observers.Observers<UpdateType, Question>(equalUpdateType, hashUpdateType);

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
      observers_.callObs(#QUESTION_ADDED, question);
      question;
    };

    public func replaceQuestion(question: Question) {
      let (questions, removed_question) = Trie.put(register_.questions, Types.keyNat32(question.id), Nat32.equal, question);
      switch(removed_question){
        case(null) { Debug.trap("Cannot replace a question that does not exist"); };
        case(?old_question) {
          register_.questions := questions;
          observers_.callObs(#QUESTION_REMOVED, old_question);
          observers_.callObs(#QUESTION_ADDED,   question    );
        };
      };
    };

    public func removeQuestion(question_id: Nat32) : Question {
      let (questions, removed_question) = Trie.remove(register_.questions, Types.keyNat32(question_id), Nat32.equal);
      switch(removed_question){
        case(null) { Debug.trap("Cannot remove a question that does not exist"); };
        case(?old_question){
          register_.questions := questions;
          observers_.callObs(#QUESTION_REMOVED, old_question);
          old_question;
        };
      };
    };

    public func next(iter: Iter<(Queries.QuestionKey, ())>) : ?Question {
      switch(iter.next()){
        case(null) { null; };
        case(?(question_key, _)){ 
          ?getQuestion(question_key.id); 
        };
      };
    };

    public func first(queries: Queries.Queries, order_by: Queries.OrderBy, direction: Queries.QueryDirection) : ?Question {
      next(queries.entries(order_by, direction));
    };

    public func queryQuestions(
      queries: Queries.Queries,
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
          queries.queryQuestions(order_by, bound, null, direction, limit);
        };
        case(#bwd){
          queries.queryQuestions(order_by, null, bound, direction, limit);
        };
      };
    };

    public func addObs(update_type: UpdateType, update_callback: UpdateCallback) {
      observers_.addObs(update_type, update_callback);
    };

  };

};