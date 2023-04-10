import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";

import Token "canister:godwin_token";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;

  public type CreateSubGodwinError = {
    #InvalidIdentifier;
    #IdentifierAlreadyTaken;
  };

  public type AirdropError = Token.TransferError or {
    #AlreadySupplied;
    #AirdropOver;
  };

  public type TransferError = Token.TransferError or {
    #NotAllowed;
  };

  public type MintBatchArgs = Token.MintBatchArgs;

  public type CreateSubGodwinResult = Result<Principal, CreateSubGodwinError>;

  public type TransferResult = Result<Token.TxIndex, TransferError>;

  public type AirdropResult = Result<Token.TxIndex, AirdropError>;

  public type MintBatchResult = Result<[ Token.TransferResult ], TransferError>;

  public type Balance = Token.Balance;

  public type MasterInterface = actor {
    pullTokens: shared(Principal, Token.Balance, ?Blob) -> async TransferResult;
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

  // @todo: this should be part of a specific module
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

};