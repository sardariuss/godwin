import WRef "WRef";
import OrderedSet "../OrderedSet";

import Order "mo:base/Order";
import Iter "mo:base/Iter";

module {

  type Order = Order.Order;
  type Iter<T> = Iter.Iter<T>;

  type WRef<T> = WRef.WRef<T>;
  type Direction = OrderedSet.Direction;
  type OrderedSet<K> = OrderedSet.OrderedSet<K>;
  type ScanLimitResult<K> = OrderedSet.ScanLimitResult<K>;

  public class WOrderedSet<K>(set_: WRef<OrderedSet<K>>, compare_: (K, K) -> Order.Order) {

    public func share() : OrderedSet<K> {
      set_.get();
    };

    public func has(k : K) : Bool {
      OrderedSet.has(set_.get(), compare_, k);
    };

    public func replace(k : K) {
      set_.set(OrderedSet.replace(set_.get(), compare_, k));
    };

    public func put(k : K) {
      set_.set(OrderedSet.put(set_.get(), compare_, k));
    };

    public func delete(k : K) {
      set_.set(OrderedSet.delete(set_.get(), compare_, k));
    };

    public func keys() : Iter<K> {
      OrderedSet.keys(set_.get());
    };

    public func keysRev() : Iter<K> {
      OrderedSet.keysRev(set_.get());
    };

    public func iter(dir : Direction)  : Iter<K> {
      OrderedSet.iter(set_.get(), dir);
    };

    public func scanLimit(lower_bound: K, upper_bound: K, dir: Direction, limit: Nat) : ScanLimitResult<K> {
      OrderedSet.scanLimit(set_.get(), compare_, lower_bound, upper_bound, dir, limit);
    };

    public func size() : Nat {
      OrderedSet.size(set_.get());
    };

  };

};