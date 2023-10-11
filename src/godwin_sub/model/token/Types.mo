import MasterTypes "../../../godwin_master/Types";
import TokenTypes  "../../../godwin_token/Types";

import Map         "mo:map/Map";

import Result      "mo:base/Result";
import Error       "mo:base/Error";
import Iter        "mo:base/Iter";
import Trie        "mo:base/Trie";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Iter<T>         = Iter.Iter<T>;
  type Map<K, V>       = Map.Map<K, V>;
  type Trie<K, V>      = Trie.Trie<K, V>;

  public type MasterInterface = MasterTypes.MasterInterface;
  public let { toBaseResult; } = MasterTypes;

  public type SubaccountPrefix = {
    #OPEN_QUESTION;
    #PUT_INTEREST_BALLOT;
    #PUT_CATEGORIZATION_BALLOT;
  };

  // Token general types
  public type Subaccount           = Blob;
  public type Balance              = TokenTypes.Balance;
  public type Account              = TokenTypes.Account;
  public type TxIndex              = TokenTypes.TxIndex;
  public type TransferResult       = TokenTypes.TransferResult;
  public type TransferArgs         = TokenTypes.TransferArgs;
  public type TransferError        = TokenTypes.TransferError;
  public type Mint                 = TokenTypes.Mint;
  public type ICRC1TokenInterface  = TokenTypes.FullInterface;

 public type CanisterCallError = {
    #CanisterCallError: {
      canister: Principal;
      method: Text;
      code: Error.ErrorCode;
      message: Text;
    };
  };

  // Pull BTC types
  public type PullBtcError = MasterTypes.PullBtcError or CanisterCallError;
  public type PullBtcResult = Result<TxIndex, PullBtcError>;
  
  // Redistribute BTC types
  public type RedistributeBtcReceiver  = { to: Principal; share: Float; };
  public type RedistributeBtcResult = Result<TxIndex, RedistributeBtcError>;
  public type RedistributeBtcError = TransferError or CanisterCallError or {
    #InsufficientFees: {
      share: Float;
      subaccount: Subaccount;
      balance: Balance;
      sum_fees: Balance;
    };
    #InvalidSumShares: {
      owed: Balance;
      subaccount: Subaccount;
      balance_without_fees: Balance;
      total_owed: Balance;
    };
  };

  // Reward GWC types @btc
  public type RewardGwcReceiver  = MasterTypes.RewardGwcReceiver;
  public type RewardGwcResult    = Result<TxIndex, RewardGwcError>;
  public type RewardGwcError     = MasterTypes.TransferError or CanisterCallError;

  public type PayoutRecipient = { 
    to: Principal;
    args: PayoutArgs;
  };

  public type RawPayout = {
    refund_share: Float;
    reward: ?Float;
  };

  public type PayoutArgs = {
    refund_share: Float;
    reward_tokens: ?Balance;
  };

  public type QuestionPayouts = {
    author_payout: RawPayout;
    creator_reward: ?Float;
  };

  public type TransactionsRecord = {
    payin: TxIndex;
    payout: {
      #PENDING;
      #PROCESSED: {
        refund: ?RedistributeBtcResult;
        reward: ?RewardGwcResult;
      };
    };
  };

  public type ITokenInterface = {
    pullBtc: (from: Principal, to_subaccount: Blob, amount: Balance) -> async PullBtcResult;
    redistributeBtc: (subaccount: Blob, receivers: Iter<RedistributeBtcReceiver>) -> async Trie<Principal, ?RedistributeBtcResult>;
    rewardGwcToAll: (receivers: Iter<RewardGwcReceiver>) -> async Trie<Principal, ?RewardGwcResult>;
    rewardGwc: (RewardGwcReceiver) -> async RewardGwcResult;
  };

};