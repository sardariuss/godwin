import Set "mo:map/Set";

import Iter "mo:base/Iter";

module {

  // For convenience: from map module
  type Set<K> = Set.Set<K>;
  type HashUtils<K> = Set.HashUtils<K>;

  public class WSet<K>(map_: Set<K>, hash_: HashUtils<K>) {

    public func has(key: K): Bool {
      Set.has(map_, hash_, key);
    };
      
    public func put(key: K): Bool {
      Set.put(map_, hash_, key);
    };

    public func add(key: K) {
      Set.add(map_, hash_, key);
    };
      
    public func remove(key: K): Bool {
      Set.remove(map_, hash_, key);
    };
      
    public func delete(key: K) {
      Set.delete(map_, hash_, key);
    };
      
    public func filter(fn: (key: K) -> Bool): Set<K> {
      Set.filter(map_, hash_, fn);
    };
      
    public func keys(): Iter.Iter<K> {
      Set.keys(map_);
    };
      
    public func forEach(fn: (key: K) -> ()) {
      Set.forEach(map_, fn);
    };
      
    public func some(fn: (key: K) -> Bool): Bool {
      Set.some(map_, fn);
    };
      
    public func every(fn: (key: K) -> Bool): Bool {
      Set.every(map_, fn);
    };
      
    public func find(fn: (key: K) -> Bool): ?K {
      Set.find(map_, fn);
    };
      
    public func findDesc(fn: (key: K) -> Bool): ?K {
      Set.findDesc(map_, fn);
    };
      
    public func clear() {
      Set.clear(map_);
    };
      
    public func size(): Nat {
      Set.size(map_);
    };

  };

};