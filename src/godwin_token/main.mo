import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Float "mo:base/Float";

import ExperimentalCycles "mo:base/ExperimentalCycles";

import ICRC1 "mo:icrc1/ICRC1";

actor Token {

  // @todo: fix args
  let token_args : ICRC1.InitArgs = {
    name = "Godwin";
    symbol = "GDW";
    decimals = 6;
    fee = 666;
    max_supply = 1_000_000_000_000_000;
    initial_balances = [({ owner = Principal.fromText("l2dqn-dqd5a-er3f7-h472o-ainav-j3ll7-iavjt-4v6ib-c6bom-duooy-uqe"); subaccount = null;}, 100_000_000_000_000)];
    min_burn_amount = 1_000_000_000;
    minting_account = { owner = Principal.fromText("rrkah-fqaaa-aaaaa-aaaaq-cai"); subaccount = null; };
    advanced_settings = null;
  };

  stable let token = ICRC1.init(token_args);

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

  public shared query func icrc1_fee() : async ICRC1.Balance {
    ICRC1.fee(token);
  };

  public shared query func icrc1_metadata() : async [ICRC1.MetaDatum] {
    ICRC1.metadata(token);
  };

  public shared query func icrc1_total_supply() : async ICRC1.Balance {
    ICRC1.total_supply(token);
  };

  public shared query func icrc1_minting_account() : async ?ICRC1.Account {
    ?ICRC1.minting_account(token);
  };

  public shared query func icrc1_balance_of(args : ICRC1.Account) : async ICRC1.Balance {
    ICRC1.balance_of(token, args);
  };

  public shared query func icrc1_supported_standards() : async [ICRC1.SupportedStandard] {
    ICRC1.supported_standards(token);
  };

  public shared ({ caller }) func icrc1_transfer(args : ICRC1.TransferArgs) : async ICRC1.TransferResult {
    await* ICRC1.transfer(token, args, caller);
  };

  public shared ({ caller }) func mint(args : ICRC1.Mint) : async ICRC1.TransferResult {
    await* ICRC1.mint(token, args, caller);
  };

  public shared ({ caller }) func burn(args : ICRC1.BurnArgs) : async ICRC1.TransferResult {
    await* ICRC1.burn(token, args, caller);
  };

  // Functions from the rosetta icrc1 ledger
  public shared query func get_transactions(req : ICRC1.GetTransactionsRequest) : async ICRC1.GetTransactionsResponse {
    ICRC1.get_transactions(token, req);
  };

  // Additional functions not included in the ICRC1 standard
  public shared func get_transaction(i : ICRC1.TxIndex) : async ?ICRC1.Transaction {
    await* ICRC1.get_transaction(token, i);
  };

  // Deposit cycles into this archive canister.
  public shared func deposit_cycles() : async () {
    let amount = ExperimentalCycles.available();
    let accepted = ExperimentalCycles.accept(amount);
    assert (accepted == amount);
  };

  ///////////////////////////////////////////

  // Additional functions specific to godwin

  public type TransferError = ICRC1.TransferError;

  public type ReapAccountError = {
    #InsufficientFunds : { balance : ICRC1.Balance; };
    #NoRecipients;
    #NegativeShare: ReapAccountRecipient;
    #DivisionByZero : { sum_shares : Float; };
  };

  public type ReapAccountResult = {
    #Ok : [ (ICRC1.TransferArgs, ICRC1.TransferResult)];
    #Err : ReapAccountError;
  };

  public type ReapAccountRecipient = {
    account : ICRC1.Account;
    share : Float;
  };

  public type ReapAccountArgs = {
    subaccount : ?ICRC1.Subaccount;
    to : [ReapAccountRecipient];
    memo : ?Blob;
  };

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

    let results = Buffer.Buffer<(ICRC1.TransferArgs, ICRC1.TransferResult)>(num_recipients);

    for ({account; share;} in args.to.vals()) {
      let tranfer_args : ICRC1.TransferArgs = {
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

  public type MintRecipient = {
    account : ICRC1.Account;
    amount : ICRC1.Balance;
  };

  public type MintBatchArgs = {
    to : [MintRecipient];
    memo : ?Blob;
  };

  public type MintBatchResult = {
    #Ok : [(ICRC1.Mint, ICRC1.TransferResult)];
    #Err : ICRC1.TransferError;
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

    let results = Buffer.Buffer<(ICRC1.Mint, ICRC1.TransferResult)>(args.to.size());

    for ({account; amount;} in Array.vals(args.to)) {
      let mint_args : ICRC1.Mint = {
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
