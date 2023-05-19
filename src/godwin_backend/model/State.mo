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
import PayTypes        "token/Types";

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
  type VoteId              = VoteTypes.VoteId;
  type Cursor              = VoteTypes.Cursor;
  type Category            = VoteTypes.Category;
  type CursorMap           = VoteTypes.CursorMap;
  type PolarizationMap     = VoteTypes.PolarizationMap;
  type Polarization        = VoteTypes.Polarization;
  type Transactions        = PayTypes.Transactions;
  type IterationHistory    = QuestionTypes.IterationHistory;

  public type State = {
    name              : Ref<Text>; // @todo: this shouldn't be a ref
    master            : Ref<Principal>; // @todo: this shouldn't be a ref
    creation_date     : Time;
    categories        : Categories.Register;
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
      transactions       : Map<Principal, Map<VoteId, Transactions>>;
    };
    votes          : {
      interest                : {
        register                  : Interests.Register;
        transactions              : Map<Principal, Map<VoteId, Transactions>>;
       };
      opinion                 : {
        register                  : Opinions.Register;
      };
      categorization          : {
        register                  : Categorizations.Register;
        transactions              : Map<Principal, Map<VoteId, Transactions>>;
       };
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
        transactions                = Map.new<Principal, Map<VoteId, Transactions>>(Map.phash);
      };
      votes         = {
        interest                    = {
          register                      = Interests.initRegister();
          transactions                  = Map.new<Principal, Map<VoteId, Transactions>>(Map.phash);
        };
        opinion                     = {
          register                      = Opinions.initRegister();
        };
        categorization              = {
          register                      = Categorizations.initRegister();
          transactions                  = Map.new<Principal, Map<VoteId, Transactions>>(Map.phash);
        };
      };
      joins         = {
        interests                   = Joins.initRegister();
        opinions                    = Joins.initRegister();
        categorizations             = Joins.initRegister();
      };
    };
  };

};