import FailedPayout "FailedPayout";
import MasterTypes "../../../godwin_master/Types";
import Types "../Types";
import WRef "../../utils/wrappers/WRef";
import WSet "../../utils/wrappers/WSet";

import Ref "../../utils/Ref";

import Set "mo:map/Set";

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Deque "mo:base/Deque";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

import Token "canister:godwin_token";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Deque<T> = Deque.Deque<T>;
  type WSet<K> = WSet.WSet<K>;
  type Set<K> = Set.Set<K>;
  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;

  type SubTransferArgs = Types.SubTransferArgs;
  type FailedPayout = Types.FailedPayout;

  public func build(
    master: Principal,
    pending_payouts: Ref<Deque<SubTransferArgs>>,
    failed_payouts: Set<FailedPayout>
  ) : PayInterface {
    PayInterface(
      actor(Principal.toText(master)),
      WRef.WRef(pending_payouts),
      WSet.WSet(failed_payouts, FailedPayout.hash)
    );
  };

  public class PayInterface(
    _master_actor: MasterTypes.MasterInterface,
    _pending_payouts: WRef<Deque<SubTransferArgs>>,
    _failed_payouts: WSet<FailedPayout>
  ){

    public func payin(sub_subaccount: Blob, principal: Principal, amount: Nat) : async* Result<(), Text> {
      switch(await _master_actor.transferToSubGodwin(principal, amount, sub_subaccount)){
        case(#ok(_)) { #ok; };
        case(#err(err)) { 
          #err(MasterTypes.transferErrorToText(err));
        };
      };
    };

    public func addPayout(sub_subaccount: Blob, principal: Principal, amount: Nat) {
      _pending_payouts.set(Deque.pushBack(_pending_payouts.get(), {sub_subaccount; principal; amount;}));
    };

    public func processPayout() : async() {
      
      // Remove the first element from the queue
      let (payout, deque) = switch(Deque.popFront(_pending_payouts.get())){
        case(null) { return; }; // Nothing to do
        case(?(elem, deque)) { (elem, deque) };
      };
      _pending_payouts.set(deque);

      // Add it preemptively to the failed payouts in case the transfer traps
      let time = Nat64.fromNat(Int.abs(Time.now()));
      let failed_payout = { payout and { time; error = #Trapped; } };
      ignore _failed_payouts.put(failed_payout);
      
      // Perform the transfer
      let transfer_result = await Token.icrc1_transfer({
        amount = payout.amount;
        created_at_time = ?time;
        fee = ?666; // @todo: try null ?
        from_subaccount = ?payout.sub_subaccount;
        memo = null;
        to = {
          owner = Principal.fromActor(_master_actor);
          subaccount = ?MasterTypes.toSubaccount(payout.principal);
        };
      });

      switch(transfer_result){
        case(#Ok(_)) {
          // Remove it from the failed payouts
          _failed_payouts.delete(failed_payout);
        };
        case(#Err(err)) {
          // Update the error
          ignore _failed_payouts.put({ failed_payout with error = err; });
        };
      };
    };

    public func getFailedPayouts() : [FailedPayout] {
      Iter.toArray(_failed_payouts.keys());
    };

  };
 
}