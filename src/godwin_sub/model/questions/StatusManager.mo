import Types  "Types";

import Joins  "../votes/QuestionVoteJoins";

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
  type StatusInput      = Types.StatusInput;
  type StatusInfo       = Types.StatusInfo;
  type StatusHistory    = Types.StatusHistory;
  type CursorVotes      = Types.CursorVotes;
  type Joins            = Joins.QuestionVoteJoins;

  public type Register = Map<QuestionId, StatusHistory>;

  public func build(
    register: Register,
    interest_joins: Joins,
    opinion_joins: Joins,
    categorization_joins: Joins
  ) : StatusManager {
    StatusManager(WMap.WMap(register, Map.nhash), interest_joins, opinion_joins, categorization_joins);
  };
  
  // @todo: this class needs a rework
  public class StatusManager(
    _register: WMap.WMap<QuestionId, StatusHistory>,
    _interest_joins: Joins,
    _opinion_joins: Joins,
    _categorization_joins: Joins
  ) {

    public func setStatus(question_id: QuestionId, status: Status, date: Time, opt_input: ?StatusInput) : Nat {
      // Get or create a status history for the question
      let status_history = switch(_register.getOpt(question_id)){
        case(null) { Buffer.init<StatusInfo>(); };
        case(?history) { history; };
      };
      // Deduce the iteration from the last status info
      let iteration = switch(findLastStatusInfo(status_history, status)){
        case(null) { 0 };
        case(?info) { info.iteration + 1; };
      };
      // Join the vote to the question
      switch(status){
        case(#CANDIDATE){
          switch(getInterestVoteId(opt_input)){
            case(null) { Debug.trap("The interest vote id is missing"); };
            case(?vote_id) { _interest_joins.addJoin(question_id, iteration, vote_id); };
          };
        };
        case(#OPEN){
          switch(getCursorVoteIds(opt_input)){
            case(null) { Debug.trap("The cursor votes ids are missing");
            };
            case(?cursor_votes) {
              _opinion_joins.addJoin       (question_id, iteration, cursor_votes.opinion_vote_id       );
              _categorization_joins.addJoin(question_id, iteration, cursor_votes.categorization_vote_id);
            };
          };
        };
        case(_){};
      };
      // Add the new status info to the history
      Buffer.add(status_history, {status; date; iteration;});
      _register.set(question_id, status_history);
      // Return the iteration
      iteration;
    };

    public func getCurrentStatus(question_id: QuestionId) : StatusInfo {
      let status_history = getStatusHistory(question_id);
      let num_statuses : Int = Buffer.size(status_history);
      if (num_statuses == 0) {
        Debug.trap("The status history us empty");
      };
      Buffer.get(status_history, Int.abs(num_statuses - 1));
    };

    public func getStatusHistory(question_id: QuestionId) : StatusHistory {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("The question '" # Nat.toText(question_id) # "' has no status history"); };
        case(?history){ history; };
      };
    };

    public func findStatusInfo(question_id: QuestionId, status: Status, iteration: Nat) : ?StatusInfo {
      let status_history = switch(_register.getOpt(question_id)){
        case(null) { return null; };
        case(?history){ history; };
      };
      for (status_info in Buffer.vals(status_history)){
        if (status_info.status == status and status_info.iteration == iteration){
          return ?status_info;
        };
      };
      return null;
    };

    public func removeStatusHistory(question_id: QuestionId) {
      _register.delete(question_id);
    };

  };

  public func findLastStatusInfo(status_history: StatusHistory, status: Status) : ?StatusInfo {
    var match : ?StatusInfo = null;
    for (status_info in Buffer.vals(status_history)){
      if (status_info.status == status){
        match := ?status_info;
      };
    };
    match;
  };

  func getInterestVoteId(opt_input: ?StatusInput) : ?Nat {
    switch(opt_input){
      case(null) {};
      case(?input) {
        switch(input){
          case(#INTEREST_VOTE(vote_id)) { return ?vote_id; };
          case(_){};
        };
      };
    };
    null;
  };

  func getCursorVoteIds(opt_input: ?StatusInput) : ?CursorVotes {
    switch(opt_input){
      case(null) {};
      case(?input) {
        switch(input){
          case(#CURSOR_VOTES(cursor_votes)) { return ?cursor_votes; };
          case(_){};
        };
      };
    };
    null;
  };

};