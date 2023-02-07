import WMap "wrappers/WMap";
import OrderedSet "OrderedSet";
import Utils "Utils";

import Map "mo:map/Map";

import Order "mo:base/Order";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Order = Order.Order;
  type Iter<T> = Iter.Iter<T>;
  type OrderedSet<K> = OrderedSet.OrderedSet<K>;
  
  type WMap<K, V> = WMap.WMap<K, V>;
  type Map<K, V> = Map.Map<K, V>;
  
  public type Direction = OrderedSet.Direction;
  public type ScanLimitResult = OrderedSet.ScanLimitResult<Nat>;

  public type Register<OrderBy, Key> = Map<OrderBy, Inner<Key>>;
  
  type Inner<Key> = {
    key_map: Map<Nat, Key>;
    var ordered_set: OrderedSet<Key>;
  };

  public func initRegister<OrderBy, Key>() : Register<OrderBy, Key> {
    Map.new<OrderBy, Inner<Key>>();
  };

  public func addOrderBy<OrderBy, Key>(register: Register<OrderBy, Key>, hash: Map.HashUtils<OrderBy>, order_by: OrderBy) {
    if(Option.isNull(Map.get(register, hash, order_by))){
      Map.set(register, hash, order_by, { key_map = Map.new<Nat,Key>(); var ordered_set = OrderedSet.init<Key>(); });
    };
  };

  public func build<OrderBy, Key>(
    register: Register<OrderBy, Key>,
    hash: Map.HashUtils<OrderBy>,
    compare_keys: (Key, Key) -> Order,
    to_order_by_ : (Key) -> OrderBy,
    get_identifier: (Key) -> Nat
  ) : Queries<OrderBy, Key> {
    Queries(WMap.WMap(register, hash), compare_keys, to_order_by_, get_identifier);
  };

  type WRegister<OrderBy, Key> = WMap<OrderBy, Inner<Key>>;

  public class Queries<OrderBy, Key>(
    register_: WRegister<OrderBy, Key>, 
    compare_keys_: (Key, Key) -> Order,
    to_order_by_ : (Key) -> OrderBy,
    get_identifier_: (Key) -> Nat
  ) {

    public func add(key: Key) {
      Option.iterate(register_.get(to_order_by_(key)), func(inner: Inner<Key>){
        let id = get_identifier_(key);
        if (Map.has(inner.key_map, Map.nhash, id)) {
          Debug.trap("Cannot add new element with id '" # Nat.toText(id) # "' because it already exists for this order_by");
        };
        Map.set(inner.key_map, Map.nhash, id, key);
        inner.ordered_set := OrderedSet.put(inner.ordered_set, compare_keys_, key);
      });
    };

    public func remove(key: Key) {
      Option.iterate(register_.get(to_order_by_(key)), func(inner: Inner<Key>){
        let id = get_identifier_(key);
        if (not Map.has(inner.key_map, Map.nhash, id)) {
          Debug.trap("Cannot remove element with id '" # Nat.toText(id) # "' because it does not exist for this order_by");
        };
        Map.delete(inner.key_map, Map.nhash, id);
        inner.ordered_set := OrderedSet.delete(inner.ordered_set, compare_keys_, key);
      });
    };

    public func replace(old: ?Key, new: ?Key) {
      Option.iterate(old, func(key: Key) { remove(key); });
      Option.iterate(new, func(key: Key) { add(key);    });
    };

    public func scan(
      order_by: OrderBy,
      lower_bound: ?Nat,
      upper_bound: ?Nat,
      direction: Direction,
      limit: Nat
    ) : ScanLimitResult {
      switch(register_.get(order_by)){
        case(null){ Debug.trap("Cannot find ordered_set for this order_by"); };
        case(?inner){
          switch(OrderedSet.keys(inner.ordered_set).next()){
            case(null){ { keys = []; next = null; } };
            case(?first){
              switch(OrderedSet.keysRev(inner.ordered_set).next()){
                case(null){ { keys = []; next = null; } };
                case(?last){
                  let lower = Option.getMapped(lower_bound, func(id: Nat) : Key { unwrapKey(id, order_by); }, first);
                  let upper = Option.getMapped(upper_bound, func(id: Nat) : Key { unwrapKey(id, order_by); }, last);
                  let scan = OrderedSet.scanLimit(inner.ordered_set, compare_keys_, lower, upper, direction, limit);
                  {
                    keys = Array.map(scan.keys, func(key: Key) : Nat { get_identifier_(key); });
                    next = Option.map(scan.next, func(key: Key) : Nat { get_identifier_(key); });
                  };
                };
              };
            };
          };
        };
      };
    };

    public func select(
      order_by: OrderBy,
      direction: Direction,
      limit: Nat,
      previous: ?Nat
    ) : ScanLimitResult {
      switch(direction){
        case(#FWD){ scan(order_by, previous, null, direction, limit); };
        case(#BWD){ scan(order_by, null, previous, direction, limit); };
      };
    };

    public func iter(order_by: OrderBy, direction: Direction) : Iter<Nat> {
      switch(register_.get(order_by)){
        case(null){ Debug.trap("Cannot find rbt for this order_by"); };
        case(?inner){ 
          Iter.map(OrderedSet.iter(inner.ordered_set, direction), func(key: Key) : Nat { get_identifier_(key); });
        };
      };
    };

    func unwrapKey(id: Nat, order_by: OrderBy) : Key {
      switch(register_.get(order_by)){
        case(null){ Debug.trap("Cannot find ordered_set for this order_by"); };
        case(?inner){
          switch(Map.get(inner.key_map, Map.nhash, id)){
            case(null){ Debug.trap("Cannot find key for this id"); };
            case(?key){ key; };
          };
        };
      };
    };

  };

};