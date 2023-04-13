import Types               "Types";
import PayInterface        "PayInterface";
import SubaccountGenerator "SubaccountGenerator";

import WMap                "../../utils/wrappers/WMap";
import WRef                "../../utils/wrappers/WRef";
import Ref                 "../../utils/Ref";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";
import Buffer              "mo:base/Buffer";
import Iter                "mo:base/Iter";

module {

  type Result<Ok, Err>  = Result.Result<Ok, Err>;

  type Ref<T>           = Ref.Ref<T>;
  type WRef<T>          = WRef.WRef<T>;
  type WMap<K, V>       = WMap.WMap<K, V>;
  type Map<K, V>        = Map.Map<K, V>;

  type PayInterface     = PayInterface.PayInterface;
  type Subaccount       = Types.Subaccount;
  type Balance          = Types.Balance;
  type PayInError       = Types.PayInError;
  type PayoutError      = Types.PayoutError;
  type SubaccountPrefix = Types.SubaccountPrefix;
  
  type Id = Nat;

  public func build(
    pay_interface: PayInterface,
    subaccount_prefix: SubaccountPrefix,
    lock_register: Map<Id, (Principal, Subaccount)>,
    //failed_payout_register: Map<Id, PayoutError>,
    subaccount_index: Ref<Nat>
  ) : PayForNew {
    PayForNew(
      pay_interface,
      subaccount_prefix,
      WMap.WMap(lock_register, Map.nhash),
      //WMap.WMap(failed_payout_register, Map.nhash),
      WRef.WRef(subaccount_index)
    );
  };

  public class PayForNew(
    _pay_interface: PayInterface,
    _subaccount_prefix: SubaccountPrefix,
    _lock_register: WMap<Id, (Principal, Subaccount)>,
    //_failed_payout_register: WMap<Id, PayoutError>,
    _subaccount_index: WRef<Nat>
  ){

    public func payNew(buyer: Principal, price: Balance, create_new: () -> Id) : async* Result<Id, PayInError>{
      let subaccount = getNextSubaccount();
      switch(await* _pay_interface.payIn(subaccount, buyer, price)) {
        case (#err(err)) { #err(err); };
        case (#ok(_)) {
          let id = create_new();
          _lock_register.set(id, (buyer, subaccount));
          return #ok(id);
        };
      };
    };

    public func refund(elem: Id, share: Float) : async* () {
      let (principal, subaccount) = switch(_lock_register.getOpt(elem)){
        case(null) { Debug.trap("Refund aborted (elem '" # Nat.toText(elem) # "'') : not found in the map"); };
        case(?v) { v; };
      };
      switch(await* _pay_interface.payOut(subaccount, Buffer.fromArray([{to = principal; share; }]))){
        case (#err(err)) { /*_failed_payout_register.set(elem, err);*/ };
        case (#ok(_)) {};
      };
      _lock_register.delete(elem);
    };

//    public func findFailedRefund(elem: Id) : ?PayoutError {
//      _failed_payout_register.getOpt(elem);
//    };
//
//    public func findFailedRefunds() : [(Id, PayoutError)] {
//      Iter.toArray(_failed_payout_register.entries());
//    };

    func getNextSubaccount() : Subaccount {
      let subaccount = SubaccountGenerator.getSubaccount(_subaccount_prefix, _subaccount_index.get());
      _subaccount_index.set(_subaccount_index.get() + 1);
      subaccount;
    };
  
  };

 
};