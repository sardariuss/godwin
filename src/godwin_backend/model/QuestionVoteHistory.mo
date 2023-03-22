import Types           "Types";
import Status          "Status";
import Categories      "Categories";
import Decay           "Decay";
import Votes           "votes/Votes";
import Opinions        "votes/Opinions";
import Categorizations "votes/Categorizations";
import Interests       "votes/Interests";
import Polarization    "votes/representation/Polarization";
import Cursor          "votes/representation/Cursor";
import PolarizationMap "votes/representation/PolarizationMap";

import Utils           "../utils/Utils";
import WMap            "../utils/wrappers/WMap";
import WSet            "../utils/wrappers/WSet";
import Duration        "../utils/Duration";

import Map             "mo:map/Map";
import Set             "mo:map/Set";

import Debug           "mo:base/Debug";
import Iter            "mo:base/Iter";
import Option          "mo:base/Option";
import Float           "mo:base/Float";
import Principal       "mo:base/Principal";
import Trie            "mo:base/Trie";
import Array           "mo:base/Array";

module {

  // For convenience: from base module
  type Time               = Int;
  type Iter<T>            = Iter.Iter<T>;

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
  type InterestVote       = Interests.Vote;
  type OpinionVote        = Opinions.Vote;
  type CategorizationVote = Categorizations.Vote;
  type OpinionBallot      = Opinions.Ballot;

  // For convenience: from types module
  type Question           = Types.Question;
  type Status             = Types.Status;
  type VoteId             = Types.VoteId;
  type Category           = Types.Category;
  type Cursor             = Types.Cursor;
  type Polarization       = Types.Polarization;
  type PolarizationMap    = Types.PolarizationMap;
  type Decay              = Types.Decay; 
  type UserHistory        = Types.UserHistory;

  type StatusHistory2 = Types.StatusHistory2;
  type StatusData3 = Types.StatusData3;
  type VoteType    = Types.VoteType;

  public type VoteLink = {
    current: Nat;
    history: [Nat];
  };

  public type Register = Map<Nat, VoteLink>;

  public func build(register: Register) : QuestionVoteHistory {
    QuestionVoteHistory(WMap.WMap(register, Map.nhash));
  };
  
  public class QuestionVoteHistory(register_: WMap<Nat, VoteLink>) {

    public func addVote(question_id: Nat, vote_id: Nat) {
      switch(register_.getOpt(question_id)){
        case(null) { 
          // Create a new entry with an empty history
          register_.set(question_id, { current = vote_id; history = []; }); 
        };
        case(?{current; history;}) {
          // Add the (previous) current status to the history
          for (id in Array.vals(history)){
            if (vote_id == id) { Debug.trap("Already added"); };
          };
          // Update the current status
          register_.set(question_id, { current = vote_id; history = Utils.append(history, [current]); }); 
        };
      };
    };

    public func getCurrentVote(question_id: Nat) : ?Nat {
      Option.map(register_.getOpt(question_id), func(vote_link: VoteLink) : Nat { vote_link.current; });
    };

    public func getHistoricalVote(question_id: Nat, iteration: Nat) : ?Nat {
      let {current; history;} = switch(register_.getOpt(question_id)){
        case(null) { return null; };
        case(?v) { v };
      };
      if (iteration >= history.size()) {
        return null;
      };
      return ?history[iteration];
    };
  };

};