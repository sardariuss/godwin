import Types  "Types";

import WMap   "../../utils/wrappers/WMap";

import Buffer "mo:stablebuffer/StableBuffer";
import Map    "mo:map/Map";

import Debug  "mo:base/Debug";
import Option "mo:base/Option";
import Int    "mo:base/Int";
import Nat    "mo:base/Nat";

module {

  // For convenience: from base module
  type Time             = Int;

  // For convenience: from map module
  type Map<K, V>        = Map.Map<K, V>;
  type WMap<K, V>       = WMap.WMap<K, V>;
  type Buffer<T>        = Buffer.StableBuffer<T>;

  // For convenience: from types module
  type Question         = Types.Question;
  type Status           = Types.Status;
  type QuestionId       = Types.QuestionId;
  type StatusInfo       = Types.StatusInfo;
  type StatusHistory    = Types.StatusHistory;
  type IterationHistory = Types.IterationHistory;

  public type Register = Map<QuestionId, IterationHistory>;

  public func build(register: Register) : StatusManager {
    StatusManager(WMap.WMap(register, Map.nhash));
  };
  
  public class StatusManager(_register: WMap.WMap<QuestionId, IterationHistory>) {

    public func newIteration(question_id: QuestionId) : Nat {
      let iteration_history = Option.get(_register.getOpt(question_id), Buffer.init<StatusHistory>());
      let status_history = Buffer.init<StatusInfo>();
      Buffer.add(iteration_history, status_history);
      _register.set(question_id, iteration_history);
      Int.abs(Buffer.size(iteration_history) - 1);
    };

    public func setCurrentStatus(question_id: QuestionId, status: Status, date: Time) {
      let (iteration, status_history) = getCurrentStatusHistory(question_id);
      Buffer.add(status_history, {status; date;});
    };

    public func getCurrentStatus(question_id: QuestionId) : (Nat, StatusInfo) {
      let (iteration, status_history) = getCurrentStatusHistory(question_id);
      let num_statuses : Int = Buffer.size(status_history);
      if (num_statuses == 0) {
        Debug.trap("Current iteration has an empty status history");
      };
      (iteration, Buffer.get(status_history, Int.abs(num_statuses - 1)));
    };

    public func getIterationHistory(question_id: QuestionId): IterationHistory {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("The question '" # Nat.toText(question_id) # "' has no iterations history"); };
        case(?it_history){ it_history; };
      };
    };

    public func removeIterationHistory(question_id: QuestionId) {
      _register.delete(question_id);
    };

    func getCurrentStatusHistory(question_id: QuestionId) : (Nat, StatusHistory) {
      let iteration_history = switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("The question '" # Nat.toText(question_id) # "' has no iterations history"); };
        case(?it_history){ it_history; };
      };
      let num_iterations : Int = Buffer.size(iteration_history);
      if (num_iterations == 0) {
        Debug.trap("The question '" # Nat.toText(question_id) # "' has an empty iterations history");
      };
      let last_iteration = Int.abs(num_iterations - 1);
      (last_iteration, Buffer.get(iteration_history, last_iteration));
    };

  };

  public func findStatusInfo(iteration_history: IterationHistory, status: Status, iteration: Nat) : ?StatusInfo {
    if (iteration >= Buffer.size(iteration_history)){
      return null;
    };
    let status_history = Buffer.get(iteration_history, iteration);
    for (status_info in Buffer.vals(status_history)){
      if (status_info.status == status){
        return ?status_info;
      };
    };
    null;
  };

};