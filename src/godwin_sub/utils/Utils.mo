import Types   "Types";

import Map     "mo:map/Map";
import Set     "mo:map/Set";

import Array   "mo:base/Array";
import Trie    "mo:base/Trie";
import Time    "mo:base/Time";
import Buffer  "mo:base/Buffer";
import Option  "mo:base/Option";
import Result  "mo:base/Result";
import Iter    "mo:base/Iter";
import Char    "mo:base/Char";
import Nat32   "mo:base/Nat32";
import Nat8   "mo:base/Nat8";
import Text    "mo:base/Text";
import Blob    "mo:base/Blob";
import Debug   "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V>         = Trie.Trie<K, V>;
  type Key<K>             = Trie.Key<K>;
  type Buffer<T>          = Buffer.Buffer<T>;
  type Set<K>             = Set.Set<K>;
  type Time               = Time.Time;
  type Result<Ok, Err>    = Result.Result<Ok, Err>;
  type Iter<T>            = { next : () -> ?T };
  type ScanLimitResult<K> = Types.ScanLimitResult<K>;
  type Direction          = Types.Direction;

  // For convenience: from map module
  type Map<K, V>       = Map.Map<K, V>;
  type HashUtils<K>    = Map.HashUtils<K>;

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

  public func make<K, V>(keys: Iter<K>, k_compute : (K) -> Key<K>, k_eq : (K, K) -> Bool, init_val: V) : Trie<K, V> {
    var trie = Trie.empty<K, V>();
    for (k in keys) {
      trie := Trie.put(trie, k_compute(k), k_eq, init_val).0;
    };
    trie;
  };

  public func toResult<Err>(bool: Bool, err: Err) : Result<(), Err> {
    if (bool) { #ok(); }
    else      { #err(err); };
  };

  public func unwrapOk<Ok, Err>(result: Result<Ok, Err>) : Ok {
    switch(result){
      case(#ok(ok)) { ok };
      case(#err(err)) { Debug.trap("Failed to unwrap result"); };
    };
  };

  public func setScanLimit<K>(set: Set<K>, hash: HashUtils<K>, dir: Direction, limit: Nat, previous: ?K) : ScanLimitResult<K> {
    let keys = Buffer.Buffer<K>(limit);
    var next : ?K = null;
    let iter = switch(dir){
      case(#FWD) { Set.keysFrom<K>(set, hash, previous); };
      case(#BWD) { Set.keysFromDesc<K>(set, hash, previous);  };
    };
    label keys_desc loop {
      switch(iter.next()){
        case(?k) {
          if (keys.size() < limit)      { keys.add(k);     }
          else if (Option.isNull(next)) { next := ?k;      }
          else                          { break keys_desc; };
        };
        case(null)                      { break keys_desc; };
      };
    };
    { keys = Buffer.toArray(keys); next; };
  };

  public func mapScanLimit<K, V>(map: Map<K, V>, hash: HashUtils<K>, dir: Direction, limit: Nat, previous: ?K) : ScanLimitResult<(K, V)> {
    let entries = Buffer.Buffer<(K, V)>(limit);
    var next : ?(K, V) = null;
    let iter = switch(dir){
      case(#FWD) { Map.entriesFrom<K, V>    (map, hash, previous); };
      case(#BWD) { Map.entriesFromDesc<K, V>(map, hash, previous); };
    };
    label entries_loop loop {
      switch(iter.next()){
        case(?kv) {
          if (entries.size() < limit)   { entries.add(kv);    }
          else if (Option.isNull(next)) { next := ?kv;        }
          else                          { break entries_loop; };
        };
        case(null)                      { break entries_loop; };
      };
    };
    { keys = Buffer.toArray(entries); next; };
  };

  public func mapScanLimitResult<K1, K2>(scan: ScanLimitResult<K1>, f: (K1) -> K2) : ScanLimitResult<K2> {
    let keys = Array.map(scan.keys, f);
    let next = Option.map(scan.next, f);
    { keys = keys; next = next; };
  };

  public func mapToArray<K, V>(map: Map<K, V>) : [(K, V)]{
    Iter.toArray(Map.entries(map));
  };

  public func arrayToMap<K, V>(array: [(K, V)], hash: HashUtils<K>) : Map<K, V>{
    Map.fromIter(Array.vals(array), hash);
  };

  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;

  public func has2D<K1, K2, V>(map2D: Map2D<K1, K2, V>, k1_hash: HashUtils<K1>, k1: K1, k2_hash: HashUtils<K2>, k2: K2) : Bool {
    switch(Map.get(map2D, k1_hash, k1)){
      case(null) { false };
      case(?map1D) { Map.has(map1D, k2_hash, k2) };
    };
  };

  public func put2D<K1, K2, V>(map2D: Map2D<K1, K2, V>, k1_hash: HashUtils<K1>, k1: K1, k2_hash: HashUtils<K2>, k2: K2, v: V) : ?V {
    let map1D = Option.get(Map.get(map2D, k1_hash, k1), Map.new<K2, V>(k2_hash));
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
    let map2D = Option.get(Map.get(map3D, k1_hash, k1), Map.new<K2, Map<K3, V>>(k2_hash));
    let map1D = Option.get(Map.get(map2D, k2_hash, k2), Map.new<K3, V>(k3_hash));
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

  public func textIntersect(text_1: Text, text_2: Text, to_lower: [Nat32]) : Nat {

    let lower_text_1 = Text.map(text_1, func(w: Char) : Char { return Char.fromNat32(to_lower[Nat32.toNat(Char.toNat32(w))]); });
    let lower_text_2 = Text.map(text_2, func(w: Char) : Char { return Char.fromNat32(to_lower[Nat32.toNat(Char.toNat32(w))]); });

    var match_count = 0;
    label find_match for (word in Text.split(lower_text_2, #predicate(Char.isWhitespace))){
      if (word.size() < 3) continue find_match;
      if (Text.contains(lower_text_1, #text(word))){
        match_count += 1;
        break find_match;
      };
    };

    match_count;
  };

  public func iterSome<T>(a: ?T, b: ?T, fn: (a: T, b: T) -> ()){
    switch(a){
      case(null) {};
      case(?a) {
        switch(b){
          case(null) {};
          case(?b) { fn(a, b); };
        };
      };
    };
  };

  public func mapEqual<K, V>(map_a: Map<K, V>, map_b: Map<K, V>, hash: HashUtils<K>, equal: (V, V) -> Bool) : Bool {
    if (Map.size(map_a) != Map.size(map_b)) return false;
    for ((k, v_a) in Map.entries(map_a)){
      switch(Map.get(map_b, hash, k)){
        case(null) { return false; };
        case(?v_b) {
          if (not equal(v_a, v_b)) return false;
        };
      };
    };
    true;
  };

  public func blobToText(blob: Blob) : Text {
    Array.foldLeft(Blob.toArray(blob), "", func(text: Text, byte: Nat8) : Text {
      Text.concat(text, Nat8.toText(byte));
    });
  };

  public func mapFilter2D<K1, K2, V, U>(map: Map<K1, Map<K2, V>>, hash1: HashUtils<K1>, hash2: HashUtils<K2>, mapEntry: (K1, K2, V) -> ?U) : Map<K1, Map<K2, U>> {
    Map.mapFilter(map, hash1, func(k1: K1, inner: Map<K2, V>) : ?Map<K2, U> {
      ?Map.mapFilter(inner, hash2, func(k2: K2, v: V) : ?U {
        mapEntry(k1, k2, v);
      });
    });
  };

};