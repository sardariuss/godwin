import Types                  "Types";
import MigrationTypes         "../Types";
import Categories             "../../model/Categories";
import Decay                  "../../model/votes/Decay";
import Questions              "../../model/questions/Questions";	
import QuestionQueriesFactory "../../model/questions/QueriesFactory";
import Interests              "../../model/votes/Interests";
import Categorizations        "../../model/votes/Categorizations";
import Opinions               "../../model/votes/Opinions";
import Joins                  "../../model/votes/QuestionVoteJoins";

import Ref                    "../../utils/Ref";

import Map                    "mo:map/Map";

import Debug                  "mo:base/Debug";

module {

  type Time                       = Int;
  type Map<K, V>                  = Map.Map<K, V>;

  type State                      = MigrationTypes.State;

  type Parameters                 = Types.Parameters;
  type SchedulerParameters        = Types.SchedulerParameters;
  type PriceParameters            = Types.PriceParameters;
  type DecayParameters            = Types.DecayParameters;
  type VoteId                     = Types.VoteId;
  type InterestMomentumArgs       = Types.InterestMomentumArgs;
  type StatusHistory              = Types.StatusHistory;
  type TransactionsRecord         = Types.TransactionsRecord;
  type InitArgs                   = Types.InitArgs;
  type UpgradeArgs                = Types.UpgradeArgs;
  type DowngradeArgs              = Types.DowngradeArgs;

  public func init(date: Time, args: InitArgs) : State {
    let {master; parameters;} = args;
    #v0_1_0({
      name                        = Ref.init<Text>(parameters.name);
      master                      = Ref.init<Principal>(master);
      creation_date               = date;
      categories                  = Categories.initRegister(parameters.categories);
      momentum_args               = Ref.init<InterestMomentumArgs>({ 
        last_pick_date_ns = date;
        last_pick_score = 1.0; 
        num_votes_opened = 0;
        minimum_score = if (parameters.minimum_interest_score > 0.0) { parameters.minimum_interest_score; } else {
          Debug.trap("Cannot intialize momentum args with a minimum score inferior or equal to 0");
        };
      });
      scheduler_params            = Ref.init<SchedulerParameters>(parameters.scheduler);
      price_params                = Ref.init<PriceParameters>(parameters.prices);
      convictions_params                = {
        opinion_vote                 = Ref.init<DecayParameters>(Decay.initParameters(parameters.convictions.vote_half_life, date));
        late_opinion_ballot          = Ref.init<DecayParameters>(Decay.initParameters(parameters.convictions.late_ballot_half_life, date));
      };
      status                      = {
        register                     = Map.new<Nat, StatusHistory>(Map.nhash);
      };
      questions                      = Questions.initRegister(parameters.questions.character_limit);
      queries                     = {
        register                     = QuestionQueriesFactory.initRegister();
      };
      opened_questions            = {
        register                     = Map.new<Nat, (Principal, Blob)>(Map.nhash);
        index                        = Ref.init<Nat>(0);
        transactions                 = Map.new<Principal, Map<VoteId, TransactionsRecord>>(Map.phash);
      };
      votes                       = {
        interest                     = {
          register                      = Interests.initRegister();
          transactions                  = Map.new<Principal, Map<VoteId, TransactionsRecord>>(Map.phash);
        };
        opinion                      = {
          register                      = Opinions.initRegister();
        };
        categorization               = {
          register                      = Categorizations.initRegister();
          transactions                  = Map.new<Principal, Map<VoteId, TransactionsRecord>>(Map.phash);
        };
      };
      joins                       = {
        interests                    = Joins.initRegister();
        opinions                     = Joins.initRegister();
        categorizations              = Joins.initRegister();
      };
    });
  };

  // From nothing to 0.1.0
  public func upgrade(migration_state: State, date: Time, args: UpgradeArgs): State {
    Debug.trap("Cannot upgrade to initial version");
  };

  // From 0.1.0 to nothing
  public func downgrade(migration_state: State, date: Time, args: DowngradeArgs): State {
    Debug.trap("Cannot downgrade from initial version");
  };

};