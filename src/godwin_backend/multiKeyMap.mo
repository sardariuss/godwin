import RBT "mo:stableRBT/StableRBTree";

import TrieSet "mo:base/TrieSet";
import Order "mo:base/Order";
import Hash "mo:base/Hash";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Set<K> = TrieSet.Set<K>;
  type Order = Order.Order;
  type Hash = Hash.Hash;

  public type MultiKeyMap<K1, K2> = RBT.Tree<K1, Set<K2>>;

  // Init the map
  public func init<K1, K2>() : MultiKeyMap<K1, K2> {
    RBT.init<K1, Set<K2>>();
  };

  // Add the pair of keys in the map
  public func put<K1, K2>(
    map: MultiKeyMap<K1, K2>,
    compare_1: (K1, K1) -> Order,
    key_1: K1,
    hash_2: (K2) -> Hash,
    equal_2: (K2, K2) -> Bool,
    key_2: K2
  ) : MultiKeyMap<K1, K2> {
    var keys_2 = Option.get(RBT.get(map, compare_1, key_1), TrieSet.empty<K2>());
    keys_2 := TrieSet.put(keys_2, key_2, hash_2(key_2), equal_2);
    RBT.put(map, compare_1, key_1, keys_2);
  };

  // Remove the pair of keys from the map
  public func remove<K1, K2>(
    map: MultiKeyMap<K1, K2>,
    compare_1: (K1, K1) -> Order,
    key_1: K1,
    hash_2: (K2) -> Hash,
    equal_2: (K2, K2) -> Bool,
    key_2: K2
  ) : MultiKeyMap<K1, K2> {
    switch(RBT.get(map, compare_1, key_1)){
      case(null) { map; };
      case(?input_keys_2){
        let keys_2 = TrieSet.delete(input_keys_2, key_2, hash_2(key_2), equal_2);
        if (TrieSet.size(keys_2) == 0) {
          // Totally remove the set from the RBT if it is empty
          RBT.delete(map, compare_1, key_1);
        } else {
          // Just update the set in the RBT if not empty
          RBT.put(map, compare_1, key_1, keys_2);
        };
      };
    };
  };

  // Replace the pair of old keys with the new keys in the map
  public func replace<K1, K2>(
    map: MultiKeyMap<K1, K2>,
    compare_1: (K1, K1) -> Order,
    old_key_1: K1,
    new_key_1: K1,
    hash_2: (K2) -> Hash,
    equal_2: (K2, K2) -> Bool,
    key_2: K2
  ) : MultiKeyMap<K1, K2> {
    var new_map = map;
    new_map := remove(new_map, compare_1, old_key_1, hash_2, equal_2, key_2);
    new_map := put(new_map, compare_1, new_key_1, hash_2, equal_2, key_2);
    new_map;
  };

};