import Utils "../utils";

import Map "mo:map/Map";

import Iter "mo:base/Iter";

module {

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;
  type HashUtils<K> = Map.HashUtils<K>;

  public class WMap<K, V>(map_: Map<K, V>, hash_: HashUtils<K>) {

    public func get(key: K): ?V {
      Map.get(map_, hash_, key);
    };
      
    public func has(key: K): Bool {
      Map.has(map_, hash_, key);
    };
      
    public func put(key: K, value: V): ?V {
      Map.put(map_, hash_, key, value);
    };
      
    public func set(key: K, value: V) {
      Map.set(map_, hash_, key, value);
    };
      
    public func remove(key: K): ?V {
      Map.remove(map_, hash_, key);
    };
      
    public func delete(key: K) {
      Map.delete(map_, hash_, key);
    };
      
    public func filter(fn: (key: K, value: V) -> Bool): Map<K, V> {
      Map.filter(map_, fn);
    };
      
    public func keys(): Iter.Iter<K> {
      Map.keys(map_);
    };
      
    public func vals(): Iter.Iter<V> {
      Map.vals(map_);
    };
      
    public func entries(): Iter.Iter<(K, V)> {
      Map.entries(map_);
    };
      
    public func forEach(fn: (key: K, value: V) -> ()) {
      Map.forEach(map_, fn);
    };
      
    public func some(fn: (key: K, value: V) -> Bool): Bool {
      Map.some(map_, fn);
    };
      
    public func every(fn: (key: K, value: V) -> Bool): Bool {
      Map.every(map_, fn);
    };
      
    public func find(fn: (key: K, value: V) -> Bool): ?(K, V) {
      Map.find(map_, fn);
    };
      
    public func findLast(fn: (key: K, value: V) -> Bool): ?(K, V) {
      Map.findLast(map_, fn);
    };
      
    public func clear() {
      Map.clear(map_);
    };
      
    public func size(): Nat {
      Map.size(map_);
    };

  };

  public class WMap2D<K1, K2, V>(map_: Map<K1, Map<K2, V>>, hash1_: HashUtils<K1>, hash2_: HashUtils<K2>) {
    
    public func get(key1: K1, key2: K2): ?V {
      Utils.get2D(map_, hash1_, key1, hash2_, key2);
    };
      
    public func put(key1: K1, key2: K2, value: V): ?V {
      Utils.put2D(map_, hash1_, key1, hash2_, key2, value);
    };
      
    public func remove(key1: K1, key2: K2): ?V {
      Utils.remove2D(map_, hash1_, key1, hash2_, key2);
    };

    public func entries(): Iter.Iter<(K1, Iter.Iter<(K2, V)>)> {
      Utils.entries2D(map_);
    };

  };

  public class WMap3D<K1, K2, K3, V>(map_: Map<K1, Map<K2, Map<K3, V>>>, hash1_: HashUtils<K1>, hash2_: HashUtils<K2>, hash3_: HashUtils<K3>) {
    
    public func get(key1: K1, key2: K2, key3: K3): ?V {
      Utils.get3D(map_, hash1_, key1, hash2_, key2, hash3_, key3);
    };
      
    public func put(key1: K1, key2: K2, key3: K3, value: V): ?V {
      Utils.put3D(map_, hash1_, key1, hash2_, key2, hash3_, key3, value);
    };
      
    public func remove(key1: K1, key2: K2, key3: K3): ?V {
      Utils.remove3D(map_, hash1_, key1, hash2_, key2, hash3_, key3);
    };

  };

};