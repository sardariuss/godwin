import WMap "../../utils/wrappers/WMap";
import WRef "../../utils/wrappers/WRef";
import Ref "../../utils/Ref";

import Map "mo:map/Map";

import PayInterface "PayInterface";
import SubaccountGenerator "SubaccountGenerator";

import Result "mo:base/Result";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;
  type WMap<K, V> = WMap.WMap<K, V>;
  type Map<K, V> = Map.Map<K, V>;

  type PayInterface = PayInterface.PayInterface;
  type Subaccount = PayInterface.Subaccount;
  type Balance = PayInterface.Balance;
  type PayInError = PayInterface.PayInError;
  type PayoutError = PayInterface.PayoutError;
  type SubaccountType = SubaccountGenerator.SubaccountType;
  
  type Id = Nat;

  public func build(
    pay_interface: PayInterface,
    subaccount_type: SubaccountType,
    map_paid: Map<Id, (Principal, Subaccount)>,
    index: Ref<Nat>,
  ) : PayForNew {
    PayForNew(pay_interface, subaccount_type, WMap.WMap(map_paid, Map.nhash), WRef.WRef(index));
  };

  public class PayForNew(
    _pay_interface: PayInterface,
    _subaccount_type: SubaccountType,
    _map_paid: WMap<Id, (Principal, Subaccount)>,
    _index: WRef<Nat>
  ){

    public func payNew(buyer: Principal, price: Balance, create_new: () -> Id) : async* Result<Id, PayInError>{
      
      let subaccount = getNextSubaccount();

      switch(await* _pay_interface.payIn(subaccount, buyer, price)) {
        case (#err(err)) { #err(err); };
        case (#ok(_)) {
          let id = create_new();
          _map_paid.set(id, (buyer, subaccount));
          return #ok(id);
        };
      };
    };

    public func refund(elem: Id, share: Float) : async* () {

      let (principal, subaccount) = switch(_map_paid.getOpt(elem)){
        case(null) { Debug.trap("Refund aborted (elem '" # Nat.toText(elem) # "'') : not found in the map"); };
        case(?v) { v; };
      };

      let payout_result = await* _pay_interface.payOut(subaccount,  Buffer.fromArray([{to = principal; share; }]));

      switch(payout_result) {
        case (#err(err)) { Debug.print("Refund failed (elem'" # Nat.toText(elem) # "'') : payout error"); };
        case (#ok(_)) {
          // @todo: shall we always delete the elem from the map ?
          _map_paid.delete(elem);
        };
      };

    };

    func getNextSubaccount() : Subaccount {
      let subaccount = SubaccountGenerator.getSubaccount(_subaccount_type, _index.get());
      _index.set(_index.get() + 1);
      subaccount;
    };
  
  };

 
};