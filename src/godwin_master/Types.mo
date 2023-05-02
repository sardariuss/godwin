import Result     "mo:base/Result";
import Nat64      "mo:base/Nat64";
import Nat        "mo:base/Nat";
import Buffer     "mo:base/Buffer";
import Blob       "mo:base/Blob";
import Principal  "mo:base/Principal";
import Debug      "mo:base/Debug";

import TokenTypes "../godwin_token/Types";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;

  public type CreateSubGodwinError = {
    #InvalidIdentifier;
    #IdentifierAlreadyTaken;
  };

  public type AirdropError = TokenTypes.TransferError or {
    #AlreadySupplied;
    #AirdropOver;
  };

  public type TransferError = TokenTypes.TransferError or {
    #NotAllowed;
  };

  public type MintBatchArgs = TokenTypes.MintBatchArgs;

  public type CreateSubGodwinResult = Result<Principal, CreateSubGodwinError>;

  public type TransferResult = Result<TokenTypes.TxIndex, TransferError>;

  public type AirdropResult = Result<TokenTypes.TxIndex, AirdropError>;

  public type MintBatchResult = Result<[(TokenTypes.Mint, TokenTypes.TransferResult)], TransferError>;

  public type Balance = TokenTypes.Balance;

  public type MasterInterface = actor {
    pullTokens: shared(Principal, TokenTypes.Balance, ?Blob) -> async TransferResult;
    airdrop: shared() -> async AirdropResult;
    mintBatch: shared(MintBatchArgs) -> async MintBatchResult;
  };

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

  // @todo: this should be part of another module
  // Subaccount shall be a blob of 32 bytes
  public func toSubaccount(principal: Principal) : Blob {
    let blob_principal = Blob.toArray(Principal.toBlob(principal));
    // According to IC interface spec: "As far as most uses of the IC are concerned they are
    // opaque binary blobs with a length between 0 and 29 bytes"
    if (blob_principal.size() > 32) {
      Debug.trap("Cannot convert principal to subaccount: principal length is greater than 32 bytes");
    };
    let buffer = Buffer.Buffer<Nat8>(32);
    buffer.append(Buffer.fromArray(blob_principal));
    // Add padding until 32 bytes
    while(buffer.size() < 32) {
      buffer.add(0);
    };
    // Return the buffer as a blob
    Blob.fromArray(Buffer.toArray(buffer));
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