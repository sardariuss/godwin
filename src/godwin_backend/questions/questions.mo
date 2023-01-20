import Types "../types";
import Utils "../utils";
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
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Int "mo:base/Int";

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
  type QuestionStatus = Types.QuestionStatus;
  type Ref<V> = Types.Ref<V>;
  type WRef<V> = WRef.WRef<V>;
  type WMap<K, V> = WMap.WMap<K, V>;
  type IndexedStatus = Types.IndexedStatus;

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("title: " # question.title # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
       and Principal.equal(q1.author, q2.author)
       and Text.equal(q1.title, q2.title)
       and Text.equal(q1.text, q2.text)
       and Int.equal(q1.date, q2.date);
  };

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

    public func updateStatus(question_id: Nat, status: QuestionStatus, date: Time) : Question {
      // @todo: create a class StatusInfo
      // Get the question
      var question = getQuestion(question_id);
      // Get status info
      let current = question.status_info.current;
      let history = Buffer.fromArray<IndexedStatus>(question.status_info.history);
      let iterations = Utils.arrayToMap<QuestionStatus, Nat>(question.status_info.iterations, Types.questionStatushash);
      // Add current to history
      history.add(current);
      let index = switch(Map.get(iterations, Types.questionStatushash, status)){
        case(null) { Debug.trap("The status index is missing"); };
        case(?idx) { idx + 1; };
      };
      // Update iteration index for this status
      Map.set(iterations, Types.questionStatushash, status, index);
      // Return the updated status info
      question := { question with status_info = 
        {
          current = { status; date; index; };
          history = Buffer.toArray(history);
          iterations = Utils.mapToArray<QuestionStatus, Nat>(iterations);
        };
      };
      // @todo: use update method instead
      switch(register_.put(question.id, question)){
        case(null) { Prelude.unreachable(); };
        case(?old_question) {
          observers_.callObs(#FIELD(#CURRENT_STATUS), ?old_question, ?question);
        };
      };

      question;
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