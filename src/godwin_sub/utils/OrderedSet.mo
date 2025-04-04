import Types  "Types";

import RBT    "mo:stableRBT/StableRBTree";

import Order  "mo:base/Order";
import Option "mo:base/Option";
import Iter   "mo:base/Iter";
import Debug  "mo:base/Debug";
import Array  "mo:base/Array";

module {

  type Order              = Order.Order;
  type Iter<T>            = Iter.Iter<T>;

  type Direction          = Types.Direction;
  type ScanLimitResult<K> = Types.ScanLimitResult<K>;

  public type Predicate<K>  = (K) -> Bool;
  public type OrderedSet<K> = RBT.Tree<K, ()>;

  public func init<K>() : OrderedSet<K> {
    RBT.init<K, ()>();
  };

  public func has<K>(set: OrderedSet<K>, compare: (K, K) -> Order.Order, k : K) : Bool {
    Option.isSome(RBT.get(set, compare, k));
  };

  public func replace<K>(set: OrderedSet<K>, compare: (K, K) -> Order.Order, k : K) : OrderedSet<K> {
    let (old, new_set) = RBT.replace<K, ()>(set, compare, k, ());
    switch(old){
      case(null) { Debug.trap("Cannot replace a key that does not exist"); };
      case(_) { new_set; };
    };
  };

  public func put<K>(set: OrderedSet<K>, compare: (K, K) -> Order.Order, k : K) : OrderedSet<K> {
    RBT.put(set, compare, k, ());
  };

  public func delete<K>(set: OrderedSet<K>, compare: (K, K) -> Order.Order, k : K) : OrderedSet<K>{
    RBT.delete(set, compare, k);
  };

  public func remove<K>(set: OrderedSet<K>, compare: (K, K) -> Order.Order, k : K) : (?K, OrderedSet<K>){
    switch(RBT.get(set, compare, k)){
      case(null) { (null, set); };
      case(_){
        let rbt = RBT.delete(set, compare, k);
        assert(not has(rbt, compare, k));
        (?k, rbt);
      };
    };
  };

  public func keys<K>(set: OrderedSet<K>) : Iter<K> {
    Iter.map<(K, ()), K>(RBT.entries(set), func(entry: (K, ())) : K { entry.0; });
  };

  public func keysRev<K>(set: OrderedSet<K>) : Iter<K> {
    Iter.map<(K, ()), K>(RBT.entriesRev(set), func(entry: (K, ())) : K { entry.0; });
  };

  public func iter<K>(set: OrderedSet<K>, dir : Direction)  : Iter<K> {
    Iter.map<(K, ()), K>(RBT.iter(set, toRBTDirection(dir)), func(entry: (K, ())) : K { entry.0; });
  };

  public func scanLimit<K>(
    set: OrderedSet<K>,
    compare: (K, K) -> Order.Order,
    lower_bound: K,
    upper_bound: K,
    dir: Direction,
    limit: Nat,
    filter: ?Predicate<K>
  ) : ScanLimitResult<K> {
    let scan = switch(filter){
      case(?f) { RBT.scanLimitWithFilter(set, compare, lower_bound, upper_bound, toRBTDirection(dir), limit, func(k: K, v: ()) : Bool { f(k); }); };
      case(null) { RBT.scanLimit(set, compare, lower_bound, upper_bound, toRBTDirection(dir), limit); };
    };
    {
      keys = Array.map<(K, ()), K>(scan.results, func (entry: (K, ())) : K { entry.0; });
      next = scan.nextKey;
    };
  };

  public func size<K>(set: OrderedSet<K>) : Nat {
    RBT.size(set);
  };

  func toRBTDirection(dir: Direction) : RBT.Direction {
    switch(dir){ case(#FWD) { #fwd; }; case(#BWD) { #bwd }; };
  };

};