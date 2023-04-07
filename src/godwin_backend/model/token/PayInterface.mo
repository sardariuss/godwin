import MasterTypes "../../../godwin_master/Types";
import Types "../Types";
import WRef "../../utils/wrappers/WRef";
import WSet "../../utils/wrappers/WSet";
import WMap "../../utils/wrappers/WMap";

import Ref "../../utils/Ref";

import Map "mo:map/Map";
import Set "mo:map/Set";

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Deque "mo:base/Deque";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Buffer "mo:base/Buffer";

import Token "canister:godwin_token";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Deque<T> = Deque.Deque<T>;
  type WSet<K> = WSet.WSet<K>;
  type Set<K> = Set.Set<K>;
  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;
  type WMap<K, V> = WMap.WMap<K, V>;
  type Map<K, V> = Map.Map<K, V>;

  public type PayoutArgs = {
    #REAP_ACCOUNT: Token.ReapAccountArgs;
    #MINT_BATCH: Token.MintBatchArgs;
  };

  public type PayoutError = {
    #REAP_ACCOUNT: { args: Token.ReapAccountArgs; time: Nat64; result: Token.ReapAccountResult or { #Trapped }; };
    #MINT_BATCH:   { args: Token.MintBatchArgs;   time: Nat64; result: Token.MintBatchResult   or { #Trapped }; };
  };

  public func build(
    master: Principal,
    pending_payouts: Ref<Deque<PayoutArgs>>,
    payout_errors: Map<Nat, PayoutError>,
    payout_error_index: Ref<Nat>
  ) : PayInterface {
    PayInterface(
      actor(Principal.toText(master)),
      WRef.WRef(pending_payouts),
      WMap.WMap(payout_errors, Map.nhash),
      WRef.WRef(payout_error_index)
    );
  };

//  public type ReapAccountResult = {
//    #Ok : [ ICRC1.TransferResult ];
//    #Err : ReapAccountError;
//  };
//
//  public type ReapAccountRecipient = {
//    account : ICRC1.Account;
//    share : Float;
//  };
//
//  public type ReapAccountArgs = {
//    subaccount : ?ICRC1.Subaccount;
//    to : [ReapAccountRecipient];
//    memo : ?Blob;
//  };
//
//  public type MintRecipient = {
//    account : ICRC1.Account;
//    amount : ICRC1.Balance;
//  };
//
//  public type MintBatchArgs = {
//    to : [MintRecipient];
//    memo : ?Blob;
//  };
//
//  public type MintBatchResult = {
//    #Ok : [ ICRC1.TransferResult ];
//    #Err : ICRC1.TransferError;
//  };

  public class PayInterface(
    _master_actor: MasterTypes.MasterInterface,
    _pending_payouts: WRef<Deque<PayoutArgs>>,
    _payout_errors: WMap<Nat, PayoutError>,
    _payout_error_index: WRef<Nat>
  ){

    public func transferToSubaccount(sub_subaccount: Blob, principal: Principal, amount: Nat) : async* Result<(), Text> {
      switch(await _master_actor.transferToSubGodwin(principal, amount, sub_subaccount)){
        case(#ok(_)) { #ok; };
        case(#err(err)) { 
          #err(MasterTypes.transferErrorToText(err));
        };
      };
    };

    public func addPayout(args: PayoutArgs) {
      _pending_payouts.set(Deque.pushBack(_pending_payouts.get(), args));
    };

    public func processPayout() : async() {
      
      // Remove the first element from the queue
      let (payout, deque) = switch(Deque.popFront(_pending_payouts.get())){
        case(null) { return; }; // Nothing to do
        case(?(elem, deque)) { (elem, deque) };
      };
      _pending_payouts.set(deque);

      let time = Nat64.fromNat(Int.abs(Time.now()));

      switch(payout){
        case(#REAP_ACCOUNT(args)) {
          // Add it preemptively to the payout errors in case the transfer traps
          
          let index = _payout_error_index.get();
          let error = #REAP_ACCOUNT({ args; time; result = #Trapped; });
          _payout_errors.set(index, error);
          _payout_error_index.set(index + 1);

          let reap_result = await Token.reap_account(args);
          switch(reap_result){
            case(#Ok(transfers)) {
              // Remove it from the failed payouts
              _payout_errors.delete(index);
            };
            case(#Err(err)) {
              // Update the error
              _payout_errors.set(index, { error with result = reap_result; });
            };
          };
        };
        case(#MINT_BATCH(args)) {
          // Add it preemptively to the payout errors in case the transfer traps
          //_payout_errors.add(#MINT_BATCH({ args; time; result = #Trapped; }));


        };
      };
    };

    public func getPayoutErrors() : [(Nat, PayoutError)] {
      Iter.toArray(_payout_errors.entries());
    };

  };
 
}