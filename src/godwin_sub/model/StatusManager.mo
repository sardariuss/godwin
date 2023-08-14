import Status   "questions/Status";
import VoteKind "votes/VoteKind";
import Types    "../stable/Types";

import Joins    "votes/QuestionVoteJoins";

import WMap     "../utils/wrappers/WMap";
import Duration "../utils/Duration";

import Buffer   "mo:stablebuffer/StableBuffer";
import Map      "mo:map/Map";

import Debug    "mo:base/Debug";
import Option   "mo:base/Option";
import Int      "mo:base/Int";
import Nat      "mo:base/Nat";
import Array    "mo:base/Array";

module {

  // For convenience: from base module
  type Time             = Int;

  // For convenience: from map module
  type Map<K, V>        = Map.Map<K, V>;
  type WMap<K, V>       = WMap.WMap<K, V>;
  type Buffer<T>        = Buffer.StableBuffer<T>;

  // For convenience: from types module
  type Question            = Types.Current.Question;
  type Status              = Types.Current.Status;
  type QuestionId          = Types.Current.QuestionId;
  type StatusInfo          = Types.Current.StatusInfo;
  type StatusHistory       = Types.Current.StatusHistory;
  type VoteKind            = Types.Current.VoteKind;
  type VoteLink            = Types.Current.VoteLink;
  type SchedulerParameters = Types.Current.SchedulerParameters;
  type Joins               = Joins.QuestionVoteJoins;

  public type Register = Map<QuestionId, StatusHistory>;

  let OPENED_VOTES_PER_STATUS : [(Status, [VoteKind])] = [
    (#CANDIDATE,            [#INTEREST ]               ),
    (#OPEN,                 [#OPINION, #CATEGORIZATION]),
    (#CLOSED,               []                         ),
    (#REJECTED(#TIMED_OUT), []                         ),
    (#REJECTED(#CENSORED),  []                         ),
  ];

  public func getRequiredVotes(status: Status) : [VoteKind] {
    for (required_votes in Array.vals(OPENED_VOTES_PER_STATUS)){
      if (required_votes.0 == status){
        return required_votes.1;
      };
    };
    Debug.trap("The status '" # Status.toText(status) # "' is missing in the OPENED_VOTES_PER_STATUS map");
  };

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

    public func setCurrentStatus(question_id: QuestionId, status: Status, date: Time, votes: [VoteLink]) : StatusInfo {
      // Get or create a status history for the question
      let status_history = switch(_register.getOpt(question_id)){
        case(null) { Buffer.init<StatusInfo>(); };
        case(?history) { history; };
      };
      // Deduce the iteration from the last status info
      let iteration = switch(findLastStatusInfoFromHistory(status_history, status)){
        case(null) { 0 };
        case(?(_, info)) { info.iteration + 1; };
      };
      let required_votes = getRequiredVotes(status);
      // Verify that there is the expected number of votes
      if (required_votes.size() != votes.size()){
        Debug.trap("Cannot set status of the question '" # Nat.toText(question_id) # "': it has an invalid number of votes");
      };
      // Add a join for each vote. We iterate on the required votes because we can 
      // reasonably assume there is only one kind of vote in the hard-coded map.
      for (vote_kind in Array.vals(required_votes)){
        let kind_links = Array.filter(votes, func(vote_link: VoteLink) : Bool { vote_link.vote_kind == vote_kind; });
        if (kind_links.size() != 1){
          Debug.trap("Cannot set status of the question '" # Nat.toText(question_id) # "': there is either none or too many votes for the kind '" # VoteKind.toText(vote_kind) # "'");
        } else switch(kind_links[0].vote_kind){
          case(#INTEREST      ) { _interest_joins.addJoin      (question_id, iteration, kind_links[0].vote_id); };
          case(#OPINION       ) { _opinion_joins.addJoin       (question_id, iteration, kind_links[0].vote_id); };
          case(#CATEGORIZATION) { _categorization_joins.addJoin(question_id, iteration, kind_links[0].vote_id); };
        };
      };
      let status_info = {status; date; iteration; votes;};
      // Add the new status info to the history
      Buffer.add(status_history, status_info);
      _register.set(question_id, status_history);
      // Return the status info
      status_info;
    };

    public func getCurrentStatus(question_id: QuestionId) : (Nat, StatusInfo) {
      let status_history = getStatusHistory(question_id);
      let num_statuses : Int = Buffer.size(status_history);
      if (num_statuses == 0) {
        Debug.trap("The status history us empty");
      };
      let last_index = Int.abs(num_statuses - 1);
      (last_index, Buffer.get(status_history, last_index));
    };

    public func getStatus(question_id: QuestionId, index: Nat) : StatusInfo {
      let status_history = getStatusHistory(question_id);
      let num_statuses : Int = Buffer.size(status_history);
      if (index > num_statuses - 1) {
        Debug.trap("The index is greater than the number of statuses");
      } else {
        Buffer.get(status_history, index);
      };
    };

    public func getStatusHistory(question_id: QuestionId) : StatusHistory {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("The question '" # Nat.toText(question_id) # "' has no status history"); };
        case(?history){ history; };
      };
    };

    // Return the index and status
    public func findLastStatusInfo(question_id: QuestionId, status: Status) : ?(Nat, StatusInfo) {
      let status_history = getStatusHistory(question_id);
      findLastStatusInfoFromHistory(status_history, status);
    };

    public func getLastStatusInfo(question_id: QuestionId, status: Status) : (Nat, StatusInfo) {
      switch(findLastStatusInfo(question_id, status)){
        case(null) { Debug.trap("Cannot find the last status info for the status '" # Status.toText(status) # "'"); };
        case(?match) { match; };
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

    // @todo: this method shall probably be moved somewhere else
    public func endingDate(question_id: Nat, scheduler_parameters: SchedulerParameters) : ?Time {
      let (_, status_info) = getCurrentStatus(question_id);
      let status_duration = switch(status_info.status){
        case(#CANDIDATE) { scheduler_parameters.candidate_status_duration; };
        case(#OPEN)      { scheduler_parameters.open_status_duration;      };
        case(#CLOSED)    { return null; };
        case(#REJECTED(_)){ 
          if (Option.isSome(findLastStatusInfo(question_id, #OPEN))){
            return null;
          } else {
            scheduler_parameters.rejected_status_duration;
          };
        };
      };
      ?(status_info.date + Duration.toTime(status_duration));
    };

  };

  // Return the index and status
  func findLastStatusInfoFromHistory(status_history: StatusHistory, status: Status) : ?(Nat, StatusInfo) {
    var match : ?(Nat, StatusInfo) = null;
    var index = 0;
    for (status_info in Buffer.vals(status_history)){
      if (status_info.status == status){
        match := ?(index, status_info);
      };
      index := index + 1;
    };
    match;
  };

};