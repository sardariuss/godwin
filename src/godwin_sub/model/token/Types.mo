import MasterTypes "../../../godwin_master/Types";
import TokenTypes  "../../../godwin_token/Types";

import Map         "mo:map/Map";

import Result      "mo:base/Result";
import Error       "mo:base/Error";
import Buffer      "mo:base/Buffer";
import Trie        "mo:base/Trie";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Buffer<T>       = Buffer.Buffer<T>;
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
  public type Subaccount     = Blob;
  public type Balance        = TokenTypes.Balance;
  public type Account        = TokenTypes.Account;
  public type TxIndex        = TokenTypes.TxIndex;
  public type TransferResult = TokenTypes.TransferResult;
  public type TransferArgs   = TokenTypes.TransferArgs;
  public type TransferError  = TokenTypes.TransferError;
  public type Mint           = TokenTypes.Mint;

  public type CanisterCallError = {
    #CanisterCallError: Error.ErrorCode;
  };

  // Transfer from master types
  public type TransferFromMasterError  = MasterTypes.TransferError or CanisterCallError;
  public type TransferFromMasterResult = Result<TxIndex, TransferFromMasterError>;

  // Transfer to master types
  public type TransferToMasterResult = Result<TxIndex, TransferError or CanisterCallError>;
  
  // Reap account types
  public type ReapAccountRecipient  = { to: Principal; share: Float; };
  public type ReapAccountResult = Result<TxIndex, ReapAccountError>;
  public type ReapAccountError = TransferError or TokenTypes.ReapAccountError or CanisterCallError or {
    #SingleReapLost: {
      share: Float;
      subgodwin_subaccount: Subaccount;
    };
    #SingleTransferError: {
      args: TransferArgs;
      error: TransferError;
    };
  };

  // Mint types
  public type MintRecipient    = { to: Principal; amount: Balance; };
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

  public type PayoutArgs = {
    refund_share: Float;
    reward_tokens: ?Balance;
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

  public type QuestionPayouts = {
    author_payout: PayoutArgs;
    creator_reward: ?Balance;
  };

  public type ITokenInterface = {
    transferFromMaster: (from: Principal, to_subaccount: Blob, amount: Balance) -> async* TransferFromMasterResult;
    reapSubaccount: (subaccount: Blob, recipients: Buffer<ReapAccountRecipient>) -> async* Trie<Principal, ?ReapAccountResult>;
    mintBatch: (recipients: Buffer<MintRecipient>) -> async* Trie<Principal, ?MintResult>;
    mint:(to: Principal, amount: Balance) -> async* MintResult;
  };

};