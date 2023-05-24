import MasterTypes "../../../godwin_master/Types";
import TokenTypes "../../../godwin_token/Types";

import Map "mo:map/Map";

import Result "mo:base/Result";
import Error "mo:base/Error";
import Buffer "mo:base/Buffer";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Buffer<T>       = Buffer.Buffer<T>;
  type Map<K, V>       = Map.Map<K, V>;

  public type MasterInterface = MasterTypes.MasterInterface;
  public let { toSubaccount; toBaseResult; } = MasterTypes;

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

  public type CanisterCallError = {
    #CanisterCallError: Error.ErrorCode;
  };

  // PayIn types
  public type PayinError       = MasterTypes.TransferError or CanisterCallError;
  public type PayinResult      = Result<TxIndex, PayinError>;
  // Payout types
  public type PayoutRecipient  = { to: Principal; share: Float; };
  //public type SinglePayoutInfo = (TokenTypes.TransferArgs, TokenTypes.TransferResult);
  public type PayoutError = TokenTypes.TransferError or TokenTypes.ReapAccountError or CanisterCallError or {
    #SingleReapLost: {
      share: Float;
      subgodwin_subaccount: Subaccount;
    };
    #SingleTransferError: {
      args: TransferArgs;
      error: TransferError;
    };
  };
  public type PayoutResult = Result<TxIndex, PayoutError>;
  // Mint types
  public type MintRecipient    = { to: Principal; amount: Balance;};
  public type MintArgs         = TokenTypes.MintBatchArgs;
  public type SingleMintInfo   = (TokenTypes.Mint, TokenTypes.TransferResult);
  public type MintError        = MasterTypes.TransferError or CanisterCallError or { #BatchError : [SingleMintInfo]; };
  public type MintResult       = Result<(), MintError>;

  public type TransactionsRecord = {
    payin: TxIndex;
    payout: {
      #PENDING;
      #PROCESSED: {
        refund: ?PayoutResult;
        reward: ?PayoutResult;
      };
    };
  };

  public type IPayInterface = {
    payin: (subaccount: Blob, from: Principal, amount: Balance) -> async* PayinResult;
    payout: (subaccount: Blob, to: Principal, amount: Nat) -> async* PayoutResult;
    batchPayout: (subaccount: Blob, recipients: Buffer<PayoutRecipient>, results: Map<Principal, PayoutResult>) -> async* ();
    mint: (recipients: Buffer<MintRecipient>) -> async* MintResult;
  };

};