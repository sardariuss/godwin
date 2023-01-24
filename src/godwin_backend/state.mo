import Types "types";
import QuestionQueries2 "QuestionQueries2";
import OrderedSet "OrderedSet";
import Categorization "votes/categorization";
import Interest "votes/interest";
import Opinion "votes/opinion";
import Scheduler "scheduler";

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
  type Duration = Types.Duration;
  type Polarization = Types.Polarization;
  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type Ref<T> = Types.Ref<T>;
  type InterestAggregate = Types.InterestAggregate;
  type QuestionStatus = Types.QuestionStatus;

  type QuestionOrderBy = QuestionQueries2.OrderBy;
  type QuestionKey = QuestionQueries2.Key;

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
      register           : Map<QuestionOrderBy, OrderedSet<QuestionKey>>;
    };
    scheduler         : {
      register:            Scheduler.Register;
    };
    votes             : {
      interest           : Interest.Register;
      opinion            : Opinion.Register;
      categorization     : Categorization.Register;
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
        register           = Map.new<QuestionOrderBy, OrderedSet<QuestionKey>>();
      };
      scheduler         = {
        register            = Scheduler.initRegister(parameters.scheduler, creation_date);
      };
      votes = {
        interest            = Interest.initRegister();
        opinion             = Opinion.initRegister();
        categorization      = Categorization.initRegister();
      };
    };
  };

};