import Types "types";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";

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

};