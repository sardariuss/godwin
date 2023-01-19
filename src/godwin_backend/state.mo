import Types "types";
import Queries "questions/queries";
import OrderedSet "OrderedSet";

import Set "mo:map/Set";
import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Array "mo:base/Array";

module {

  type Time = Int;
  type Principal = Principal.Principal;

  type Set<K> = Set.Set<K>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type Map3D<K1, K2, K3, V> = Map<K1, Map<K2, Map<K3, V>>>;
  type OrderedSet<K> = OrderedSet.OrderedSet<K>;

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
  type Ref<T> = Types.Ref<T>;
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
      index              : Ref<Nat>;
    };
    queries           : {
      register           : Map<OrderBy, OrderedSet<QuestionKey>>;
    };
    scheduler         : {
      last_selection_date: Ref<Time>;
      selection_rate:      Ref<Duration>;
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
        index              = Types.initRef(0 : Nat);
      };
      queries           = {
        register           = Queries.initRegister();
      };
      scheduler         = {
        last_selection_date = Types.initRef(creation_date);
        selection_rate      = Types.initRef(parameters.scheduler.selection_rate);
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