import Types      "Types";

import WMap       "wrappers/WMap";
import OrderedSet "OrderedSet";
import Utils      "Utils";

import Map        "mo:map/Map";

import Order      "mo:base/Order";
import Debug      "mo:base/Debug";
import Option     "mo:base/Option";
import Array      "mo:base/Array";
import Iter       "mo:base/Iter";
import Nat        "mo:base/Nat";

module {

  // For convenience: from base module
  type Order           = Order.Order;
  type Iter<T>         = Iter.Iter<T>;
  
  type OrderedSet<K>   = OrderedSet.OrderedSet<K>;
  type Predicate<K>    = OrderedSet.Predicate<K>;
  type WMap<K, V>      = WMap.WMap<K, V>;
  type Map<K, V>       = Map.Map<K, V>;
  
  type Direction       = Types.Direction;
  type ScanLimitResult = Types.ScanLimitResult<Nat>;

  public type Register<OrderBy, Key> = Map<OrderBy, Inner<Key>>;
  
  type Inner<Key> = {
    key_map: Map<Nat, Key>;
    var ordered_set: OrderedSet<Key>;
  };

  public func initRegister<OrderBy, Key>(hash: Map.HashUtils<OrderBy>) : Register<OrderBy, Key> {
    Map.new<OrderBy, Inner<Key>>(hash);
  };

  public func addOrderBy<OrderBy, Key>(register: Register<OrderBy, Key>, hash: Map.HashUtils<OrderBy>, order_by: OrderBy) {
    if(Option.isNull(Map.get(register, hash, order_by))){
      Map.set(register, hash, order_by, { key_map = Map.new<Nat, Key>(Map.nhash); var ordered_set = OrderedSet.init<Key>(); });
    };
  };

  public func build<OrderBy, Key>(
    register: Register<OrderBy, Key>,
    hash: Map.HashUtils<OrderBy>,
    compare_keys: (Key, Key) -> Order,
    to_order_by : (Key) -> OrderBy,
    get_identifier: (Key) -> Nat
  ) : Queries<OrderBy, Key> {
    Queries(WMap.WMap(register, hash), compare_keys, to_order_by, get_identifier);
  };

  type WRegister<OrderBy, Key> = WMap<OrderBy, Inner<Key>>;

  public class Queries<OrderBy, Key>(
    _register: WRegister<OrderBy, Key>, 
    _compare_keys: (Key, Key) -> Order,
    _to_order_by : (Key) -> OrderBy,
    _get_identifier: (Key) -> Nat
  ) {

    public func add(key: Key) {
      Option.iterate(_register.getOpt(_to_order_by(key)), func(inner: Inner<Key>){
        let id = _get_identifier(key);
        if (Map.has(inner.key_map, Map.nhash, id)) {
          Debug.trap("Cannot add new element with id '" # Nat.toText(id) # "' because it already exists for this order_by");
        };
        Map.set(inner.key_map, Map.nhash, id, key);
        inner.ordered_set := OrderedSet.put(inner.ordered_set, _compare_keys, key);
      });
    };

    public func remove(key: Key) {
      Option.iterate(_register.getOpt(_to_order_by(key)), func(inner: Inner<Key>){
        let id = _get_identifier(key);
        if (not Map.has(inner.key_map, Map.nhash, id)) {
          Debug.trap("Cannot remove element with id '" # Nat.toText(id) # "' because it does not exist for this order_by");
        };
        let (removed, set) = OrderedSet.remove(inner.ordered_set, _compare_keys, key);
        if(Option.isNull(removed)){
          Debug.trap("Key not found");
        };
        Map.delete(inner.key_map, Map.nhash, id);
        inner.ordered_set := set;
      });
    };

    public func removeAll(id: Nat) {
      for ((order_by, order_register) in _register.entries()){
        switch(Map.get(order_register.key_map, Map.nhash, id)){
          case(null){};
          case(?key){ remove(key); };
        };
      };
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
      limit: Nat,
      filter: ?Predicate<Key>
    ) : ScanLimitResult {
      switch(_register.getOpt(order_by)){
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
                  let scan = OrderedSet.scanLimit(inner.ordered_set, _compare_keys, lower, upper, direction, limit, filter);
                  {
                    keys = Array.map(scan.keys, func(key: Key) : Nat { _get_identifier(key); });
                    next = Option.map(scan.next, func(key: Key) : Nat { _get_identifier(key); });
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
      previous: ?Nat,
      filter: ?Predicate<Key>
    ) : ScanLimitResult {
      switch(direction){
        case(#FWD){ scan(order_by, previous, null, direction, limit, filter); };
        case(#BWD){ scan(order_by, null, previous, direction, limit, filter); };
      };
    };

    public func iter(order_by: OrderBy, direction: Direction) : Iter<Nat> {
      switch(_register.getOpt(order_by)){
        case(null){ Debug.trap("Cannot find rbt for this order_by"); };
        case(?inner){ 
          Iter.map(OrderedSet.iter(inner.ordered_set, direction), func(key: Key) : Nat { _get_identifier(key); });
        };
      };
    };

    func unwrapKey(id: Nat, order_by: OrderBy) : Key {
      switch(_register.getOpt(order_by)){
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