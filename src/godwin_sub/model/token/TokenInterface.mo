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
  type ICRC1TokenInterface            = Types.ICRC1TokenInterface;
  type Subaccount                     = Types.Subaccount;
  type Balance                        = Types.Balance;
  type Account                        = Types.Account;
  type CanisterCallError              = Types.CanisterCallError;
  type PullBtcResult                  = Types.PullBtcResult;
  type RedistributeBtcReceiver        = Types.RedistributeBtcReceiver;
  type RedistributeBtcResult          = Types.RedistributeBtcResult;
  type RewardGwcReceiver              = Types.RewardGwcReceiver;
  type RewardGwcResult                = Types.RewardGwcResult;
  type TransferArgs                   = Types.TransferArgs;
  type TransferResult                 = Types.TransferResult;
  type ITokenInterface                = Types.ITokenInterface;

  public func build({master: Principal; gwc: Principal; ck_btc: Principal}) : TokenInterface {
    TokenInterface(
      actor(Principal.toText(master)) : MasterInterface,
      actor(Principal.toText(gwc)) : ICRC1TokenInterface,
      actor(Principal.toText(ck_btc)) : ICRC1TokenInterface
    );
  };

  public class TokenInterface(
    _master: MasterInterface,
    _gwc: ICRC1TokenInterface, // unused for now
    _ck_btc: ICRC1TokenInterface
  ) : ITokenInterface {

    var _self_id : ?Principal = null;

    public func setSelfId(self_id: Principal) {
      _self_id := ?self_id;
    };

    func unwrapSelfId() : Principal {
      switch(_self_id){
        case(null) { Debug.trap("Self principal is not set"); };
        case(?self_id) { self_id; };
      };
    };

    public func pullBtc(from: Principal, to_subaccount: Blob, amount: Balance) : async PullBtcResult {
      try {
        await _master.pullBtc(from, amount, ?to_subaccount);
      } catch(e) {
        #err(toCanisterCallError(Principal.fromActor(_master), "pullBtc", e));
      };
    };
    
    public func redistributeBtc(subaccount: Blob, receivers: Iter<RedistributeBtcReceiver>) : async Trie<Principal, ?RedistributeBtcResult> {

      var results : Trie<Principal, ?RedistributeBtcResult> = Trie.empty();

      // Get the receivers in an array to be able to iterate over them more than once
      let array_receivers = Iter.toArray(receivers);

      let fee = await _ck_btc.icrc1_fee();
      let balance = await _ck_btc.icrc1_balance_of({ owner = unwrapSelfId(); subaccount = ?subaccount; });

      // Remove a fee for each positive share to distribute
      // Return insufficient fees error if the sum of the fees is greater or equal to the subaccount balance
      let sum_fees = Array.foldLeft(array_receivers, 0, func(sum: Nat, { share; }: RedistributeBtcReceiver) : Nat {
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
      let to_transfer = Array.map<RedistributeBtcReceiver, (Principal, Balance)>(array_receivers, func({ to; share; }: RedistributeBtcReceiver) : (Principal, Balance) {
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
              await _ck_btc.icrc1_transfer({
                from_subaccount = ?subaccount;
                to = getMasterAccount(?to);
                memo = null;
                amount = owed;
                fee = ?fee;
                created_at_time = null;
              });
            } catch(e) {
              #Err(toCanisterCallError(Principal.fromActor(_ck_btc), "icrc1_transfer", e));
            }
          );
        };
        results := Trie.put(results, key(to), Principal.equal, result).0;
      };

      return results;
    };

    public func rewardGwcToAll(receivers: Iter<RewardGwcReceiver>) : async Trie<Principal, ?RewardGwcResult> {

      var results : Trie<Principal, ?RewardGwcResult> = Trie.empty();
      let recipients = Buffer.Buffer<RewardGwcReceiver>(0);
      for ({to; amount;} in receivers){
        results := Trie.put(results, key(to), Principal.equal, null).0;
        recipients.add({ to; amount; });
      };

      let reward_result = try {
        await _master.rewardGwc(Buffer.toArray(recipients));
      } catch(e) {
        #err(toCanisterCallError(Principal.fromActor(_master), "rewardGwc", e));
      };

      switch(reward_result) {
        case(#err(err)) {
          for ((k, v) in Trie.iter(results)){
            results := Trie.put(results, key(k), Principal.equal, ?#err(err)).0;
          };
        };
        case(#ok(transfer_results)){
          for ((receiver, result) in Array.vals(transfer_results)){
            results := Trie.put(results, key(receiver.to), Principal.equal, ?result).0;
          };
        };
      };

      results;
    };

    public func rewardGwc(receiver: RewardGwcReceiver) : async RewardGwcResult {
      let result = try {
        await _master.rewardGwc([receiver]);
      } catch(e) {
        #err(toCanisterCallError(Principal.fromActor(_master), "rewardGwc", e));
      };
      switch(result){
        case(#err(err)) { #err(err); };
        case(#ok(transfer_results)) { transfer_results[0].1; };
      };
    };

    func getMasterAccount(principal: ?Principal) : Account {
      { owner = Principal.fromActor(_master); subaccount = Option.map(principal, func(p: Principal) : Blob { Account.toSubaccount(p); }); };
    };

  };

  private func toCanisterCallError(principal: Principal, method: Text, error: Error) : CanisterCallError {
    #CanisterCallError({ canister = principal; method; code = Error.code(error); message = Error.message(error); });
  };
 
};