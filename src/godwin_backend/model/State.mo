import Types "Types";
import QuestionQueries "QuestionQueries";
import OrderedSet "../utils/OrderedSet";
import Ref "../utils/Ref";
import Categorization "votes/Categorizations";
import Interests "votes/Interests";
import Opinion "votes/Opinions";
import Categories "Categories";
import Duration "../utils/Duration";
import History "History";

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
  type Ref<V> = Ref.Ref<V>;

  // For convenience: from types module
  type Parameters = Types.Parameters;
  type Question = Types.Question;
  type Cursor = Types.Cursor;
  type Category = Types.Category;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type Duration = Duration.Duration;
  type Polarization = Types.Polarization;
  type SchedulerParameters = Types.SchedulerParameters;
  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type Appeal = Types.Appeal;
  type Status = Types.Status;
  type StatusHistory = Types.StatusHistory;
  type UserHistory = Types.UserHistory;

  public type State = {
    admin             : Principal;
    creation_date     : Time;
    categories        : Categories.Register;
    questions         : {
      register           : Map<Nat, Question>;
      index              : Ref<Nat>;
    };
    queries           : {
      register           : QuestionQueries.Register;
    };
    controller        : {
      model              : {
        time             : Ref<Time>; 
        most_interesting : Ref<?Nat>;
        last_pick_date   : Ref<Time>;
        params           : Ref<SchedulerParameters>;
      };
    };
    votes             : {
      interest           : Interests.Register;
      opinion            : Opinion.Register;
      categorization     : Categorization.Register;
    };
    history           : {
      status_history         : Map<Nat, StatusHistory>;
      user_history           : Map<Principal, UserHistory>;
      convictions_half_life  : ?Duration;
    };
  };

  public func initState(admin: Principal, creation_date: Time, parameters: Parameters) : State {
    {
      admin          = admin;
      creation_date  = creation_date;
      categories     = Categories.initRegister(parameters.categories);
      questions      = {
        register              = Map.new<Nat, Question>();
        index                 = Ref.initRef<Nat>(0);
      };
      queries        = {
        register              = QuestionQueries.initRegister();
      };
      controller     = {
        model                 = {
          time                    = Ref.initRef<Time>(creation_date);
          most_interesting        = Ref.initRef<?Nat>(null);
          last_pick_date          = Ref.initRef<Time>(creation_date);
          params                  = Ref.initRef<SchedulerParameters>(parameters.scheduler);
        };
      };
      votes          = {
        interest              = Interests.initRegister();
        opinion               = Opinion.initRegister();
        categorization        = Categorization.initRegister();
      };
      history        = {
        status_history            = Map.new<Nat, StatusHistory>();
        user_history              = Map.new<Principal, UserHistory>();
        convictions_half_life     = parameters.history.convictions_half_life;
      };
    };
  };

};