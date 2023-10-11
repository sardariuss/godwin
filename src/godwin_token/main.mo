import Types              "Types";

import Principal          "mo:base/Principal";
import Buffer             "mo:base/Buffer";
import Int                "mo:base/Int";
import Array              "mo:base/Array";
import Float              "mo:base/Float";
import Debug              "mo:base/Debug";

import ExperimentalCycles "mo:base/ExperimentalCycles";

import ICRC1              "mo:icrc1/ICRC1";

shared({ caller = _owner }) actor class GodwinToken(token_args : ICRC1.TokenInitArgs) : async Types.FullInterface {

  type Account                 = Types.Account;
  type Transaction             = Types.Transaction;
  type Balance                 = Types.Balance;
  type TransferArgs            = Types.TransferArgs;
  type Mint                    = Types.Mint;
  type BurnArgs                = Types.BurnArgs;
  type SupportedStandard       = Types.SupportedStandard;
  type InitArgs                = Types.InitArgs;
  type MetaDatum               = Types.MetaDatum;
  type TxIndex                 = Types.TxIndex;
  type GetTransactionsRequest  = Types.GetTransactionsRequest;
  type GetTransactionsResponse = Types.GetTransactionsResponse;
  type TransferResult          = Types.TransferResult;
  type TransferError           = Types.TransferError;

  stable let token = ICRC1.init({
    token_args with minting_account = switch(token_args.minting_account){
      case(?account) { account; };
      case(null) { Debug.trap("Minting account must be specified"); };
    }
  });

  /// Functions for the ICRC1 token standard
  public shared query func icrc1_name() : async Text {
    ICRC1.name(token);
  };

  public shared query func icrc1_symbol() : async Text {
    ICRC1.symbol(token);
  };

  public shared query func icrc1_decimals() : async Nat8 {
    ICRC1.decimals(token);
  };

  public shared query func icrc1_fee() : async Balance {
    ICRC1.fee(token);
  };

  public shared query func icrc1_metadata() : async [MetaDatum] {
    ICRC1.metadata(token);
  };

  public shared query func icrc1_total_supply() : async Balance {
    ICRC1.total_supply(token);
  };

  public shared query func icrc1_minting_account() : async ?Account {
    ?ICRC1.minting_account(token);
  };

  public shared query func icrc1_balance_of(args : Account) : async Balance {
    ICRC1.balance_of(token, args);
  };

  public shared query func icrc1_supported_standards() : async [SupportedStandard] {
    ICRC1.supported_standards(token);
  };

  public shared ({ caller }) func icrc1_transfer(args : TransferArgs) : async TransferResult {
    await* ICRC1.transfer(token, args, caller);
  };

  public shared ({ caller }) func mint(args : Mint) : async TransferResult {
    await* ICRC1.mint(token, args, caller);
  };

  public shared ({ caller }) func burn(args : BurnArgs) : async TransferResult {
    await* ICRC1.burn(token, args, caller);
  };

  // Functions from the rosetta icrc1 ledger
  public shared query func get_transactions(req : GetTransactionsRequest) : async GetTransactionsResponse {
    ICRC1.get_transactions(token, req);
  };

  // Additional functions not included in the ICRC1 standard
  public shared func get_transaction(i : TxIndex) : async ?Transaction {
    await* ICRC1.get_transaction(token, i);
  };

  // Deposit cycles into this archive canister.
  public shared func deposit_cycles() : async () {
    let amount = ExperimentalCycles.available();
    let accepted = ExperimentalCycles.accept(amount);
    assert (accepted == amount);
  };

  public query func get_cycles_balance() : async Nat {
    ExperimentalCycles.balance();
  };

};
