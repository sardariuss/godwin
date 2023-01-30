import Map "mo:map/Map";

import Array "mo:base/Array";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Buffer<T> = Buffer.Buffer<T>;
  type Set<K> = TrieSet.Set<K>;
  type Time = Time.Time;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Iter<T> = { next : () -> ?T };

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;
  type HashUtils<K> = Map.HashUtils<K>;

  /// Creates a buffer from an array
  public func toBuffer<T>(x :[T]) : Buffer<T>{
    let buffer = Buffer.Buffer<T>(x.size());
    for(thisItem in x.vals()){
      buffer.add(thisItem);
    };
    return buffer;
  };
  
  public func arrayToTrie<K, V>(array: [(K, V)], key: (K) -> Key<K>, equal: (K, K) -> Bool) : Trie<K, V> {
    var trie = Trie.empty<K, V>();
    for ((k, v) in Array.vals(array)){
      trie := Trie.put(trie, key(k), equal, v).0;
    };
    trie;
  };

  public func trieToArray<K, V>(trie: Trie<K, V>) : [(K, V)] {
    let buffer = Buffer.Buffer<(K, V)>(Trie.size(trie));
    for (key_val in Trie.iter(trie)) {
      buffer.add(key_val);
    };
    Buffer.toArray(buffer);
  };

  public func keys<K, V>(trie: Trie<K, V>, key: (K) -> Key<K>, equal: (K, K) -> Bool) : Set<K> {
    var set = TrieSet.empty<K>();
    for ((k, _) in Trie.iter(trie)){
      set := Trie.put(set, key(k), equal, ()).0;
    };
    set;
  };

  public func append<T>(left: [T], right: [T]) : [T] {
    let buffer = Buffer.Buffer<T>(left.size());
    for(val in left.vals()){
      buffer.add(val);
    };
    for(val in right.vals()){
      buffer.add(val);
    };
    return Buffer.toArray(buffer);
  };

  public func leftJoin<K, V, W, X>(tl : Trie<K, V>, tr : Trie<K, W>, k_compute : (K) -> Key<K>, k_eq : (K, K) -> Bool, vbin : (V, ?W) -> X) : Trie<K, X> {
    var join = Trie.empty<K, X>();
    for ((k, v) in Trie.iter(tl)){
      let key = k_compute(k);
      join := Trie.put(join, key, k_eq, vbin(v, Trie.get(tr, key, k_eq))).0;
    };
    join;
  };

  public func make<K, V>(keys: [K], k_compute : (K) -> Key<K>, k_eq : (K, K) -> Bool, init_val: V) : Trie<K, V> {
    var trie = Trie.empty<K, V>();
    for (k in Array.vals(keys)) {
      trie := Trie.put(trie, k_compute(k), k_eq, init_val).0;
    };
    trie;
  };

  public func setIter<K>(set: Set<K>) : Iter<K> {
    Array.vals(TrieSet.toArray(set));
  };

  public func toResult<Err>(bool: Bool, err: Err) : Result<(), Err> {
    if (bool) { #ok(); }
    else      { #err(err); };
  };

  public func mapToArray<K, V>(map: Map<K, V>) : [(K, V)]{
    Iter.toArray(Map.entries(map));
  };

  public func arrayToMap<K, V>(array: [(K, V)], hash: HashUtils<K>) : Map<K, V>{
    Map.fromIter(Array.vals(array), hash);
  };

  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;

  public func put2D<K1, K2, V>(map2D: Map2D<K1, K2, V>, k1_hash: HashUtils<K1>, k1: K1, k2_hash: HashUtils<K2>, k2: K2, v: V) : ?V {
    let map1D = Option.get(Map.get(map2D, k1_hash, k1), Map.new<K2, V>());
    let old_v = Map.put(map1D, k2_hash, k2, v);
    ignore Map.put(map2D, k1_hash, k1, map1D); // @todo: might be required only if the inner map is new
    old_v;
  };

  public func get2D<K1, K2, V>(map2D: Map2D<K1, K2, V>, k1_hash: HashUtils<K1>, k1: K1, k2_hash: HashUtils<K2>, k2: K2) : ?V {
    Option.chain(Map.get(map2D, k1_hash, k1), func(map1D: Map<K2, V>) : ?V {
      Map.get(map1D, k2_hash, k2);
    });
  };

  // @todo: optimization: remove emptied sub trie if any
  public func remove2D<K1, K2, V>(map2D: Map2D<K1, K2, V>, k1_hash: HashUtils<K1>, k1: K1, k2_hash: HashUtils<K2>, k2: K2) : ?V {
    Option.chain(Map.get(map2D, k1_hash, k1), func(map1D: Map<K2, V>) : ?V {
      let old_v = Map.remove(map1D, k2_hash, k2);
      ignore Map.put(map2D, k1_hash, k1, map1D); // @todo: might not be required
      old_v;
    });
  };

  public func entries2D<K1, K2, V>(map2D: Map2D<K1, K2, V>) : Iter.Iter<(K1, Iter.Iter<(K2, V)>)> {
    Iter.map<(K1, Map<K2, V>), (K1, Iter.Iter<(K2, V)>)>(Map.entries(map2D), func((k1, map1D): (K1, Map<K2, V>)) : (K1, Iter.Iter<(K2, V)>) {
      (k1, Map.entries(map1D));
    });
  };

  type Map3D<K1, K2, K3, V> = Map<K1, Map<K2, Map<K3, V>>>;

  public func put3D<K1, K2, K3, V>(map3D: Map3D<K1, K2, K3, V>, k1_hash: HashUtils<K1>, k1: K1, k2_hash: HashUtils<K2>, k2: K2, k3_hash: HashUtils<K3>, k3: K3, v: V) : ?V {
    let map2D = Option.get(Map.get(map3D, k1_hash, k1), Map.new<K2, Map<K3, V>>());
    let map1D = Option.get(Map.get(map2D, k2_hash, k2), Map.new<K3, V>());
    let old_v = Map.put(map1D, k3_hash, k3, v);
    ignore Map.put(map2D, k2_hash, k2, map1D); // @todo: might be required only if the inner map is new
    ignore Map.put(map3D, k1_hash, k1, map2D); // @todo: might be required only if the inner map is new
    old_v;
  };

  public func get3D<K1, K2, K3, V>(map3D: Map3D<K1, K2, K3, V>, k1_hash: HashUtils<K1>, k1: K1, k2_hash: HashUtils<K2>, k2: K2, k3_hash: HashUtils<K3>, k3: K3) : ?V {
    Option.chain(Map.get(map3D, k1_hash, k1), func(map2D: Map<K2, Map<K3, V>>) : ?V {
      Option.chain(Map.get(map2D, k2_hash, k2), func(map1D: Map<K3, V>) : ?V {
        Map.get(map1D, k3_hash, k3);
      })
    });
  };

  // @todo: optimization: remove emptied sub trie if any
  public func remove3D<K1, K2, K3, V>(map3D: Map3D<K1, K2, K3, V>, k1_hash: HashUtils<K1>, k1: K1, k2_hash: HashUtils<K2>, k2: K2, k3_hash: HashUtils<K3>, k3: K3) : ?V {
    Option.chain(Map.get(map3D, k1_hash, k1), func(map2D: Map<K2, Map<K3, V>>) : ?V {
      Option.chain(Map.get(map2D, k2_hash, k2), func(map1D: Map<K3, V>) : ?V {
        let old_v = Map.remove(map1D, k3_hash, k3);
        ignore Map.put(map2D, k2_hash, k2, map1D); // @todo: might not be required
        ignore Map.put(map3D, k1_hash, k1, map2D); // @todo: might not be required
        old_v;
      })
    });
  };

  public func equalOpt<T>(opt_a: ?T, opt_b: ?T, equal: (T, T) -> Bool) : Bool {
    switch(opt_a){
      case(null) {
        switch(opt_b){
          case(null) { true; };
          case(_) { false; };
        };
      };
      case(?a) {
        switch(opt_b){
          case(null) { false; };
          case(?b) { equal(a, b); };
        };
      };
    };
  };

  public func nullIter<T>() : Iter<T> {
    { next = func () : ?T { null; }; };
  };

};