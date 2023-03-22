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
import Duration        "../utils/Duration";

import Map             "mo:map/Map";
import Set             "mo:map/Set";

import Debug           "mo:base/Debug";
import Iter            "mo:base/Iter";
import Option          "mo:base/Option";
import Float           "mo:base/Float";
import Principal       "mo:base/Principal";
import Trie            "mo:base/Trie";

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
  type StatusInfo2 = Types.StatusInfo2;
  type StatusData2 = Types.StatusData2;
  type VoteType    = Types.VoteType;

  public func unwrapStatus(status_info: StatusInfo2) : Status {
    switch(status_info){
      case(#CANDIDATE(_)) { #CANDIDATE; };
      case(#OPEN(_))      { #OPEN;      };
      case(#CLOSED(_))    { #CLOSED;    };
      case(#REJECTED(_))  { #REJECTED;  };
      case(#TRASH)        { #TRASH;     };
    };
  };

  public type Register = Map<Nat, StatusData2>;

  public func build(register: Register) : StatusManager {
    StatusManager(WMap.WMap(register, Map.nhash));
  };
  
  public class StatusManager(register_: WMap.WMap<Nat, StatusData2>) {

    public func setCurrent(question_id: Nat, status_info: StatusInfo2) {
      switch(register_.getOpt(question_id)){
        case(null) { 
          // Create a new entry with an empty history
          register_.set(question_id, { var current = status_info; history = Map.new<Status, [StatusInfo2]>(); }); 
        };
        case(?status_data) {
          // Add the (previous) current status to the history
          var iterations = Option.get(Map.get(status_data.history, Status.status_hash, unwrapStatus(status_data.current)), []);
          iterations := Utils.append<StatusInfo2>(iterations, [status_data.current]);
          Map.set(status_data.history, Status.status_hash, unwrapStatus(status_data.current), iterations);
          // Update the current status
          status_data.current := status_info;
        };
      };
    };

    public func getCurrent(question_id: Nat) : ?StatusInfo2 {
      Option.map(register_.getOpt(question_id), func(status_data: StatusData2) : StatusInfo2 { 
        status_data.current; 
      });
    };

    public func getHistory(question_id: Nat) : ?StatusHistory2 {
      Option.map(register_.getOpt(question_id), func(status_data: StatusData2) : StatusHistory2 { 
        status_data.history; 
      });
    };

    public func getCurrentVoteId(question_id: Nat, vote_type: VoteType) : ?Nat {
      Option.chain(getCurrent(question_id), func(status_info: StatusInfo2) : ?Nat { 
        getVoteId(status_info, vote_type); 
      });
    };

    public func iterateCurrentVote(question_id: Nat, vote_type: VoteType, fn: Nat -> ()) {
      let status_info = switch(getCurrent(question_id)){
        case(null) { return; };
        case(?s) { s; };
      };
      Option.iterate(getVoteId(status_info, vote_type), func(vote_id: Nat) { 
        fn(vote_id); 
      });
    };

    public func getHistoricalVoteId(question_id: Nat, vote_type: VoteType, iteration: Nat) : ?Nat {
      // Get the history for this question
      let history = switch(getHistory(question_id)){
        case(null) { return null; };
        case(?h) { h; };
      };
      // Get the historical array of status corresponding to this vote type
      let array_status = switch(Map.get(history, Status.status_hash, getStatus(vote_type))){
        case(null) { return null; };
        case(?a) { a; };
      };
      // Check if the historical array has the iteration
      if (array_status.size() < iteration) { 
        return null; 
      };
      // Return the vote id
      getVoteId(array_status[iteration], vote_type);
    };

    public func getStatusIteration(question_id: Nat, status: Status) : Nat {
      // Get the status data
      let status_data = switch(register_.getOpt(question_id)){
        case(null) { return 0; };
        case(?d) { d; };
      };
      // Get the status info
      let status_infos = switch(Map.get(status_data.history, Status.status_hash, status)){
        case(null) { return 0; };
        case(?i) { i; };
      };
      // Return the size
      status_infos.size();
    };

    func getVoteId(status_info: StatusInfo2, vote_type: VoteType) : ?Nat {
      switch(status_info){
        case(#CANDIDATE({interests_id}))   { if (vote_type == #INTEREST      ) { return ?interests_id;       } };
        case(#OPEN({opinions_id; 
                    categorizations_id;})) { if (vote_type == #OPINION       ) { return ?opinions_id;        } 
                                        else if (vote_type == #CATEGORIZATION) { return ?categorizations_id; } };
        case(_) { };
      };
      null;
    };

    func getStatus(vote_type: VoteType) : Status {
      switch(vote_type){
        case(#INTEREST)       { #CANDIDATE; };
        case(#OPINION)        { #OPEN;      };
        case(#CATEGORIZATION) { #OPEN;      };
      };
    };

  };

};