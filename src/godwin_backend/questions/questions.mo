import Types "../types";
import Vote "../votes/vote";
import Queries "queries";
import Observers "../observers";
import WrappedRef "../ref/wrappedRef";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Hash "mo:base/Hash";

module {

  // For convenience: from base module
  type Iter<T> = Iter.Iter<T>;
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;

  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type WrappedRef<T> = WrappedRef.WrappedRef<T>;
  type WMap<K, V> = WMap.WMap<K, V>;

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

  public func build(register: Map<Nat, Question>, index: WrappedRef<Nat>) : Questions {
    Questions(
      WMap.WMap(register, Map.nhash),
      index,
      Observers.Observers<UpdateType, Question>(equalUpdateType, hashUpdateType)
    );
  };

  public class Questions(
    register_: WMap<Nat, Question>,
    index_: WrappedRef<Nat>,
    observers_: Observers.Observers<UpdateType, Question>
  ) {

    public func getQuestion(question_id: Nat) : Question {
      switch(findQuestion(question_id)){
        case(null) { Debug.trap("The question does not exist."); };
        case(?question) { question; };
      };
    };

    public func findQuestion(question_id: Nat) : ?Question {
      register_.get(question_id);
    };

    public func createQuestion(author: Principal, date: Int, title: Text, text: Text) : Question {
      let question = {
        id = index_.ref;
        author;
        title;
        text;
        date;
        status = #CANDIDATE(Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = 0; }));
        interests_history = [];
        vote_history = [];
      };
      register_.set(question.id, question);
      index_.ref := index_.ref + 1;
      observers_.callObs(#QUESTION_ADDED, question);
      question;
    };

    public func replaceQuestion(question: Question) {
      if (Option.isNull(register_.get(question.id))){
        Debug.trap("Cannot replace a question that does not exist");
      };
      switch(register_.put(question.id, question)){
        case(null) { Prelude.unreachable(); };
        case(?old_question) {
          observers_.callObs(#QUESTION_REMOVED, old_question);
          observers_.callObs(#QUESTION_ADDED,   question    );
        };
      };
    };

    public func removeQuestion(question_id: Nat) : Question {
      if (Option.isNull(register_.get(question_id))){
        Debug.trap("Cannot remove a question that does not exist");
      };
      switch(register_.remove(question_id)){
        case(null) { Prelude.unreachable(); };
        case(?old_question) {
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
      previous_id: ?Nat
    ) : Queries.QueryQuestionsResult {
      let bound = Option.chain(previous_id, func(id: Nat) : ?Queries.QuestionKey {
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