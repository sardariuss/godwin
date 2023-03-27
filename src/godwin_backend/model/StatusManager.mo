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
import Nat             "mo:base/Nat";

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
  type Category           = Types.Category;
  type Cursor             = Types.Cursor;
  type Polarization       = Types.Polarization;
  type PolarizationMap    = Types.PolarizationMap;
  type Decay              = Types.Decay; 
  type User        = Types.User;
  type StatusInfo = Types.StatusInfo;

  type StatusData = Types.StatusData;

  public type Register = Map<Nat, StatusData>;

  public func build(register: Register) : StatusManager {
    StatusManager(WMap.WMap(register, Map.nhash));
  };
  
  public class StatusManager(_register: WMap.WMap<Nat, StatusData>) {

    public func setCurrent(question_id: Nat, status: Status, date: Time) {
      switch(_register.getOpt(question_id)){
        case(null) { 
          // Create a new entry with an empty history
          _register.set(question_id, { var current = { status; date; iteration = 0; }; history = Map.new<Status, [Time]>(); }); 
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

    public func getCurrent(question_id: Nat) : StatusInfo {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("Not status data found for the question with id='" # Nat.toText(question_id) # "'") };
        case(?status_data) { status_data.current; };
      };
    };

    public func getHistory(question_id: Nat) : Map<Status, [Time]> {
      switch(_register.getOpt(question_id)){
        case(null) { Debug.trap("Not status data found for the question with id='" # Nat.toText(question_id) # "'") };
        case(?status_data) { status_data.history; };
      };
    };

    public func getStatusIteration(question_id: Nat, status: Status) : Nat {
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

    public func deleteStatus(question_id: Nat) {
      _register.delete(question_id);
    };

  };

};