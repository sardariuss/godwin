import Types       "Types";

import Account     "../../utils/Account";

import Map         "mo:map/Map";

import Result      "mo:base/Result";
import Principal   "mo:base/Principal";
import Option      "mo:base/Option";
import Buffer      "mo:base/Buffer";
import Error       "mo:base/Error";
import Array       "mo:base/Array";
import Debug       "mo:base/Debug";
import Trie        "mo:base/Trie";
import Iter        "mo:base/Iter";
import Int         "mo:base/Int";
import Float       "mo:base/Float";

module {

  type Result<Ok, Err>                = Result.Result<Ok, Err>;
  type Buffer<T>                      = Buffer.Buffer<T>;
  type Map<K, V>                      = Map.Map<K, V>;
  type Trie<K, V>                     = Trie.Trie<K, V>;
  type Key<K>                         = Trie.Key<K>;
  type Iter<T>                        = Iter.Iter<T>;
  type Principal                      = Principal.Principal;
  func key(p: Principal) : Key<Principal> { { hash = Principal.hash(p); key = p; } };

  let { toBaseResult; } = Types;
  type MasterInterface                = Types.MasterInterface;
  type GodwinTokenInterface           = Types.GodwinTokenInterface;
  type Subaccount                     = Types.Subaccount;
  type Balance                        = Types.Balance;
  type Account                        = Types.Account;
  type CanisterCallError              = Types.CanisterCallError;
  type TransferFromMasterResult       = Types.TransferFromMasterResult;
  type ReapAccountReceiver            = Types.ReapAccountReceiver;
  type ReapAccountRecipient           = Types.ReapAccountRecipient;
  type ReapAccountResult              = Types.ReapAccountResult;
  type MintReceiver                   = Types.MintReceiver;
  type MintRecipient                  = Types.MintRecipient;
  type TransferArgs                   = Types.TransferArgs;
  type TransferResult                 = Types.TransferResult;
  type MintError                      = Types.MintError;
  type MintResult                     = Types.MintResult;
  type Mint                           = Types.Mint;
  type ITokenInterface                = Types.ITokenInterface;

  public func build({master: Principal; token: Principal}) : TokenInterface {
    TokenInterface(
      actor(Principal.toText(master)) : MasterInterface,
      actor(Principal.toText(token)) : GodwinTokenInterface
    );
  };

  public class TokenInterface(_master: MasterInterface, _token: GodwinTokenInterface) : ITokenInterface {

    public func transferFromMaster(from: Principal, to_subaccount: Blob, amount: Balance) : async TransferFromMasterResult {
      try {
        await _master.pullTokens(from, amount, ?to_subaccount);
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };
    
    public func reapSubaccount(subaccount: Blob, receivers: Iter<ReapAccountReceiver>) : async Trie<Principal, ?ReapAccountResult> {

      var results : Trie<Principal, ?ReapAccountResult> = Trie.empty();

      // Get the receivers in an array to be able to iterate over them more than once
      let array_receivers = Iter.toArray(receivers);

      let fee = await _token.icrc1_fee();
      let balance = await _token.icrc1_balance_of({ owner = Principal.fromText("aaaaa-aa"); subaccount = ?subaccount; }); // @todo

      // Remove a fee for each positive share to distribute
      // Return insufficient fees error if the sum of the fees is greater or equal to the subaccount balance
      let sum_fees = Array.foldLeft(array_receivers, 0, func(sum: Nat, { share; }: ReapAccountReceiver) : Nat {
        if (share > 0.0) { sum + fee; } else { sum; };
      });
      if (sum_fees >= balance) {
        for ({ to; share; } in Array.vals(array_receivers)){
          let result = #err(#InsufficientFees({ share; subaccount; balance; sum_fees; }));
          results := Trie.put(results, key(to), Principal.equal, ?result).0;
        };
        return results;
      };

      // Initialize the results with what is owed to each receiver
      // Return an error if the sum of shares is greater than the balance without the fees
      var total_owed : Nat = 0;
      let balance_without_fees = Int.abs(balance - sum_fees); // Convert to float here to avoid doing it everytime in the loop
      let to_transfer = Array.map<ReapAccountReceiver, (Principal, Balance)>(array_receivers, func({ to; share; }: ReapAccountReceiver) : (Principal, Balance) {
        let owed = if (share > 0.0) { Int.abs(Float.toInt(Float.fromInt(balance_without_fees) * share)); } else { 0; };
        total_owed += owed;
        (to, owed);
      });
      if (total_owed > balance_without_fees){
        for ((to, owed) in Array.vals(to_transfer)){
          let result = #err(#InvalidSumShares({ owed; subaccount; total_owed; balance_without_fees; }));
          results := Trie.put(results, key(to), Principal.equal, ?result).0;
        };
        return results;
      };

      for ((to, owed) in Array.vals(to_transfer)){
        let result = if (owed == 0) { null; } else {
          ?toBaseResult(
            try {
              await _token.icrc1_transfer({
                from_subaccount = ?subaccount;
                to = getMasterAccount(?to);
                memo = null;
                amount = owed;
                fee = ?fee;
                created_at_time = null;
              });
            } catch(e) {
              #Err(#CanisterCallError(Error.code(e)));
            }
          );
        };
        results := Trie.put(results, key(to), Principal.equal, result).0;
      };

      return results;
    };

    public func mintBatch(receivers: Iter<MintReceiver>) : async Trie<Principal, ?MintResult> {

      var results : Trie<Principal, ?MintResult> = Trie.empty();

      let map_recipients = Map.new<Subaccount, Principal>(Map.bhash);
      let to_accounts = Buffer.Buffer<MintRecipient>(0);

      for ({ to; amount; } in receivers){
        if (amount > 0) {
        // Add to the recipients 
        to_accounts.add({ account = getMasterAccount(?to); amount; });
        // Keep the mapping of subaccount <-> principal
        Map.set(map_recipients, Map.bhash, Account.toSubaccount(to), to);
        // Initialize the results map in case no error is found
        results := Trie.put(results, key(to), Principal.equal, ?#err(#SingleMintLost({ amount; }))).0;
        } else {
          results := Trie.put(results, key(to), Principal.equal, null).0;
        };
      };

      let mint_batch = try {
        await _master.mintBatch({
          to = Buffer.toArray(to_accounts);
          memo = null;
        });
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };

      switch(mint_batch) {
        case(#err(err)) {    
          for (receiver in receivers){
            results := Trie.put(results, key(receiver.to), Principal.equal, ?#err(err)).0;
          };
        };
        case(#ok(transfer_results)){
          for ((args, result) in Array.vals(transfer_results)){
            Option.iterate(transferToMintResult(map_recipients, args, result), func((principal, result): (Principal, MintResult)){
              results := Trie.put(results, key(principal), Principal.equal, ?result).0;
            });
          };
        };
      };

      results;
    };

    public func mint(to: Principal, amount: Balance) : async MintResult {
      let args = {
        to = getMasterAccount(?to);
        amount;
        memo = null;
        created_at_time = null;
      };
      
      let mint = try {
        await _master.mint(args);
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };

    func getMasterAccount(principal: ?Principal) : Account {
      { owner = Principal.fromActor(_master); subaccount = Option.map(principal, func(p: Principal) : Blob { Account.toSubaccount(p); }); };
    };

  };

  // @todo: in case the subaccount or the principal is ever null, the transfer will be lost
  func transferToMintResult(map_recipients: Map<Subaccount, Principal>, args: Mint, result: TransferResult) : ?(Principal, MintResult) {
    let opt_subaccount = args.to.subaccount;
    switch(opt_subaccount){
      case(null) { null; };
      case(?subaccount) {
        let opt_principal = Map.get(map_recipients, Map.bhash, subaccount);
        switch(opt_principal){
          case(null) { null; };
          case(?principal) {
            switch(result){
              case(#Ok(tx_index)) { ?(principal, #ok(tx_index));                                         };
              case(#Err(err))     { ?(principal, #err(#SingleMintError({ args = args; error = err; }))); };
            };
          };
        };
      };
    };
  };
 
};