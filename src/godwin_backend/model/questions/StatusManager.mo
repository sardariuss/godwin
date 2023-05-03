import Types           "Types";
import Status          "Status";

import Utils           "../../utils/Utils";
import WMap            "../../utils/wrappers/WMap";

import Map             "mo:map/Map";

import Debug           "mo:base/Debug";
import Option          "mo:base/Option";
import Nat             "mo:base/Nat";

module {

  // For convenience: from base module
  type Time        = Int;

  // For convenience: from map module
  type Map<K, V>   = Map.Map<K, V>;
  type WMap<K, V>  = WMap.WMap<K, V>;

  // For convenience: from types module
  type Question    = Types.Question;
  type Status      = Types.Status;
  type StatusInfo  = Types.StatusInfo;
  type QuestionId  = Types.QuestionId;
  type StatusData  = Types.StatusData;
  let questionHash = Types.questionHash;

  public type Register = Map<QuestionId, StatusData>;

  public func build(register: Register) : StatusManager {
    StatusManager(WMap.WMap(register, questionHash));
  };
  
  public class StatusManager(_register: WMap.WMap<QuestionId, StatusData>) {

    public func setCurrent(question_id: QuestionId, status: Status, date: Time) {
      switch(_register.getOpt(question_id)){
        case(null) { 
          // Create a new entry with an empty history
          _register.set(question_id, { var current = { status; date; iteration = 0; }; history = Map.new<Status, [Time]>(Status.status_hash); }); 
        };
        case(?status_data) {
          // Add the (previous) current status to the history
          var iterations = Option.get(Map.get(status_data.history, Status.status_hash, status_data.current.status), []);
          iterations := Utils.append<Time>(iterations, [status_data.current.date]);
          Map.set(status_data.history, Status.status_hash, status_data.current.status, iterations);
          // Update the current status
          status_data.current := { status; date; iteration = Option.get(Map.get(status_data.history, Status.status_hash, status), []).size(); };
        };
      };
    };

    public func getCurrent(question_id: QuestionId) : StatusInfo {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("Not status data found for the question with id='" # Nat.toText(question_id) # "'") };
        case(?status_data) { status_data.current; };
      };
    };

    public func getHistory(question_id: QuestionId) : Map<Status, [Time]> {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("Not status data found for the question with id='" # Nat.toText(question_id) # "'") };
        case(?status_data) { status_data.history; };
      };
    };

    public func getStatusIteration(question_id: QuestionId, status: Status) : Nat {
      // Get the status data
      let status_data = switch(_register.getOpt(question_id)){
        case(null) { return 0; };
        case(?data) { data; };
      };
      // Get the status info
      let status_history = switch(Map.get(status_data.history, Status.status_hash, status)){
        case(null) { return 0; };
        case(?history) { history; };
      };
      // Return the size
      status_history.size();
    };

    public func deleteStatus(question_id: QuestionId) {
      _register.delete(question_id);
    };

  };

};