import MasterTypes "../../../godwin_master/Types";
import TokenTypes "../../../godwin_token/Types";

import Result "mo:base/Result";
import Error "mo:base/Error";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;

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

};