import Types           "Types";
import Status          "Status";
import Categories      "Categories";
import Decay           "Decay";
import Votes           "votes/Votes";
import Polarization    "votes/representation/Polarization";
import Cursor          "votes/representation/Cursor";
import PolarizationMap "votes/representation/PolarizationMap";

import Utils           "../utils/Utils";
import WMap            "../utils/wrappers/WMap";
import WSet            "../utils/wrappers/WSet";
import Duration        "../utils/Duration";

import Map             "mo:map/Map";
import Set             "mo:map/Set";

import Result          "mo:base/Result";
import Debug           "mo:base/Debug";
import Iter            "mo:base/Iter";
import Option          "mo:base/Option";
import Float           "mo:base/Float";
import Principal       "mo:base/Principal";
import Trie            "mo:base/Trie";
import Array           "mo:base/Array";
import OpenVote "votes/interfaces/OpenVote";

module {

  // For convenience: from base module
  type Time               = Int;
  type Iter<T>            = Iter.Iter<T>;
  type Result<Ok, Err>       = Result.Result<Ok, Err>;

  // For convenience: from map module
  type Map<K, V>          = Map.Map<K, V>;
  type Map2D<K1, K2, V>   = Map<K1, Map<K2, V>>;
  type WMap<K, V>         = WMap.WMap<K, V>;
  type WMap2D<K1, K2, V>  = WMap.WMap2D<K1, K2, V>;
  type Set<K>             = Set.Set<K>;
  type WSet<K>            = WSet.WSet<K>;

  // For convenience: from other modules
  type Categories         = Categories.Categories;
  type Duration           = Duration.Duration;

  // For convenience: from types module
  type Question           = Types.Question;
  type Status             = Types.Status;
  type Category           = Types.Category;
  type Cursor             = Types.Cursor;
  type Polarization       = Types.Polarization;
  type PolarizationMap    = Types.PolarizationMap;
  type Decay              = Types.Decay; 
  type User               = Types.User;
  type VoteHistory        = Types.VoteHistory;
  type StatusData         = Types.StatusData;
  type FindCurrentVoteError = Types.FindCurrentVoteError;
  type FindHistoricalVoteError = Types.FindHistoricalVoteError;

  public type Register = Map<Nat, VoteHistory>;

  public func build(register: Register) : QuestionVoteHistory {
    QuestionVoteHistory(WMap.WMap(register, Map.nhash));
  };
  
  public class QuestionVoteHistory(_register: WMap<Nat, VoteHistory>) {

    public func addVote(question_id: Nat, vote_id: Nat) {
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

    public func closeCurrentVote(question_id: Nat) : Nat {
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

    public func findCurrentVote(question_id: Nat) : Result<Nat, FindCurrentVoteError> {
      let {current} = switch(_register.getOpt(question_id)){
        case(null) { return #err(#VoteLinkNotFound); };
        case(?vote_link) { vote_link; };
      };
      switch(current){
        case(null) { #err(#VoteClosed); };
        case(?vote) { #ok(vote); };
      };
    };

    public func findHistoricalVote(question_id: Nat, iteration: Nat) : Result<Nat, FindHistoricalVoteError> {
      let {history} = switch(_register.getOpt(question_id)){
        case(null) { return #err(#VoteLinkNotFound); };
        case(?vote_link) { vote_link };
      };
      if (iteration >= history.size()) {
        return #err(#IterationOutOfBounds);
      };
      return #ok(history[iteration]);
    };

    public func findPreviousVote(question_id: Nat) : ?Nat {
      let {current; history;} = switch(_register.getOpt(question_id)){
        case(null) { return null; };
        case(?vote_link) { vote_link };
      };
      if (history.size() == 0) {
        return null;
      };
      return ?history[history.size() - 1];
    };

    public func getCurrentVote(question_id: Nat) : ?Nat {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("Could not find a current vote for that question"); };
        case(?vote_link) { return vote_link.current; };
      };
    };

    public func getHistoricalVotes(question_id: Nat) : [Nat] {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("Could not find a current vote for that question"); };
        case(?vote_link) { vote_link.history; };
      };
    };

  };

};