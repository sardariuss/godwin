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

  public type TxIndex        = TokenTypes.TxIndex;
  public type TransferResult = Result<TxIndex, TransferError>;
  public type Balance        = TokenTypes.Balance;
  public type Account        = TokenTypes.Account;

  public type Duration = UtilsTypes.Duration;

  public type SubMigrationArgs = SubMigrationTypes.Args;

  public type MigrationArgs = StableTypes.Args;

  public type CyclesParameters = StableTypes.Current.CyclesParameters;

  public type PriceParameters = StableTypes.Current.PriceParameters;

  public type ValidationParams = StableTypes.Current.ValidationParams;

  public type LedgerType = {
    #BTC;
    #GWC;
  };

  public type AccessControlRole = {
    #ADMIN;
    #SUB;
  };

  public type AccessControlError = {
    #AccessDenied: ({ required_role: AccessControlRole });
  };

  public type UpgradeAllSubsResult = Result<ListSubUpgradesResults, AccessControlError>;

  public type ListSubUpgradesResults = [(Principal, SingleSubUpgradeResult)];

  public type SingleSubUpgradeResult = Result<(), CanisterCallError>;

  public type RemoveSubResult = Result<Principal, RemoveSubError>;
  
  public type CanisterCallError = {
    #CanisterCallError: {
      canister: Principal;
      method: Text;
      code: Error.ErrorCode;
      message: Text;
    };
  };

  public type RemoveSubError = AccessControlError or {
    #SubNotFound;
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

  public type TransferError = TokenTypes.TransferError or AccessControlError or CanisterCallError;

  public type SetUserNameError = {
    #AnonymousNotAllowed;
    #NameTooShort: { min_length: Nat; };
    #NameTooLong: { max_length: Nat; };
    #NameAlreadyTaken;
  };

  public type RewardGwcReceiver = {
    to: Principal;
    amount: Balance;
  };

  public type CreateSubGodwinResult = Result<Principal, CreateSubGodwinError or TransferError>;

  public type PullBtcError = TransferError;
  public type PullBtcResult = Result<TxIndex, TransferError>;
  public type RewardGwcResult = Result<[(RewardGwcReceiver, TransferResult)], AccessControlError>;

  public type MasterInterface = actor {
    pullBtc: shared(Principal, Balance, ?Blob) -> async PullBtcResult;
    rewardGwc: shared([RewardGwcReceiver]) -> async RewardGwcResult;
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