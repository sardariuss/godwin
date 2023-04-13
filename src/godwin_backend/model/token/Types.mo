import MasterTypes "../../../godwin_master/Types";

import Token "canister:godwin_token";

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
  public type Subaccount = Blob;
  public type Balance = Token.Balance;
  public type Account = Token.Account;
  public type TxIndex = Token.TxIndex;

  public type CanisterCallError = {
    #CanisterCallError: Error.ErrorCode;
  };

  // PayIn types
  public type PayInError = MasterTypes.TransferError or CanisterCallError;
  public type PayInResult = Result<TxIndex, PayInError>;
  // Payout types
  public type PayoutRecipient = { to: Principal; share: Float; };
  public type PayoutArgs = Token.ReapAccountArgs;
  public type SinglePayoutInfo = (Token.TransferArgs, Token.TransferResult);
  public type PayoutError = Token.ReapAccountError or CanisterCallError or { #BatchError: [SinglePayoutInfo]; };
  public type PayOutResult = Result<(), PayoutError>;
  // Mint types
  public type MintRecipient = { to: Principal; amount: Balance;};
  public type MintArgs = Token.MintBatchArgs;
  public type SingleMintInfo = (Token.Mint, Token.TransferResult);
  public type MintError = MasterTypes.TransferError or CanisterCallError or { #BatchError : [SingleMintInfo]; };
  public type MintResult = Result<(), MintError>;

};