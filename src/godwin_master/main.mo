import Godwin "../godwin_backend/main";
import Types "../godwin_backend/model/Types";

import Map "mo:map/Map";

import ICRC1 "mo:icrc1/ICRC1";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Debug "mo:base/Debug";
import ExperimentalCycles "mo:base/ExperimentalCycles";

shared actor class Master() = this_ {

  type Parameters = Types.Parameters;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Map<K, V> = Map.Map<K, V>;
  type Godwin = Godwin.Godwin;
  type Balance = ICRC1.Balance;
  type Token = ICRC1.TokenData;

  stable var token_ : ?Token = null;

  stable let sub_godwins_ = Map.new<Principal, Godwin>();

  public shared func createSubGodwin(parameters: Parameters) {

    let new_sub = await (system Godwin.Godwin)(#new {settings = ?{ 
      controllers = ?[Principal.fromActor(this_)];
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = null;
    }})(parameters);

    Map.set(sub_godwins_, Map.phash, Principal.fromActor(new_sub), new_sub);
  };

  type LockError = ICRC1.TransferError or {
    #NotAllowed;
  };

  public shared({caller = sub_godwin}) func lockTokens(user: Principal, amount: Balance) : async Result<(), LockError>{
    if (not Map.has(sub_godwins_, Map.phash, sub_godwin)) {
      return #err(#NotAllowed);
    };

    let transfer_args : ICRC1.TransferArgs = {
      from_subaccount = null;
      to = { owner = this(); subaccount = ?Principal.toBlob(user); };
      amount;
      fee : ?Balance = null;
      memo = ?Text.encodeUtf8("Lock tokens from subgodwin '" # Principal.toText(sub_godwin) # "'");
      /// The time at which the transaction was created.
      /// If this is set, the canister will check for duplicate transactions and reject them.
      created_at_time = ?Nat64.fromIntWrap(Time.now());
    };

    switch(await ICRC1.transfer(token(), transfer_args, user)){
      case (#Ok(_)) { #ok; };
      case (#Err(e)) { #err(e); };
    };
  };

  public shared({caller = sub_godwin}) func unlockTokens(user: Principal, amount: Balance) : async Result<(), LockError>{
    if (not Map.has(sub_godwins_, Map.phash, sub_godwin)) {
      return #err(#NotAllowed);
    };

    let transfer_args : ICRC1.TransferArgs = {
      from_subaccount = ?Principal.toBlob(user);
      to = { owner = user; subaccount = null; };
      amount;
      fee : ?Balance = null;
      memo = ?Text.encodeUtf8("Unlock tokens from subgodwin '" # Principal.toText(sub_godwin) # "'");
      /// The time at which the transaction was created.
      /// If this is set, the canister will check for duplicate transactions and reject them.
      created_at_time = ?Nat64.fromIntWrap(Time.now());
    };

    switch(await ICRC1.transfer(token(), transfer_args, this())){
      case (#Ok(_)) { #ok; };
      case (#Err(e)) { #err(e); };
    };
  };

  public func init() : async() {
    switch(token_){
      case (null) { 
        token_ := ?ICRC1.init({
          name = "Godwin";
          symbol = "GDW";
          decimals = 6; // @todo
          fee = 1_000_000;
          max_supply = 1_000_000_000_000_000;
          initial_balances = [({ owner = Principal.fromText("@todo:sardariuss"); subaccount = null;}, 100_000_000_000_000)];
          min_burn_amount = 1_000_000_000; // @todo
          minting_account = { owner = this(); subaccount = null; };
          advanced_settings = null;
        }); 
      };
      case (_) { Debug.trap("Already initialized"); };
    };
  };

  func this() : Principal {
    Principal.fromActor(this_);
  };

  func token() : Token {
    switch(token_){
      case (?t) { t; };
      case (null) { Debug.trap("Not initialized"); };
    };
  };

  /// Functions for the ICRC1 token standard

  public shared query func icrc1_name() : async Text {
    ICRC1.name(token());
  };

  public shared query func icrc1_symbol() : async Text {
    ICRC1.symbol(token());
  };

  public shared query func icrc1_decimals() : async Nat8 {
    ICRC1.decimals(token());
  };

  public shared query func icrc1_fee() : async ICRC1.Balance {
    ICRC1.fee(token());
  };

  public shared query func icrc1_metadata() : async [ICRC1.MetaDatum] {
    ICRC1.metadata(token());
  };

  public shared query func icrc1_total_supply() : async ICRC1.Balance {
    ICRC1.total_supply(token());
  };

  public shared query func icrc1_minting_account() : async ?ICRC1.Account {
    ?ICRC1.minting_account(token());
  };

  public shared query func icrc1_balance_of(args : ICRC1.Account) : async ICRC1.Balance {
    ICRC1.balance_of(token(), args);
  };

  public shared query func icrc1_supported_standards() : async [ICRC1.SupportedStandard] {
    ICRC1.supported_standards(token());
  };

  public shared ({ caller }) func icrc1_transfer(args : ICRC1.TransferArgs) : async ICRC1.TransferResult {
    await ICRC1.transfer(token(), args, caller);
  };

  public shared ({ caller }) func mint(args : ICRC1.Mint) : async ICRC1.TransferResult {
    await ICRC1.mint(token(), args, caller);
  };

  public shared ({ caller }) func burn(args : ICRC1.BurnArgs) : async ICRC1.TransferResult {
    await ICRC1.burn(token(), args, caller);
  };

  // Functions from the rosetta icrc1 ledger
  public shared query func get_transactions(req : ICRC1.GetTransactionsRequest) : async ICRC1.GetTransactionsResponse {
    ICRC1.get_transactions(token(), req);
  };

  // Additional functions not included in the ICRC1 standard
  public shared func get_transaction(i : ICRC1.TxIndex) : async ?ICRC1.Transaction {
    await ICRC1.get_transaction(token(), i);
  };

  // Deposit cycles into this archive canister.
  public shared func deposit_cycles() : async () {
    let amount = ExperimentalCycles.available();
    let accepted = ExperimentalCycles.accept(amount);
    assert (accepted == amount);
  };

};
