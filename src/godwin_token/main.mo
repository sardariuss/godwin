import Types              "Types";

import Principal          "mo:base/Principal";
import Buffer             "mo:base/Buffer";
import Int                "mo:base/Int";
import Array              "mo:base/Array";
import Float              "mo:base/Float";
import Nat8               "mo:base/Nat8";
import Debug              "mo:base/Debug";
import Option             "mo:base/Option";

import ExperimentalCycles "mo:base/ExperimentalCycles";

import ICRC1              "mo:icrc1/ICRC1";

actor GodwinToken {
//shared({ caller = _owner }) actor class GodwinToken(token_args : ICRC1.TokenInitArgs) {

  type Account                 = Types.Account;
  type Subaccount              = Types.Subaccount;
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
  type ReapAccountError        = Types.ReapAccountError;
  type ReapAccountResult       = Types.ReapAccountResult;
  type ReapAccountRecipient    = Types.ReapAccountRecipient;
  type ReapAccountArgs         = Types.ReapAccountArgs;
  type MintRecipient           = Types.MintRecipient;
  type MintBatchArgs           = Types.MintBatchArgs;
  type MintBatchResult         = Types.MintBatchResult;

  let DECIMALS : Nat = 8;
  let TOKEN_UNIT : Nat = 10 ** DECIMALS;
  let TOKEN_SUPPLY : Nat = 1_000_000_000 * TOKEN_UNIT;
  let FEE : Nat = 10_000;

  // @todo: remove args
  let token_args : ICRC1.TokenInitArgs = {
    name = "Godwin";
    symbol = "GDW";
    decimals = Nat8.fromNat(DECIMALS);
    fee = FEE;
    max_supply = TOKEN_SUPPLY;
    initial_balances = [
      ({ owner = Principal.fromText("l2dqn-dqd5a-er3f7-h472o-ainav-j3ll7-iavjt-4v6ib-c6bom-duooy-uqe"); subaccount = null;}, 500_000_000 * TOKEN_UNIT), // deployer
      ({ owner = Principal.fromText("bkyz2-fmaaa-aaaaa-qaaaq-cai"); subaccount = null;}, 10_000_000 * TOKEN_UNIT)]; // airdrop
    min_burn_amount = FEE;
    minting_account = ?{ owner = Principal.fromText("br5f7-7uaaa-aaaaa-qaaca-cai"); subaccount = null; }; // master
    advanced_settings = null;
  };

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

  ///////////////////////////////////////////

  // Additional functions specific to godwin

  // Kind of an equivalent to icrc4_transfer_batch function, with pre_validate = false and batch_fee = null
  // but where only one account can be specified
  public shared ({ caller }) func reap_account(args : ReapAccountArgs) : async ReapAccountResult {
    
    let account_balance = ICRC1.balance_of(token, { owner = caller; subaccount = args.subaccount; });

    let num_recipients = args.to.size();

    if (num_recipients == 0) {
      return #Err(#NoRecipients);
    };

    let amount_without_fees : Int = account_balance - token._fee * num_recipients;

    if (amount_without_fees <= 0) {
      return #Err(#InsufficientFunds({balance = account_balance;}));
    };

    var sum_shares = 0.0;
    
    for ({account; share} in Array.vals(args.to)){
      if (share <= 0.0) {
        return #Err(#NegativeShare({account; share;}));
      };
      sum_shares += share;
    };

    if (sum_shares <= 0.0){
      return #Err(#DivisionByZero({sum_shares}));
    };

    let results = Buffer.Buffer<(TransferArgs, TransferResult)>(num_recipients);

    for ({account; share;} in args.to.vals()) {
      let tranfer_args : TransferArgs = {
        from_subaccount = args.subaccount;
        to = account;
        amount = Int.abs(Float.toInt(Float.trunc((Float.fromInt(amount_without_fees) * share) / sum_shares)));
        fee = ?token._fee;
        memo = args.memo;
        created_at_time = null; // Has to be null because two transfers can't have the same timestamp
      };
      results.add(tranfer_args, (await* ICRC1.transfer(token, tranfer_args, caller)));
    };

    // @todo: burn the remaining balance if any?
    
    return #Ok(Buffer.toArray(results));
  };

  public shared({caller}) func mint_batch(args : MintBatchArgs) : async MintBatchResult {
    
    if (caller != token.minting_account.owner) {
      return #Err(
        #GenericError {
          error_code = 401;
          message = "Unauthorized: Only the minting_account can mint tokens.";
        },
      );
    };

    let results = Buffer.Buffer<(Mint, TransferResult)>(args.to.size());

    for ({account; amount;} in Array.vals(args.to)) {
      let mint_args : Mint = {
        from_subaccount = null;
        to = account;
        amount;
        fee = ?token._fee;
        memo = args.memo;
        created_at_time = null; // Has to be null because two transfers can't have the same timestamp
      };

      results.add(mint_args, (await* ICRC1.mint(token, mint_args, caller)));
    };

    return #Ok(Buffer.toArray(results));
  };

};
