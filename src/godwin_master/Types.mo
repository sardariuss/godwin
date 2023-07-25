import Result     "mo:base/Result";
import Nat64      "mo:base/Nat64";
import Nat        "mo:base/Nat";

import TokenTypes "../godwin_token/Types";
import UtilsTypes "../godwin_sub/utils/Types";

module {

  type Result<Ok, Err>       = Result.Result<Ok, Err>;

  type Duration              = UtilsTypes.Duration;

  public type ValidationParams = {
    username: {
      min_length: Nat;
      max_length: Nat;
    };
    subgodwin: {
      scheduler_params: {
        minimum_duration: Duration;
        maximum_duration: Duration;
      };
      convictions_params: {
        minimum_duration: Duration;
        maximum_duration: Duration;
      };
      question_char_limit: {
        maximum: Nat;
      };
      minimum_interest_score: {
        minimum: Float;
      };
    };
  };

  public type AddGodwinSubError = {
    #NotAuthorized;
    #AlreadyAdded;
  };

  public type CreateSubGodwinError = {
    #InvalidIdentifier;
    #IdentifierAlreadyTaken;
    #CategoryDuplicate;
    #DurationTooShort: ({minimum_duration: Duration;});
    #DurationTooLong: ({maximum_duration: Duration;});
    #CharacterLimitTooLong: ({maximum: Nat;});
    #MinimumInterestScoreTooLow: ({minimum: Float;});
  };

  public type TransferError = TokenTypes.TransferError or {
    #NotAllowed;
  }; // @todo: add the CanisterCallError

  public type SetUserNameError = {
    #AnonymousNotAllowed;
    #NameTooShort: { min_length: Nat; };
    #NameTooLong: { max_length: Nat; };
    #NameAlreadyTaken;
  };

  public type MintBatchArgs = TokenTypes.MintBatchArgs;

  public type CreateSubGodwinResult = Result<Principal, CreateSubGodwinError>;

  public type TransferResult = Result<TokenTypes.TxIndex, TransferError>;

  public type MintBatchResult = Result<[(TokenTypes.Mint, TokenTypes.TransferResult)], TransferError>;

  public type Balance = TokenTypes.Balance;

  public type MasterInterface = actor {
    pullTokens: shared(Principal, TokenTypes.Balance, ?Blob) -> async TransferResult;
    mintBatch: shared(MintBatchArgs) -> async MintBatchResult;
    mint: shared(TokenTypes.Mint) -> async TransferResult;
  };

  // @todo
  public func transferErrorToText(error: TransferError) : Text {
    switch error {
      case (#TooOld) { "TooOld" };
      case (#CreatedInFuture({ledger_time})) { "CreatedInFuture (ledger_time=" # Nat64.toText(ledger_time) # ")"; };
      case (#BadFee({expected_fee})) { "BadFee (expected_fee=" # Nat.toText(expected_fee) # ")"; };
      case (#BadBurn({min_burn_amount})) { "BadBurn (min_burn_amount=" # Nat.toText(min_burn_amount) # ")"; };
      case (#InsufficientFunds({balance})) { "InsufficientFunds (balance=" # Nat.toText(balance) # ")"; };
      case (#Duplicate({duplicate_of})) { "Duplicate (duplicate_of=" # Nat.toText(duplicate_of) # ")"; };
      case (#TemporarilyUnavailable) { "TemporarilyUnavailable" };
      case (#GenericError({error_code; message;})) { "GenericError (error_code=" # Nat.toText(error_code) # ", message=" # message # ")"; };
      case (#NotAllowed) { "NotAllowed" };
    };
  };

  public type TokenResult<Ok, Err> = {
    #Ok: Ok;
    #Err: Err;
  };

  // @todo: this should be part of another module
  public func toBaseResult<Ok, Err>(icrc1_result: TokenResult<Ok, Err>) : Result<Ok, Err> {
    switch(icrc1_result){
      case(#Ok(ok)) {
        #ok(ok);
      };
      case(#Err(err)) {
        #err(err);
      };
    };
  };

};