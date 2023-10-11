import V0_2_0                 "Types";
import V0_1_0                 "../00-01-00-initial/Types";
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

import Utils                  "../../utils/Utils";
import Ref                    "../../utils/Ref";

import Map                    "mo:map/Map";

import Debug                  "mo:base/Debug";
import Option                 "mo:base/Option";
import Principal              "mo:base/Principal";
import Float                  "mo:base/Float";
import Nat                    "mo:base/Nat";
import Error                  "mo:base/Error";

module {

  type Time                       = Int;
  type Map<K, V>                  = Map.Map<K, V>;

  type State                      = MigrationTypes.State;

  type SubParameters              = V0_2_0.SubParameters;
  type SchedulerParameters        = V0_2_0.SchedulerParameters;
  type SelectionParameters        = V0_2_0.SelectionParameters;
  type PriceParameters            = V0_2_0.PriceParameters;
  type DecayParameters            = V0_2_0.DecayParameters;
  type Momentum                   = V0_2_0.Momentum;
  type VoteId                     = V0_2_0.VoteId;
  type QuestionId                 = V0_2_0.QuestionId;
  type StatusHistory              = V0_2_0.StatusHistory;
  type TransactionsRecord         = V0_2_0.TransactionsRecord;
  type RewardGwcResult            = V0_2_0.RewardGwcResult;
  type InitArgs                   = V0_2_0.InitArgs;
  type UpgradeArgs                = V0_2_0.UpgradeArgs;
  type DowngradeArgs              = V0_2_0.DowngradeArgs;

  public func init(date: Time, args: InitArgs) : State {
    let { master; token; creator; sub_parameters; price_parameters; } = args;
    let { name; categories; scheduler; character_limit; convictions; selection; } = sub_parameters;

    if (selection.minimum_score <= 0.0) {
      Debug.trap("Cannot intialize momentum args with a minimum score inferior or equal to 0");
    };

    #v0_2_0({
      creator;
      creation_date               = date;
      name                        = Ref.init<Text>(name);
      master                      = Ref.init<Principal>(master);
      token                       = Ref.init<Principal>(token);
      categories                  = Categories.initRegister(categories);
      scheduler_params            = Ref.init<SchedulerParameters>(scheduler);
      price_params                = Ref.init<PriceParameters>(price_parameters);
      selection_params            = Ref.init<SelectionParameters>(selection);
      momentum                    = Ref.init<Momentum>({
        num_votes_opened = 0;
        selection_score = selection.minimum_score;
        last_pick = null;
      });
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
        creator_rewards              = Map.new<VoteId, RewardGwcResult>(Map.nhash);
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

  // From 0.1.0 to 0.2.0
  public func upgrade(migration_state: State, date: Time, args: UpgradeArgs): State {
    // Access current state
    let state = switch(migration_state){
      case(#v0_1_0(state)) state;
      case(_)              Debug.trap("Unexpected migration state (v0_1_0 expected)");
    };

    let opened_questions     = { state.opened_questions     with transactions = upgradeTransactionsRecords(state.opened_questions.transactions);     
                                                                 creator_rewards = updateRewardGwcResult(state.opened_questions.creator_rewards);    };
    let interest_votes       = { state.votes.interest       with transactions = upgradeTransactionsRecords(state.votes.interest.transactions);       };
    let categorization_votes = { state.votes.categorization with transactions = upgradeTransactionsRecords(state.votes.categorization.transactions); };
    let votes                = { state.votes                with interest = interest_votes; categorization = categorization_votes;                   };
    let price_params         = Ref.init<PriceParameters>(args.price_parameters);

    #v0_2_0({state with 
      opened_questions; 
      votes; 
      price_params; 
    });
  };

  // From 0.2.0 to 0.1.0
  public func downgrade(migration_state: State, date: Time, args: DowngradeArgs): State {
    Debug.trap("Downgrade not supported");
  };

  func updateRewardGwcResult(v1: Map<VoteId, V0_1_0.MintResult>) : Map<VoteId, V0_2_0.RewardGwcResult> {
    Map.mapFilter(v1, Map.nhash, func(id: VoteId, result: V0_1_0.MintResult) : ?V0_2_0.RewardGwcResult {
      ?toRewardGwcResult(result);
    });
  };

  func upgradeTransactionsRecords(v1: Map<Principal, Map<Nat, V0_1_0.TransactionsRecord>>) : Map<Principal, Map<Nat, V0_2_0.TransactionsRecord>> {
    Utils.mapFilter2D<Principal, Nat, V0_1_0.TransactionsRecord, V0_2_0.TransactionsRecord>(
      v1, Map.phash, Map.nhash, func(p: Principal, id: Nat, tx_record: V0_1_0.TransactionsRecord) : ?V0_2_0.TransactionsRecord {
        ?upgradeTransactionsRecord(tx_record);
      });
  };

  func upgradeTransactionsRecord(v1: V0_1_0.TransactionsRecord) : V0_2_0.TransactionsRecord {
    let { payin; payout } = v1;
    return { 
      payin; payout = switch(payout){
        case(#PENDING)   { #PENDING; };
        case(#PROCESSED({refund; reward;})) { 
          #PROCESSED({ refund = Option.map(refund, toRedistributeBtcResult); reward = Option.map(reward, toRewardGwcResult); });
        };
      };
    };
  };

  func toRedistributeBtcResult(v1: V0_1_0.ReapAccountResult) : V0_2_0.RedistributeBtcResult {
    switch(v1){
      case(#ok(tx_index)) { #ok(tx_index); };
      case(#err(v1_err)) { 
        switch(v1_err){
          case(#NoRecipients) 
            #err(#GenericError({
              error_code = 1000;
              message = "v0_1_0 error: no recipients";
            }));
          case(#NegativeShare({account = {owner; subaccount}; share})) 
            #err(#GenericError({ 
              error_code = 1000; 
              message = "v0_1_0 error: negative share [" # 
                "account = {
                  owner      = " # Principal.toText(owner) # "; 
                  subaccount = " # Option.getMapped<Blob, Text>(subaccount, Utils.blobToText, "(null)") # 
                "} 
                share    = " # Float.toText(share) # "]";
            }));
          case(#BalanceExceeded({sum_shares; total_amount; balance_without_fees; }))
            #err(#GenericError({
              error_code = 1000;
              message = "v0_1_0 error: balance exceeded [" # 
                "sum_shares           = " # Float.toText(sum_shares) # "; " # 
                "total_amount         = " # Nat.toText(total_amount) # "; " # 
                "balance_without_fees = " # Nat.toText(balance_without_fees) # "]";
            }));
          case(#SingleReapLost({share; subgodwin_subaccount; }))
            #err(#GenericError({
              error_code = 1000;
              message = "v0_1_0 error: single reap lost [" # 
                "share                = " # Float.toText(share) # "; " # 
                "subgodwin_subaccount = " # Utils.blobToText(subgodwin_subaccount) # "]";
            }));
          case(#SingleTransferError({error;}))
            #err(error);
          case(#BadBurn(details))
            #err(#BadBurn(details));
          case(#BadFee(details))
            #err(#BadFee(details));
          case(#CanisterCallError(details))
            #err(#GenericError({
              error_code = 1000;
              message = "v0_1_0 error: canister call error"
            }));
          case(#CreatedInFuture(details))
            #err(#CreatedInFuture(details));
          case(#Duplicate(details))
            #err(#Duplicate(details));
          case(#GenericError(details))
            #err(#GenericError(details));
          case(#InsufficientFunds(details))
            #err(#InsufficientFunds(details));
          case(#TemporarilyUnavailable)
            #err(#TemporarilyUnavailable);
          case(#TooOld)
            #err(#TooOld);
        };
      };
    };
  };

  func toRewardGwcResult(v1: V0_1_0.MintResult) : V0_2_0.RewardGwcResult {
    switch(v1){
      case(#ok(tx_index)) { #ok(tx_index); };
      case(#err(v1_err)) { 
        switch(v1_err){
          case(#SingleMintLost({amount;}))
             #err(#GenericError({
              error_code = 1000;
              message = "v0_1_0 error: single mint lost [" # 
                "amount = " # Nat.toText(amount) # "]";
            }));
          case(#SingleMintError({error}))
            #err(error);
          case(#BadBurn(details))
            #err(#BadBurn(details));
          case(#BadFee(details))
            #err(#BadFee(details));
          case(#CanisterCallError(error))
            #err(#GenericError({
              error_code = 1000;
              message = "v0_1_0 error: canister call error"
            }));
          case(#CreatedInFuture(details))
            #err(#CreatedInFuture(details));
          case(#Duplicate(details))
            #err(#Duplicate(details));
          case(#GenericError(details))
            #err(#GenericError(details));
          case(#InsufficientFunds(details))
            #err(#InsufficientFunds(details));
          case(#TemporarilyUnavailable)
            #err(#TemporarilyUnavailable);
          case(#TooOld)
            #err(#TooOld);
          case(#AccessDenied(details))
            #err(#AccessDenied(details));
        };
      };
    };
  };

};