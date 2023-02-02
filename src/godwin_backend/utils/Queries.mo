import WMap "wrappers/WMap";
import OrderedSet "OrderedSet";

import Map "mo:map/Map";

import Order "mo:base/Order";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Order = Order.Order;
  type Iter<T> = Iter.Iter<T>;
  type OrderedSet<K> = OrderedSet.OrderedSet<K>;
  
  type WMap<K, V> = WMap.WMap<K, V>;
  type Map<K, V> = Map.Map<K, V>;
  
  public type Direction = OrderedSet.Direction;
  public type QueryResult<Item> = { items: [Item]; next: ?Item };
  public type ScanLimitResult<K> = OrderedSet.ScanLimitResult<K>;

  public func buildQueries<OrderBy, Key, Item>(
    register: Map<OrderBy, OrderedSet<Key>>,
    hash: Map.HashUtils<OrderBy>,
    compare_keys: (Key, Key) -> Order,
    order_by : (Key) -> OrderBy,
    from_key: Key -> Item,
    to_key: (OrderBy, Item) -> Key
  ) : Queries<OrderBy, Key, Item> {
    Queries(buildQueries2(register, hash, compare_keys, order_by), from_key, to_key);
  };

  public class Queries<OrderBy, Key, Item>(
    queries_: Queries2<OrderBy, Key>, 
    from_key_: Key -> Item,
    to_key: (OrderBy, Item) -> Key
  ) {

    public func add(key: Key) {
      queries_.add(key);
    };

    public func remove(key: Key) {
      queries_.remove(key);
    };

    public func replace(old: ?Key, new: ?Key) {
      queries_.replace(old, new);
    };

    func getOptKey(order_by: OrderBy, opt_item: ?Item) : ?Key {
      Option.map(opt_item, func(item: Item) : Key { to_key(order_by, item); });
    };

    public func scanLimit(
      order_by: OrderBy,
      lower_bound: ?Item,
      upper_bound: ?Item,
      direction: Direction,
      limit: Nat
    ) : QueryResult<Item> {
      let scan = queries_.scanLimit(order_by, getOptKey(order_by, lower_bound), getOptKey(order_by, upper_bound), direction, limit);
      {
        items = Array.map(scan.keys, func(key: Key) : Item { from_key_(key); });
        next = Option.map(scan.next, func(key: Key) : Item { from_key_(key); });
      };
    };

    public func queryItems(
      order_by: OrderBy,
      direction: Direction,
      limit: Nat,
      previous: ?Item
    ) : QueryResult<Item> {
      switch(direction){
        case(#FWD){
          scanLimit(order_by, previous, null, direction, limit);
        };
        case(#BWD){
          scanLimit(order_by, null, previous, direction, limit);
        };
      };
    };

    public func entries(order_by: OrderBy, direction: Direction) : Iter<Item> {
      Iter.map(queries_.keys(order_by, direction), func(key: Key) : Item { from_key_(key); });
    };

  };

  public func buildQueries2<OrderBy, Key>(
    register: Map<OrderBy, OrderedSet<Key>>,
    hash: Map.HashUtils<OrderBy>,
    compare_keys: (Key, Key) -> Order,
    order_by : (Key) -> OrderBy
  ) : Queries2<OrderBy, Key> {
    Queries2(WMap.WMap(register, hash), compare_keys, order_by);
  };

  public class Queries2<OrderBy, Key>(
    register_: WMap<OrderBy, OrderedSet<Key>>, 
    compare_keys_: (Key, Key) -> Order,
    to_order_by_ : (Key) -> OrderBy
  ) {

    public func add(key: Key) {
      let order_by = to_order_by_(key);
      // @todo: or trap if no set for this order by ?
      Option.iterate(register_.get(order_by), func(ordered_set: OrderedSet<Key>){
        register_.set(order_by, OrderedSet.put(ordered_set, compare_keys_, key));
      });
    };

    public func remove(key: Key) {
      let order_by = to_order_by_(key);
      // @todo: or trap if no set for this order by ?
      Option.iterate(register_.get(order_by), func(ordered_set: OrderedSet<Key>){
        register_.set(order_by, OrderedSet.delete(ordered_set, compare_keys_, key));
      });
    };

    public func replace(old: ?Key, new: ?Key) {
      Option.iterate(old, func(key: Key) { remove(key); });
      Option.iterate(new, func(key: Key) { add(key);    });
    };

    public func scanLimit(
      order_by: OrderBy,
      lower_bound: ?Key,
      upper_bound: ?Key,
      direction: Direction,
      limit: Nat
    ) : ScanLimitResult<Key> {
      switch(register_.get(order_by)){
        case(null){ Debug.trap("Cannot find ordered_set for this order_by"); };
        case(?ordered_set){
          switch(OrderedSet.keys(ordered_set).next()){
            case(null){ { keys = []; next = null; } };
            case(?first){
              switch(OrderedSet.keysRev(ordered_set).next()){
                case(null){ { keys = []; next = null; } };
                case(?last){
                  OrderedSet.scanLimit(ordered_set, compare_keys_, Option.get(lower_bound, first), Option.get(upper_bound, last), direction, limit);
                };
              };
            };
          };
        };
      };
    };

    public func queryKeys(
      order_by: OrderBy,
      direction: Direction,
      limit: Nat,
      previous: ?Key
    ) : ScanLimitResult<Key> {
      switch(direction){
        case(#FWD){
          scanLimit(order_by, previous, null, direction, limit);
        };
        case(#BWD){
          scanLimit(order_by, null, previous, direction, limit);
        };
      };
    };

    public func keys(order_by: OrderBy, direction: Direction) : Iter<Key> {
      switch(register_.get(order_by)){
        case(null){ Debug.trap("Cannot find rbt for this order_by"); };
        case(?ordered_set){ 
          OrderedSet.iter(ordered_set, direction);
        };
      };
    };

  };

  public func buildQueries3<Key>(register: OrderedSet<Key>, compare_keys: (Key, Key) -> Order) : Queries3<Key>{
    Queries3(register, compare_keys);
  };

  public class Queries3<Key>(
    register_: OrderedSet<Key>, 
    compare_keys_: (Key, Key) -> Order
  ) {

    public func add(key: Key) {
      ignore OrderedSet.put(register_, compare_keys_, key);
    };

    public func remove(key: Key) {
      ignore OrderedSet.delete(register_, compare_keys_, key);
    };

    public func replace(old: ?Key, new: ?Key) {
      Option.iterate(old, func(key: Key) { remove(key); });
      Option.iterate(new, func(key: Key) { add(key);    });
    };

    public func scanLimit(
      lower_bound: ?Key,
      upper_bound: ?Key,
      direction: Direction,
      limit: Nat
    ) : ScanLimitResult<Key> {
      switch(OrderedSet.keys(register_).next()){
        case(null){ { keys = []; next = null; } };
        case(?first){
          switch(OrderedSet.keysRev(register_).next()){
            case(null){ { keys = []; next = null; } };
            case(?last){
              OrderedSet.scanLimit(register_, compare_keys_, Option.get(lower_bound, first), Option.get(upper_bound, last), direction, limit);
            };
          };
        };
      };
    };

    public func queryKeys(
      direction: Direction,
      limit: Nat,
      previous: ?Key
    ) : ScanLimitResult<Key> {
      switch(direction){
        case(#FWD){
          scanLimit(previous, null, direction, limit);
        };
        case(#BWD){
          scanLimit(null, previous, direction, limit);
        };
      };
    };

    public func keys(direction: Direction) : Iter<Key> {
      OrderedSet.iter(register_, direction);
    };

  };

};