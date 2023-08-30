import Types                  "Types";
import MigrationTypes         "../Types";
// @todo: do not use model modules
import Categories             "../../model/Categories";
import Decay                  "../../model/votes/Decay";
import Questions              "../../model/questions/Questions";	
import QuestionQueriesFactory "../../model/questions/QueriesFactory";
import Interests              "../../model/votes/Interests";
import Categorizations        "../../model/votes/Categorizations";
import Opinions               "../../model/votes/Opinions";
import Joins                  "../../model/votes/QuestionVoteJoins";
import SubPrices               "../../model/SubPrices";

import Ref                    "../../utils/Ref";

import Map                    "mo:map/Map";

import Debug                  "mo:base/Debug";

module {

  type Time                       = Int;
  type Map<K, V>                  = Map.Map<K, V>;

  type State                      = MigrationTypes.State;

  type SubParameters              = Types.SubParameters;
  type SchedulerParameters        = Types.SchedulerParameters;
  type SelectionParameters        = Types.SelectionParameters;
  type BasePriceParameters        = Types.BasePriceParameters;
  type DecayParameters            = Types.DecayParameters;
  type Momentum                   = Types.Momentum;
  type VoteId                     = Types.VoteId;
  type QuestionId                 = Types.QuestionId;
  type PriceRegister              = Types.PriceRegister;
  type StatusHistory              = Types.StatusHistory;
  type TransactionsRecord         = Types.TransactionsRecord;
  type MintResult                 = Types.MintResult;
  type InitArgs                   = Types.InitArgs;
  type UpgradeArgs                = Types.UpgradeArgs;
  type DowngradeArgs              = Types.DowngradeArgs;

  public func init(date: Time, args: InitArgs) : State {
    let { master; token; creator; sub_parameters; price_parameters; } = args;
    let { name; categories; scheduler; character_limit; convictions; selection; } = sub_parameters;

    if (selection.minimum_score <= 0.0) {
      Debug.trap("Cannot intialize momentum args with a minimum score inferior or equal to 0");
    };

    #v0_1_0({
      creator;
      creation_date               = date;
      name                        = Ref.init<Text>(name);
      master                      = Ref.init<Principal>(master);
      token                       = Ref.init<Principal>(token);
      categories                  = Categories.initRegister(categories);
      scheduler_params            = Ref.init<SchedulerParameters>(scheduler);
      base_price_params           = Ref.init<BasePriceParameters>(price_parameters);
      selection_params            = Ref.init<SelectionParameters>(selection);
      momentum                    = Ref.init<Momentum>({
        num_votes_opened = 0;
        selection_score = selection.minimum_score;
        last_pick = null;
      });
      price_register              = Ref.init<PriceRegister>(SubPrices.computeSubPrices(price_parameters, selection));
      status                      = {
        register                     = Map.new<Nat, StatusHistory>(Map.nhash);
      };
      questions                      = Questions.initRegister(character_limit);
      queries                     = {
        register                     = QuestionQueriesFactory.initRegister();
      };
      opened_questions            = {
        register                     = Map.new<Nat, (Principal, Blob)>(Map.nhash);
        index                        = Ref.init<Nat>(0);
        transactions                 = Map.new<Principal, Map<VoteId, TransactionsRecord>>(Map.phash);
        creator_rewards              = Map.new<VoteId, MintResult>(Map.nhash);
      };
      votes                       = {
        interest                     = {
          register                      = Interests.initRegister();
          open_by                       = Map.new<Principal, Map<VoteId, Time>>(Map.phash);
          voters_history                = Map.new<Principal, Map<QuestionId, Map<Nat, VoteId>>>(Map.phash);
          joins                         = Joins.initRegister();
          transactions                  = Map.new<Principal, Map<VoteId, TransactionsRecord>>(Map.phash);
        };
        opinion                      = {
          register                      = Opinions.initRegister();
          voters_history                = Map.new<Principal, Map<QuestionId, Map<Nat, VoteId>>>(Map.phash);
          joins                         = Joins.initRegister();
          vote_decay_params             = Ref.init<DecayParameters>(Decay.getDecayParameters(convictions.vote_half_life, date));
          late_ballot_decay_params      = Ref.init<DecayParameters>(Decay.getDecayParameters(convictions.late_ballot_half_life, date));
        };
        categorization               = {
          register                      = Categorizations.initRegister();
          voters_history                = Map.new<Principal, Map<QuestionId, Map<Nat, VoteId>>>(Map.phash);
          joins                         = Joins.initRegister();
          transactions                  = Map.new<Principal, Map<VoteId, TransactionsRecord>>(Map.phash);
        };
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