import Types "types";
import Utils "utils";
import Queries "questions/queries";
import WrappedRef "ref/wrappedRef";

import Set "mo:map/Set";
import Map "mo:map/Map";
import RBT "mo:stableRBT/StableRBTree";

import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Array "mo:base/Array";

module {

  type Time = Int;
  //type Set<K> = TrieSet.Set<K>;
  //type Trie<K, V> = Trie.Trie<K, V>;
  //type Trie2D<K1, K2, V> = Trie.Trie2D<K1, K2, V>;
  //type Trie3D<K1, K2, K3, V> = Trie.Trie3D<K1, K2, K3, V>;
  type Principal = Principal.Principal;

  type Set<K> = Set.Set<K>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type Map3D<K1, K2, K3, V> = Map<K1, Map<K2, Map<K3, V>>>;
  type RBT<K, V> = RBT.Tree<K, V>;

  // For convenience: from types module
  type Parameters = Types.Parameters;
  type Question = Types.Question;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type User = Types.User;
  type Category = Types.Category;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Status = Types.Status;
  type Duration = Types.Duration;
  type Polarization = Types.Polarization;
  type WrappedRef<T> = WrappedRef.WrappedRef<T>;
  type Timestamp<T> = Types.Timestamp<T>;
  type InterestAggregate = Types.InterestAggregate;
  type OrderBy = Queries.OrderBy;
  type QuestionKey = Queries.QuestionKey;

  public type State = {
    admin             : Principal;
    creation_date     : Time;
    categories        : Set<Category>;
    users             : {
      register           : Map<Principal, User>;
      convictions_half_life: ?Duration;
    };
    questions         : {
      register           : Map<Nat, Question>;
      index              : WrappedRef<Nat>;
    };
    queries           : {
      register           : Map<OrderBy, RBT<QuestionKey, ()>>;
    };
    scheduler         : {
      last_selection_date: WrappedRef<Time>;
      selection_rate:      WrappedRef<Duration>;
      status_durations:    Map<Status, Duration>;
    };
    votes             : {
      interest           : {
        ballots            : Map3D<Principal, Nat, Nat, Timestamp<Interest>>;
        aggregates         : Map2D<Nat, Nat, Timestamp<InterestAggregate>>;
      };
      opinion            : {
        ballots            : Map3D<Principal, Nat, Nat, Timestamp<Cursor>>;
        aggregates         : Map2D<Nat, Nat, Timestamp<Polarization>>;
      };
      categorization     : {
        ballots            : Map3D<Principal, Nat, Nat, Timestamp<CategoryCursorTrie>>;
        aggregates         : Map2D<Nat, Nat, Timestamp<CategoryPolarizationTrie>>;
      };
    };
  };

  public func initState(admin: Principal, creation_date: Time, parameters: Parameters) : State {
    {
      admin             = admin;
      creation_date     = creation_date;
      categories        = Set.fromIter(Array.vals(parameters.categories), Set.thash);
      users             = {
        register        = Map.new<Principal, User>();
        convictions_half_life = parameters.users.convictions_half_life;
      };
      questions         = {
        register           = Map.new<Nat, Question>();
        index              = WrappedRef.init(0 : Nat);
      };
      queries           = {
        register           = Map.new<OrderBy, RBT<QuestionKey, ()>>();
      };
      scheduler         = {
        last_selection_date = WrappedRef.init(creation_date);
        selection_rate      = WrappedRef.init(parameters.scheduler.selection_rate);
        status_durations    = Map.fromIter(Array.vals(parameters.scheduler.status_durations), Types.statushash);
      };
      votes = {
        interest        = {
          ballots              = Map.new<Principal, Map<Nat, Map<Nat, Timestamp<Interest>>>>();
          aggregates           = Map.new<Nat, Map<Nat, Timestamp<InterestAggregate>>>();
        };
        opinion         = {
          ballots              = Map.new<Principal, Map<Nat, Map<Nat, Timestamp<Cursor>>>>();
          aggregates           = Map.new<Nat, Map<Nat, Timestamp<Polarization>>>();
        };
        categorization  = {
          ballots              = Map.new<Principal, Map<Nat, Map<Nat, Timestamp<CategoryCursorTrie>>>>();
          aggregates           = Map.new<Nat, Map<Nat, Timestamp<CategoryPolarizationTrie>>>();
        };
      };
    };
  };

};