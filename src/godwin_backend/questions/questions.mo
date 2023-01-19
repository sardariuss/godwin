import Types "../types";
import Vote "../votes/vote";
import Question "question";
import Queries "queries";
import Observers "../observers";
import WMap "../wrappers/WMap";
import WRef "../wrappers/WRef";

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
  type Time = Int;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;

  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type Status2 = Types.Status2;
  type Ref<V> = Types.Ref<V>;
  type WRef<V> = WRef.WRef<V>;
  type WMap<K, V> = WMap.WMap<K, V>;

  type UpdateType = {
    #RECORD;
    #FIELD: {
      #CURRENT_STATUS;
    };
  };

  type UpdateCallback = (?Question, ?Question) -> ();

  func equalUpdateType(obs_a: UpdateType, obs_b: UpdateType) : Bool {
    obs_a == obs_b;
  };

  func hashUpdateType(obs: UpdateType) : Hash {
    switch(obs){
      case(#RECORD)                 { 0; };
      case(#FIELD(#CURRENT_STATUS)) { 1; };
    };
  };

  public func build(register: Map<Nat, Question>, index: Ref<Nat>) : Questions {
    Questions(
      WMap.WMap(register, Map.nhash),
      WRef.WRef(index),
      Observers.Observers<UpdateType, Question>(equalUpdateType, hashUpdateType)
    );
  };

  public class Questions(
    register_: WMap<Nat, Question>,
    index_: WRef<Nat>,
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
        id = index_.get();
        author;
        title;
        text;
        date;
        status = #CANDIDATE(Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = 0; }));
        interests_history = [];
        vote_history = [];
        status_info = {
          current = {
            status = #CANDIDATE;
            date;
            index = 0;
          };
          history = [];
          iterations = [(#CANDIDATE, 0)];
        };
      };
      register_.set(question.id, question);
      index_.set(index_.get() + 1);
      observers_.callObs(#RECORD, null, ?question);
      question;
    };

    public func replaceQuestion(question: Question) {
      if (Option.isNull(register_.get(question.id))){
        Debug.trap("Cannot replace a question that does not exist");
      };
      switch(register_.put(question.id, question)){
        case(null) { Prelude.unreachable(); };
        case(?old_question) {
          observers_.callObs(#RECORD, ?old_question, ?question);
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
          observers_.callObs(#RECORD, ?old_question, null);
          old_question;
        };
      };
    };

    public func updateStatus(question_id: Nat, status: Status2, date: Time) {
      let question = Question.updateStatus(getQuestion(question_id), status, date);
      switch(register_.put(question.id, question)){
        case(null) { Prelude.unreachable(); };
        case(?old_question) {
          observers_.callObs(#FIELD(#CURRENT_STATUS), ?old_question, ?question);
        };
      };
    };

    public func next(iter: Iter<Queries.QuestionKey>) : ?Question {
      switch(iter.next()){
        case(null) { null; };
        case(?key){ ?getQuestion(key.id); };
      };
    };

    public func first(queries: Queries.Queries, order_by: Queries.OrderBy, direction: Queries.Direction) : ?Question {
      next(queries.entries(order_by, direction));
    };

    public func queryQuestions(
      queries: Queries.Queries,
      order_by: Queries.OrderBy,
      direction: Queries.Direction,
      limit: Nat,
      previous_id: ?Nat
    ) : Queries.QueryQuestionsResult {
      let bound = Option.chain(previous_id, func(id: Nat) : ?Queries.QuestionKey {
        Queries.initQuestionKey(getQuestion(id), order_by);
      });
      switch(direction){
        case(#FWD){
          queries.queryQuestions(order_by, bound, null, direction, limit);
        };
        case(#BWD){
          queries.queryQuestions(order_by, null, bound, direction, limit);
        };
      };
    };

    public func addObs(update_type: UpdateType, update_callback: UpdateCallback) {
      observers_.addObs(update_type, update_callback);
    };

  };

};