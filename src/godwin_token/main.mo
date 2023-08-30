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
  type ReapAccountError        = Types.ReapAccountError;
  type ReapAccountResult       = Types.ReapAccountResult;
  type ReapAccountRecipient    = Types.ReapAccountRecipient;
  type ReapAccountArgs         = Types.ReapAccountArgs;
  type MintBatchArgs           = Types.MintBatchArgs;
  type MintBatchResult         = Types.MintBatchResult;

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

  /// Reap an account by distributing its balance to the provided list of recipients. 
  /// Each recipient receive the specified share of the balance.
  /// The sum of all the shares must be less than or equal to 1.0.
  /// If the sum of all the shares is less than 1.0, the remaining balance is burned.
  /// \param[in] args, the ReapAccountArgs that contains the list of recipients, the memo
  ///                  and the subaccount to reap.
  /// \return Ok with the list of TransferResult if the reaping was successful.
  ///         Err with the corresponding error otherwise.
  /// @todo: implement this function directly in the module to avoid multiple usage of await* functions.
  public shared ({ caller }) func reap_account(args : ReapAccountArgs) : async ReapAccountResult {
    
    // Get the balance of the account
    let account_balance = ICRC1.balance_of(token, { owner = caller; subaccount = args.subaccount; });

    // Deduce the amount to distribute (by removing a fee for each recipient)
    let num_recipients = args.to.size();
    let balance_without_fees : Int = account_balance - token._fee * num_recipients;
    if (balance_without_fees <= 0) {
      return #Err(#InsufficientFunds({balance = account_balance;}));
    };

    // Compute the share for every recipient
    var total_amount : Nat = 0;
    var sum_shares = 0.0;
    let to_transfer = Buffer.Buffer<(Account, Balance)>(num_recipients);
    for ({account; share} in Array.vals(args.to)){
      if (share < 0.0) {
        // A share cannot be negative
        return #Err(#NegativeShare({account; share;}));
      };
      let amount = Int.abs(Float.toInt(Float.trunc(Float.fromInt(balance_without_fees) * share)));
      to_transfer.add(account, amount);
      total_amount += amount;
      sum_shares += share;
    };
    // The sum of all the shares must be less than or equal to 1.0
    // Perform the comparison on the total amount instead of the sum of the shares
    // to avoid comparison errors due to floating point arithmetic.
    if (total_amount > balance_without_fees){
      return #Err(#BalanceExceeded({sum_shares; total_amount; balance_without_fees = Int.abs(balance_without_fees);}));
    };

    // Transfer each share to the corresponding account
    let results = Buffer.Buffer<(TransferArgs, TransferResult)>(num_recipients);
    for ((to, amount) in to_transfer.vals()) {
      let tranfer_args : TransferArgs = {
        from_subaccount = args.subaccount;
        to;
        amount;
        fee = ?token._fee;
        memo = args.memo;
        created_at_time = null; // Has to be null because two transfers can't have the same timestamp
      };
      results.add(tranfer_args, (await* ICRC1.transfer(token, tranfer_args, caller)));
    };

    // Burn the remaining balance if any
    let remaining_balance = ICRC1.balance_of(token, { owner = caller; subaccount = args.subaccount; });
    if (remaining_balance > 0) {
      let burn_args = { 
        from_subaccount = args.subaccount;
        amount = remaining_balance;
        memo = null;
        created_at_time = null; // Has to be null because two transfers can't have the same timestamp
      };
      ignore await* ICRC1.burn(token, burn_args, caller);
    };
    
    // Return the results of the transfers
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
