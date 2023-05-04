import Types           "Types";
import QuestionQueries "questions/QuestionQueries";
import Categories      "Categories";
import Interests       "votes/Interests";
import Categorizations "votes/Categorizations";
import Opinions        "votes/Opinions";

import Duration        "../utils/Duration";
import Ref             "../utils/Ref";

import Set             "mo:map/Set";
import Map             "mo:map/Map";

import Principal       "mo:base/Principal";

module {

  type Time                = Int;
  type Principal           = Principal.Principal;

  type Set<K>              = Set.Set<K>;
  type Map<K, V>           = Map.Map<K, V>;
  type Ref<V>              = Ref.Ref<V>;

  // For convenience: from types module
  type Parameters          = Types.Parameters;
  type Question            = Types.Question;
  type Cursor              = Types.Cursor;
  type Category            = Types.Category;
  type CursorMap           = Types.CursorMap;
  type PolarizationMap     = Types.PolarizationMap;
  type Duration            = Duration.Duration;
  type Polarization        = Types.Polarization;
  type SchedulerParameters = Types.SchedulerParameters;
  type User                = Types.User;
  type StatusData          = Types.StatusData;
  type VoteHistory         = Types.VoteHistory;
  //type FailedPayout        = Types.FailedPayout; // @todo

  public type State = {
    name              : Ref<Text>; // @todo: this shouldn't be a ref
    master            : Ref<Principal>; // @todo: this shouldn't be a ref
    creation_date     : Time;
    categories        : Categories.Register;
    pay_interface     : {
      //failed_payouts     : Set<FailedPayout>; // @todo: shall be adapted to the new payout system
    };
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
        last_pick_date   : Ref<Time>;
        params           : Ref<SchedulerParameters>;
      };
    };
    opened_questions  : {
      register           : Map<Nat, (Principal, Blob)>;
      index              : Ref<Nat>;
    };
    votes          : {
      interest                : Interests.Register;
      interest_history        : Map<Nat, VoteHistory>;
      opinion                 : Opinions.Register;
      opinion_history         : Map<Nat, VoteHistory>;
      categorization          : Categorizations.Register;
      categorization_history  : Map<Nat, VoteHistory>;
    };
    users          : {
      register                : Map<Principal, User>;
      convictions_half_life   : ?Duration;
    };
  };

  public func initState(master: Principal, creation_date: Time, parameters: Parameters) : State {
    {
      name                          = Ref.init<Text>(parameters.name);
      master                        = Ref.init<Principal>(master);
      creation_date                 = creation_date;
      categories                    = Categories.initRegister(parameters.categories);
      pay_interface = {
        //failed_payouts              = Set.new<FailedPayout>();
      };
      status        = {
        register                    = Map.new<Nat, StatusData>(Map.nhash);
      };
      questions     = {
        register                    = Map.new<Nat, Question>(Map.nhash);
        index                       = Ref.init<Nat>(0);
        character_limit             = Ref.init<Nat>(parameters.questions.character_limit);
      };
      queries       = {
        register                    = QuestionQueries.initRegister();
      };
      controller    = {
        model = {
          last_pick_date            = Ref.init<Time>(creation_date);
          params                    = Ref.init<SchedulerParameters>(parameters.scheduler);
        };
      };
      opened_questions = {
        register                    = Map.new<Nat, (Principal, Blob)>(Map.nhash);
        index                       = Ref.init<Nat>(0);
      };
      votes         = {
        interest                    = Interests.initRegister();
        interest_history            = Map.new<Nat, VoteHistory>(Map.nhash);
        opinion                     = Opinions.initRegister();
        opinion_history             = Map.new<Nat, VoteHistory>(Map.nhash);
        categorization              = Categorizations.initRegister();
        categorization_history      = Map.new<Nat, VoteHistory>(Map.nhash);
      };
      users         = {
        register                    = Map.new<Principal, User>(Map.phash);
        convictions_half_life       = parameters.history.convictions_half_life;
      };
    };
  };

};