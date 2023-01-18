import Votes "votes"; 
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";
import Types "../types";
import WrappedRef "../ref/wrappedRef";
import TrieRef "../ref/trieRef";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal"

module {

  type Category = Types.Category;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Trie2D<K1, K2, V> = Trie.Trie2D<K1, K2, V>;
  type Trie3D<K1, K2, K3, V> = Trie.Trie3D<K1, K2, K3, V>;
  type Votes<B, A> = Votes.Votes<B, A>;
  type WrappedRef<T> = WrappedRef.WrappedRef<T>;
  type Timestamp<T> = Types.Timestamp<T>;

  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type Map3D<K1, K2, K3, V> = Map<K1, Map<K2, Map<K3, V>>>;

  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type WMap3D<K1, K2, K3, V> = WMap.WMap3D<K1, K2, K3, V>;

  public func build(
    ballots : Map3D<Principal, Nat, Nat, Timestamp<CategoryCursorTrie>>,
    aggregates : Map2D<Nat, Nat, Timestamp<CategoryPolarizationTrie>>,
    categories: [Category]
  ) : Votes<CategoryCursorTrie, CategoryPolarizationTrie> {
    Votes.Votes(
      WMap.WMap3D<Principal, Nat, Nat, Timestamp<CategoryCursorTrie>>(ballots, Map.phash, Map.nhash, Map.nhash),
      WMap.WMap2D<Nat, Nat, Timestamp<CategoryPolarizationTrie>>(aggregates, Map.nhash, Map.nhash),
      CategoryPolarizationTrie.nil(categories),
      CategoryPolarizationTrie.addCategoryCursorTrie,
      CategoryPolarizationTrie.subCategoryCursorTrie
    );
  };

};