import SubTypes "../godwin_backend/model/Types";

import ICRC1 "mo:icrc1/ICRC1";

import Result "mo:base/Result";
import Nat64 "mo:base/Nat64";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;

  public type CreateSubGodwinError = {
    #InvalidIdentifier;
    #IdentifierAlreadyTaken;
  };

  public type CreateSubGodwinResult = Result<Principal, CreateSubGodwinError>;

  public type TransferResult = Result<ICRC1.TxIndex, TransferError>;

  public type TransferError = ICRC1.TransferError or {
    #NotAllowed;
  };

  public type AirdropResult = Result<ICRC1.TxIndex, AirdropError>;

  public type AirdropError = ICRC1.TransferError or {
    #AlreadySupplied;
    #AirdropOver;
  };

  public type MintBatchResult = Result<[ ICRC1.TransferResult ], TransferError>;

  public type MintBatchArgs = {
    to : [{ account : ICRC1.Account; amount : ICRC1.Balance; }];
    memo : ?Blob;
  };

  public type MasterInterface = actor {
    createSubGodwin: shared(SubTypes.Parameters) -> async Principal;
    updateSubGodwins: shared(SubTypes.Parameters) -> async ();
    listSubGodwins: query() -> async [Principal];
    airdrop: shared() -> async AirdropResult;
    mintBatch: shared(MintBatchArgs) -> async MintBatchResult;
    transferToSubGodwin: shared(Principal, ICRC1.Balance, Blob) -> async TransferResult;
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