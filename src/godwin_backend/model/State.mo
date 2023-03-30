import Types "Types";
import QuestionQueries "QuestionQueries";
import OrderedSet "../utils/OrderedSet";
import Ref "../utils/Ref";
import Categorization "votes/Categorizations";
import Interests "votes/Interests";
import Opinion "votes/Opinions";
import Categorizations "votes/Categorizations";
import Opinions "votes/Opinions";
import Categories "Categories";
import Duration "../utils/Duration";

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
  type QuestionsParameters = Types.QuestionsParameters;
  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type Appeal = Types.Appeal;
  type Status = Types.Status;
  type StatusHistory = Types.StatusHistory;
  type User = Types.User;
  type Interest = Types.Interest;
  type StatusData = Types.StatusData;
  type VoteHistory = Types.VoteHistory;

  public type State = {
    admin             : Ref<Principal>;
    creation_date     : Time;
    categories        : Categories.Register;
    questions         : {
      register           : Map<Nat, Question>;
      index              : Ref<Nat>;
      character_limit    : Ref<Nat>;
    };
    status            : {
      register           : Map<Nat, StatusData>;
    };
    queries           : {
      register           : QuestionQueries.Register;
    };
    controller        : {
      model              : {
        time             : Ref<Time>; 
        last_pick_date   : Ref<Time>;
        params           : Ref<SchedulerParameters>;
      };
    };
    subaccounts       : {
      interest_votes        : Map<Nat, Blob>;
      categorization_votes  : Map<Nat, Blob>;
      index                 : Ref<Nat>;
    };
    votes          : {
      interest                : Interests.VoteRegister;
      interest_history        : Map<Nat, VoteHistory>;
      opinion                 : Opinions.VoteRegister;
      opinion_history        : Map<Nat, VoteHistory>;
      categorization          : Categorizations.VoteRegister;
      categorization_history        : Map<Nat, VoteHistory>;
    };
    users          : {
      register                : Map<Principal, User>;
      convictions_half_life   : ?Duration;
    };
  };

  public func initState(admin: Principal, creation_date: Time, parameters: Parameters) : State {
    {
      admin          = Ref.initRef<Principal>(admin);
      creation_date  = creation_date;
      categories     = Categories.initRegister(parameters.categories);
      status         = {
        register              = Map.new<Nat, StatusData>();
      };
      questions      = {
        register              = Map.new<Nat, Question>();
        index                 = Ref.initRef<Nat>(0);
        character_limit       = Ref.initRef<Nat>(parameters.questions.character_limit);
      };
      queries        = {
        register              = QuestionQueries.initRegister();
      };
      controller     = {
        model                 = {
          time                    = Ref.initRef<Time>(creation_date);
          last_pick_date          = Ref.initRef<Time>(creation_date);
          params                  = Ref.initRef<SchedulerParameters>(parameters.scheduler);
        };
      };
      subaccounts = {
        interest_votes        = Map.new<Nat, Blob>();
        categorization_votes  = Map.new<Nat, Blob>();
        index                 = Ref.initRef<Nat>(0);
      };
      votes          = {
        interest              = Interests.initVoteRegister();
        interest_history      = Map.new<Nat, VoteHistory>();
        opinion               = Opinions.initVoteRegister();
        opinion_history      = Map.new<Nat, VoteHistory>();
        categorization        = Categorizations.initVoteRegister();
        categorization_history      = Map.new<Nat, VoteHistory>();
      };
      users        = {
        register                  = Map.new<Principal, User>();
        convictions_half_life     = parameters.history.convictions_half_life;
      };
    };
  };

};