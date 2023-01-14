import WrappedRef "wrappedRef";

import Trie "mo:base/Trie";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V>            = Trie.Trie<K, V>;
  type Trie2D<K1, K2, V>     = Trie.Trie2D<K1, K2, V>;
  type Trie3D<K1, K2, K3, V> = Trie.Trie3D<K1, K2, K3, V>;
  type Key<K>                = Trie.Key<K>;

  type WrappedRef<T> = WrappedRef.WrappedRef<T>;

  public class TrieRef<K, V>(
    trie_: WrappedRef<Trie<K, V>>,
    key_gen: (K) -> Key<K>,
    key_eq: (K, K) -> Bool
  ) {

    public func put(k: K, v: V) : ?V {
      let (trie, old_v) = Trie.put(trie_.ref, key_gen(k), key_eq, v);
      trie_.ref        := trie;
      old_v;
    };

    public func get(k: K) : ?V {
      Trie.get(trie_.ref, key_gen(k), key_eq);
    };

    public func remove(k: K) : ?V {
      let (trie, old_v) = Trie.remove(trie_.ref, key_gen(k), key_eq);
      trie_.ref        := trie;
      old_v;
    };

  };

  public class Trie2DRef<K1, K2, V>(
    trie_: WrappedRef<Trie2D<K1, K2, V>>, 
    key_gen_1: (K1) -> Key<K1>,
    key_eq_1: (K1, K1) -> Bool,
    key_gen_2: (K2) -> Key<K2>,
    key_eq_2: (K2, K2) -> Bool
  ) {

    public func put(k1: K1, k2: K2, v: V) : ?V {
      let trie_2            = Option.get(Trie.get(trie_.ref, key_gen_1(k1), key_eq_1), Trie.empty<K2, V>());
      let (update_2, old_v) = Trie.put(trie_2,    key_gen_2(k2), key_eq_2, v);
      trie_.ref            := Trie.put(trie_.ref, key_gen_1(k1), key_eq_1, update_2).0;
      old_v;
    };

    public func get(k1: K1, k2: K2) : ?V {
      Option.chain(Trie.get(trie_.ref, key_gen_1(k1), key_eq_1), func(trie_2: Trie<K2, V>) : ?V {
        Trie.get(trie_2, key_gen_2(k2), key_eq_2);
      });
    };

    // @todo: optimization: remove emptied sub trie if any
    public func remove(k1: K1, k2: K2) : ?V {
      Option.chain(Trie.get(trie_.ref, key_gen_1(k1), key_eq_1), func(trie_2: Trie<K2, V>) : ?V {
        let (update_2, old_v) = Trie.remove(trie_2, key_gen_2(k2), key_eq_2);
        trie_.ref            := Trie.put(trie_.ref, key_gen_1(k1), key_eq_1, update_2).0;
        old_v;
      });
    };
  };

  public class Trie3DRef<K1, K2, K3, V>(
    trie_    : WrappedRef<Trie3D<K1, K2, K3, V>>, 
    key_gen_1: (K1)     -> Key<K1>,
    key_eq_1 : (K1, K1) -> Bool,
    key_gen_2: (K2)     -> Key<K2>,
    key_eq_2 : (K2, K2) -> Bool,
    key_gen_3: (K3)     -> Key<K3>,
    key_eq_3 : (K3, K3) -> Bool
  ) {

    public func put(k1: K1, k2: K2, k3: K3, v: V) : ?V {
      let trie_2            = Option.get(Trie.get(trie_.ref, key_gen_1(k1), key_eq_1), Trie.empty<K2, Trie<K3, V>>());
      let trie_3            = Option.get(Trie.get(trie_2   , key_gen_2(k2), key_eq_2), Trie.empty<K3, V>());
      let (update_3, old_v) = Trie.put(trie_3,    key_gen_3(k3), key_eq_3, v);
      let (update_2, _)     = Trie.put(trie_2,    key_gen_2(k2), key_eq_2, update_3);
      trie_.ref            := Trie.put(trie_.ref, key_gen_1(k1), key_eq_1, update_2).0;
      old_v;
    };

    public func get(k1: K1, k2: K2, k3: K3) : ?V {
      Option.chain(Trie.get(trie_.ref, key_gen_1(k1), key_eq_1), func(trie_2: Trie<K2, Trie<K3, V>>) : ?V {
        Option.chain(Trie.get(trie_2, key_gen_2(k2), key_eq_2), func(trie_3: Trie<K3, V>) : ?V {
          Trie.get(trie_3, key_gen_3(k3), key_eq_3);
        })
      });
    };

    // @todo: optimization: remove emptied sub trie if any
    public func remove(k1: K1, k2: K2, k3: K3) : ?V {
      Option.chain(Trie.get(trie_.ref, key_gen_1(k1), key_eq_1), func(trie_2: Trie<K2, Trie<K3, V>>) : ?V {
        Option.chain(Trie.get(trie_2, key_gen_2(k2), key_eq_2), func(trie_3: Trie<K3, V>) : ?V {
          let (update_3, old_v) = Trie.remove(trie_3, key_gen_3(k3), key_eq_3);
          let (update_2, _)     = Trie.put(trie_2,    key_gen_2(k2), key_eq_2, update_3);
          trie_.ref            := Trie.put(trie_.ref, key_gen_1(k1), key_eq_1, update_2).0;
          old_v;
        })
      });
    };

  };
  
};