import Types           "Types";
import Utils           "../utils/Utils";
import WMap            "../utils/wrappers/WMap";

import Map             "mo:map/Map";

import Result          "mo:base/Result";
import Debug           "mo:base/Debug";
import Option          "mo:base/Option";
import Array           "mo:base/Array";

module {

  // For convenience: from base module
  type Result<Ok, Err>       = Result.Result<Ok, Err>;

  // For convenience: from map module
  type Map<K, V>          = Map.Map<K, V>;
  type WMap<K, V>         = WMap.WMap<K, V>;

  // For convenience: from types module
  //type Question                = Types.Question;
  type VoteHistory             = Types.VoteHistory;
  type FindCurrentVoteError    = Types.FindCurrentVoteError;
  type FindHistoricalVoteError = Types.FindHistoricalVoteError;
  type QuestionId              = Types.QuestionId;
  type VoteId                  = Types.VoteId;

  public type Register = Map<QuestionId, VoteHistory>;

  public func build(register: Register) : QuestionVoteHistory {
    QuestionVoteHistory(WMap.WMap(register, Map.nhash));
  };
  
  public class QuestionVoteHistory(_register: WMap<QuestionId, VoteHistory>) {

    public func addVote(question_id: QuestionId, vote_id: VoteId) {
      switch(_register.getOpt(question_id)){
        case(null) { 
          // Create a new entry with an empty history
          _register.set(question_id, { current = ?vote_id; history = []; }); 
        };
        case(?{current; history;}) {
          if (Option.isSome(current)) {
            Debug.trap("There is already a current vote");
          };
          // Add the (previous) current status to the history
          for (id in Array.vals(history)){
            if (vote_id == id) { Debug.trap("Already added"); };
          };
          // Update the current status
          _register.set(question_id, { current = ?vote_id; history; }); 
        };
      };
    };

    public func closeCurrentVote(question_id: QuestionId) : VoteId {
      switch(_register.getOpt(question_id)){
        case(null) { 
          Debug.trap("Could not find a current vote for that question");
        };
        case(?{current; history;}) {
          switch(current){
            case(null) { 
              Debug.trap("There is no current vote to close");
            };
            case(?vote){
              _register.set(question_id, { current = null; history = Utils.append(history, [vote]); }); 
              vote;
            };
          };
        };
      };
    };

    public func findCurrentVote(question_id: QuestionId) : Result<VoteId, FindCurrentVoteError> {
      let {current} = switch(_register.getOpt(question_id)){
        case(null) { return #err(#VoteLinkNotFound); };
        case(?vote_link) { vote_link; };
      };
      switch(current){
        case(null) { #err(#VoteClosed); };
        case(?vote) { #ok(vote); };
      };
    };

    public func findHistoricalVote(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindHistoricalVoteError> {
      let {history} = switch(_register.getOpt(question_id)){
        case(null) { return #err(#VoteLinkNotFound); };
        case(?vote_link) { vote_link };
      };
      if (iteration >= history.size()) {
        return #err(#IterationOutOfBounds);
      };
      return #ok(history[iteration]);
    };

    public func findPreviousVote(question_id: QuestionId) : ?VoteId {
      let {current; history;} = switch(_register.getOpt(question_id)){
        case(null) { return null; };
        case(?vote_link) { vote_link };
      };
      if (history.size() == 0) {
        return null;
      };
      return ?history[history.size() - 1];
    };

    public func getCurrentVote(question_id: QuestionId) : ?VoteId {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("Could not find a current vote for that question"); };
        case(?vote_link) { return vote_link.current; };
      };
    };

    public func getHistoricalVotes(question_id: QuestionId) : [VoteId] {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("Could not find a current vote for that question"); };
        case(?vote_link) { vote_link.history; };
      };
    };

  };

};