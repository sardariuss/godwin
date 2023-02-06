import Types "Types";
import Utils "../utils/Utils";

import Map "mo:map/Map";

import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Time = Int;
  type Buffer<T> = Buffer.Buffer<T>;
  type Iter<T> = Iter.Iter<T>;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;

  // For convenience: from types module
  type Question = Types.Question;
  type Status = Types.Status;
  type IndexedStatus = Types.IndexedStatus;
  type Poll = Types.Poll;

  public func statusToText(status: Status) : Text {
    switch(status){
      case(#VOTING(#INTEREST))       { "VOTING(INTEREST)"; };
      case(#VOTING(#OPINION))        { "VOTING(OPINION)"; };
      case(#VOTING(#CATEGORIZATION)) { "VOTING(CATEGORIZATION)"; };
      case(#CLOSED)                  { "CLOSED"; };
      case(#REJECTED)                { "REJECTED"; };
      case(#TRASH)                   { "TRASH"; };
    };
  };

  public func hashStatus(a: Status) : Nat { Map.thash.0(statusToText(a)); };
  public func equalStatus(a: Status, b: Status) : Bool { Map.thash.1(statusToText(a), statusToText(b)); };
  public let status_hash : Map.HashUtils<Status> = ( func(a) = hashStatus(a), func(a, b) = equalStatus(a, b));

  public func isHistoryIteration(question: Question, status: Status, iteration: Nat) : Bool {
    let helper = StatusInfo(question.status_info);
    not (helper.getCurrentStatus() == status and helper.getCurrentIteration() == iteration) 
      and helper.getIteration(status) <= iteration;
  };

  public func isValidIteration(question: Question, status: Status, iteration: Nat) : Bool {
    let helper = StatusInfo(question.status_info);
    helper.getIteration(status) <= iteration;
  };

  public func isCurrentStatus(question: Question, status: Status) : Bool {
    question.status_info.current.status == status;
  };

  public func getCurrentPoll(question: Question) : ?Poll {
    switch(question.status_info.current.status){
      case(#VOTING(poll)) { ?poll; };
      case(_)             { null;  };
    };
  };

  public func iterateVotingStatus(question: Question, f: Poll -> ()) {
    switch(question.status_info.current.status){
      case(#VOTING(poll)) { f(poll); };
      case(_){};
    };
  };

  public func getCurrentStatus(question: Question) : Status {
    question.status_info.current.status;
  };

  public func getCurrent(question: Question) : IndexedStatus {
    question.status_info.current;
  };

  public func getIteration(question: Question, status: Status) : Nat {
    StatusInfo(question.status_info).getIteration(status);
  };

  public func getIterations(question: Question, status: Status) : Iter<Nat> {
    StatusInfo(question.status_info).getIterations(status);
  };

  public func initStatusInfo(date: Time) : Types.StatusInfo {
    {
      current = {
        status = #VOTING(#INTEREST);
        date;
        index = 0;
      };
      history = [];
      iterations = [(#VOTING(#INTEREST), 0)];
    };
  };

  public func updateStatusInfo(question: Question, status: Status, date: Time) : Question {
    let helper = StatusInfo(question.status_info);
    helper.setCurrent(status, date);
    {
      question with status_info = helper.share();
    };
  };

  public class StatusInfo(status_info: Types.StatusInfo) {

    var current_ = status_info.current;
    
    let history_ = Buffer.fromArray<IndexedStatus>(status_info.history);

    let iterations_ = Utils.arrayToMap<Status, Nat>(status_info.iterations, status_hash);

    public func share() : Types.StatusInfo {
      {
        current = current_;
        history = Buffer.toArray(history_);
        iterations = Utils.mapToArray<Status, Nat>(iterations_);
      };
    };

    public func setCurrent(status: Status, date: Time){
      // Add current to history
      history_.add(current_);
      let index = switch(Map.get(iterations_, status_hash, status)){
        case(null) { 0; };
        case(?idx) { idx + 1; };
      };
      // Set current
      current_ := { status; date; index; };
      // Update iteration index for this status
      Map.set(iterations_, status_hash, status, index);
    };

    public func getIteration(status: Status) : Nat {
      switch(Map.get(iterations_, status_hash, status)){
        case(null) { Debug.trap("The status index is missing"); };
        case(?idx) { idx; };
      };
    };

    public func getIterations(status: Status) : Iter<Nat> {
      switch(Map.get(iterations_, status_hash, status)){
        case(null) { Debug.trap("The status index is missing"); };
        case(?idx) { Iter.range(0, idx); };
      };
    };

    public func getCurrentStatus() : Status {
      current_.status;
    };

    public func getCurrentIteration() : Nat {
      current_.index;
    };

  };

};