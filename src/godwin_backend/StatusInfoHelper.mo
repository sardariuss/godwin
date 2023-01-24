import Types "Types";
import Utils "Utils";

import Map "mo:map/Map";

import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Time = Int;
  type Buffer<T> = Buffer.Buffer<T>;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;

  // For convenience: from types module
  type Question = Types.Question;
  type QuestionStatus = Types.QuestionStatus;
  type IndexedStatus = Types.IndexedStatus;
  type StatusInfo = Types.StatusInfo;

  public func isHistoryIteration(question: Question, status: QuestionStatus, iteration: Nat) : Bool {
    let helper = StatusInfoHelper(question);
    not (helper.getCurrentStatus() == status and helper.getCurrentIteration() == iteration) 
      and helper.getIteration(status) <= iteration;
  };

  public func isValidIteration(question: Question, status: QuestionStatus, iteration: Nat) : Bool {
    let helper = StatusInfoHelper(question);
    helper.getIteration(status) <= iteration;
  };

  public func isCurrentStatus(question: Question, status: QuestionStatus) : Bool {
    question.status_info.current.status == status;
  };

  public class StatusInfoHelper(question: Question) {

    var current_ = question.status_info.current;
    
    let history_ = Buffer.fromArray<IndexedStatus>(question.status_info.history);

    let iterations_ = Utils.arrayToMap<QuestionStatus, Nat>(question.status_info.iterations, Types.status_hash);

    public func share() : StatusInfo {
      {
        current = current_;
        history = Buffer.toArray(history_);
        iterations = Utils.mapToArray<QuestionStatus, Nat>(iterations_);
      };
    };

    public func setCurrent(status: QuestionStatus, date: Time){
      // Add current to history
      history_.add(current_);
      let index = switch(Map.get(iterations_, Types.status_hash, status)){
        case(null) { Debug.trap("The status index is missing"); };
        case(?idx) { idx + 1; };
      };
      // Set current
      current_ := { status; date; index; };
      // Update iteration index for this status
      Map.set(iterations_, Types.status_hash, status, index);
    };

    public func getIteration(status: QuestionStatus) : Nat {
      switch(Map.get(iterations_, Types.status_hash, status)){
        case(null) { Debug.trap("The status index is missing"); };
        case(?idx) { idx; };
      };
    };

    public func getCurrentStatus() : QuestionStatus {
      current_.status;
    };

    public func getCurrentIteration() : Nat {
      current_.index;
    };

  };

};