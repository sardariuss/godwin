import Types           "Types";
import VoteTypes       "votes/Types";
import QuestionTypes   "questions/Types";
import Questions       "questions/Questions";	
import QuestionQueries "questions/QuestionQueries";
import Categories      "Categories";
import Interests       "votes/Interests";
import Categorizations "votes/Categorizations";
import Opinions        "votes/Opinions";
import Joins           "votes/QuestionVoteJoins";

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
  type Duration            = Types.Duration;
  type Parameters          = Types.Parameters;
  type SchedulerParameters = Types.SchedulerParameters;
  type Cursor              = VoteTypes.Cursor;
  type Category            = VoteTypes.Category;
  type CursorMap           = VoteTypes.CursorMap;
  type PolarizationMap     = VoteTypes.PolarizationMap;
  type Polarization        = VoteTypes.Polarization;
  type IterationHistory    = QuestionTypes.IterationHistory;

  //type FailedPayout        = Types.FailedPayout; // @todo

  public type State = {
    name              : Ref<Text>; // @todo: this shouldn't be a ref
    master            : Ref<Principal>; // @todo: this shouldn't be a ref
    creation_date     : Time;
    categories        : Categories.Register;
    pay_interface     : {
      //failed_payouts     : Set<FailedPayout>; // @todo: shall be adapted to the new payout system
    };
    questions         : Questions.Register;
    status            : {
      register           : Map<Nat, IterationHistory>;
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
      opinion                 : Opinions.Register;
      categorization          : Categorizations.Register;
    };
    joins          : {
      interests               : Joins.Register;
      opinions                : Joins.Register;
      categorizations         : Joins.Register;
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
        register                    = Map.new<Nat, IterationHistory>(Map.nhash);
      };
      questions                     = Questions.initRegister(parameters.questions.character_limit);
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
        opinion                     = Opinions.initRegister();
        categorization              = Categorizations.initRegister();
      };
      joins         = {
        interests                   = Joins.initRegister();
        opinions                    = Joins.initRegister();
        categorizations             = Joins.initRegister();
      };
    };
  };

};