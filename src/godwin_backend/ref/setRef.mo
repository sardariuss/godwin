import WrappedRef "wrappedRef";

import TrieSet "mo:base/TrieSet";
import Trie    "mo:base/Trie";
import Option  "mo:base/Option";
import Array   "mo:base/Array";

module {

  // For convenience: from base module
  type Set<K>  = TrieSet.Set<K>;
  type Key<K>  = Trie.Key<K>;
  type Iter<T> = { next : () -> ?T };

  type WrappedRef<T> = WrappedRef.WrappedRef<T>;

  public class SetRef<K>(
    set_: WrappedRef<Set<K>>,
    key_gen: (K) -> Key<K>,
    key_eq: (K, K) -> Bool
  ) {

    public func share() : Set<K> {
      set_.ref;
    };

    public func put(k: K) {
      let key = key_gen(k);
      set_.ref := TrieSet.put(set_.ref, key.key, key.hash, key_eq);
    };

    public func contains(k: K) : Bool {
      Option.isSome(Trie.get(set_.ref, key_gen(k), key_eq));
    };

    public func remove(k: K){
      let key = key_gen(k);
      set_.ref := TrieSet.delete(set_.ref, key.key, key.hash, key_eq);
    };

    public func iter() : Iter<K> {
      Array.vals(TrieSet.toArray(set_.ref));
    };

    public func size() : Nat {
      TrieSet.size(set_.ref);
    };

  };
};