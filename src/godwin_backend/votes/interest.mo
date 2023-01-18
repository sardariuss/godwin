import Votes "votes"; 
import Interests "interests";
import Types "../types";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal"

module {

  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type Trie2D<K1, K2, V> = Trie.Trie2D<K1, K2, V>;
  type Trie3D<K1, K2, K3, V> = Trie.Trie3D<K1, K2, K3, V>;
  type Votes<B, A> = Votes.Votes<B, A>;
  type Timestamp<T> = Types.Timestamp<T>;

  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type Map3D<K1, K2, K3, V> = Map<K1, Map<K2, Map<K3, V>>>;

  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type WMap3D<K1, K2, K3, V> = WMap.WMap3D<K1, K2, K3, V>;

  public func build(
    ballots : Map3D<Principal, Nat, Nat, Timestamp<Interest>>,
    aggregates : Map2D<Nat, Nat, Timestamp<InterestAggregate>>
  ) : Votes<Interest, InterestAggregate> {
    Votes.Votes(
      WMap.WMap3D<Principal, Nat, Nat, Timestamp<Interest>>(ballots, Map.phash, Map.nhash, Map.nhash),
      WMap.WMap2D<Nat, Nat, Timestamp<InterestAggregate>>(aggregates, Map.nhash, Map.nhash),
      Interests.emptyAggregate(),
      Interests.addToAggregate,
      Interests.removeFromAggregate
    );
  };

};