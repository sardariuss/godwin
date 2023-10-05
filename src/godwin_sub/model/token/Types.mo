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
  public type ReapAccountRecipient = TokenTypes.ReapAccountRecipient;
  public type MintRecipient        = TokenTypes.MintRecipient;
  public type GodwinTokenInterface = TokenTypes.FullInterface;

  public type CanisterCallError = {
    #CanisterCallError: Error.ErrorCode;
  };

  // Transfer from master types
  public type TransferFromMasterError  = MasterTypes.TransferError or CanisterCallError;
  public type TransferFromMasterResult = Result<TxIndex, TransferFromMasterError>;

  // Transfer to master types
  public type TransferToMasterResult = Result<TxIndex, TransferError or CanisterCallError>;
  
  // Reap account types
  public type ReapAccountReceiver  = { to: Principal; share: Float; };
  public type ReapAccountResult = Result<TxIndex, ReapAccountError>;
  public type ReapAccountError = TransferError or CanisterCallError or {
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

  // Mint types
  public type MintReceiver    = { to: Principal; amount: Balance; };
  public type MintResult       = Result<TxIndex, MintError>;
  public type MintError        = MasterTypes.TransferError or CanisterCallError or { 
    #SingleMintLost: {
      amount: Balance;
    };
    #SingleMintError: {
      args: Mint;
      error: TransferError;
    };
  };

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
        refund: ?ReapAccountResult;
        reward: ?MintResult;
      };
    };
  };

  public type ITokenInterface = {
    transferFromMaster: (from: Principal, to_subaccount: Blob, amount: Balance) -> async TransferFromMasterResult;
    reapSubaccount: (subaccount: Blob, recipients: Iter<ReapAccountReceiver>) -> async Trie<Principal, ?ReapAccountResult>;
    mintBatch: (recipients: Iter<MintReceiver>) -> async Trie<Principal, ?MintResult>;
    mint:(to: Principal, amount: Balance) -> async MintResult;
  };

};