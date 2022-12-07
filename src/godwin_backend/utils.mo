import Types "types";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Set<K> = TrieSet.Set<K>;
  type Time = Time.Time;
  // For convenience: from types module
  type Duration = Types.Duration;
  
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
    buffer.toArray();
  };

  public func toTime(duration: Duration) : Time {
    switch(duration) {
      case(#DAYS(days)){ days * 24 * 60 * 60 * 1_000_000_000; };
      case(#HOURS(hours)){ hours * 60 * 60 * 1_000_000_000; };
      case(#MINUTES(minutes)){ minutes * 60 * 1_000_000_000; };
      case(#SECONDS(seconds)){ seconds * 1_000_000_000; };
      case(#NS(ns)){ ns; };
    };
  };

  public func append<T>(left: [T], right: [T]) : [T] {
    let buffer = Buffer.Buffer<T>(left.size());
    for(val in left.vals()){
      buffer.add(val);
    };
    for(val in right.vals()){
      buffer.add(val);
    };
    return buffer.toArray();
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

};