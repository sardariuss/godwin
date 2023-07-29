import TokenTypes        "../godwin_token/Types";
import UtilsTypes        "../godwin_sub/utils/Types";
import SubMigrationTypes "../godwin_sub/stable/Types";
import StableTypes       "stable/Types";

import Result      "mo:base/Result";
import Nat64       "mo:base/Nat64";
import Nat         "mo:base/Nat";
import Error       "mo:base/Error";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;

  public type Duration = UtilsTypes.Duration;

  public type SubMigrationArgs = SubMigrationTypes.Args;

  public type MigrationArgs = StableTypes.Args;

  public type CyclesParameters = StableTypes.Current.CyclesParameters;

  public type BasePriceParameters = StableTypes.Current.BasePriceParameters;

  public type ValidationParams = StableTypes.Current.ValidationParams;

  public type AccessControlRole = {
    #ADMIN;
    #SUB;
  };

  public type AccessControlError = {
    #AccessDenied: ({ required_role: AccessControlRole });
  };

  public type UpgradeAllSubsResult = Result<ListSubUpgradesResults, AccessControlError>;

  public type ListSubUpgradesResults = [(Principal, SingleSubUpgradeResult)];

  public type SingleSubUpgradeResult = Result<(), FailedUpgradeError>;
  
  public type FailedUpgradeError = {
    code: Error.ErrorCode;
    message: Text;
  };

  public type AddGodwinSubError = {
    #NotAuthorized;
    #AlreadyAdded;
  };

  public type CreateSubGodwinError = {
    #IdentifierTooShort:        ({min_length       : Nat;     });
    #IdentifierTooLong:         ({max_length       : Nat;     });
    #NameTooShort:              ({min_length       : Nat;     });
    #NameTooLong:               ({max_length       : Nat;     });
    #InvalidIdentifier;         
    #IdentifierAlreadyTaken;    
    #NoCategories;              
    #CategoryDuplicate;         
    #DurationTooShort:           ({minimum_duration: Duration;});
    #DurationTooLong:            ({maximum_duration: Duration;});
    #CharacterLimitTooLong:      ({maximum         : Nat;     });
    #MinimumInterestScoreTooLow: ({minimum         : Float;   });
  };

  public type TransferError = TokenTypes.TransferError or AccessControlError; // @todo: add the CanisterCallError

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
      case (#AccessDenied(_)) { "AccessDenied" };
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