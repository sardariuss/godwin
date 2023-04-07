import WMap "../../utils/wrappers/WMap";
import WRef "../../utils/wrappers/WRef";
import Ref "../../utils/Ref";

import Map "mo:map/Map";

import Deque "mo:base/Deque";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

module {

  type Deque<T> = Deque.Deque<T>;
  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;
  type WMap<K, V> = WMap.WMap<K, V>;
  type Map<K, V> = Map.Map<K, V>;

  type Failed<Args, Err> = {
    args : Args;
    time : Nat64;
    error : Err;
  };

  public class AsyncFifo<Args, Err>(
    _method: (Args, WRef<?Err>) -> async(),
    _trap_error: Err,
    _pending: WRef<Deque<Args>>,
    _failed: WMap<Nat, Failed<Args, Err>>,
    _index: WRef<Nat>
  ){

    public func pushBack(args: Args) {
      _pending.set(Deque.pushBack(_pending.get(), args));
    };

    public func popFront() : async() {
      
      // Remove the first element from the queue
      let (args, deque) = switch(Deque.popFront(_pending.get())){
        case(null) { return; }; // Nothing to do
        case(?(elem, deque)) { (elem, deque) };
      };
      _pending.set(deque);

      let time = Nat64.fromNat(Int.abs(Time.now()));

      // Add it preemptively to the failed in case the method traps
      let index = _index.get();
      _failed.set(index, { args; time; error = _trap_error; });
      _index.set(index + 1);

      // Call the method
      let err = WRef.WRef<?Err>({ var v = null; });
      await _method(args, err);
      switch(err.get()){
        case(null) {
          // Remove it from the failed payouts
          _failed.delete(index);
        };
        case(?error) {
          // Update the error
          _failed.set(index, { args; time; error; });
        };
      };
    };

    public func getFailed() : [(Nat, Failed<Args, Err>)] {
      Iter.toArray(_failed.entries());
    };
  };
  
};

