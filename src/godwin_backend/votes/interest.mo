import Votes "votes"; 
import InterestAggregate "../representation/interestAggregate";
import Types "../types";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

import Order "mo:base/Order";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

module {

  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  
  public type Vote = Types.Vote<Interest, InterestAggregate>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Interests2 = Votes<Interest, InterestAggregate>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register) : Interests2 {

    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      InterestAggregate.emptyAggregate(),
      InterestAggregate.addToAggregate,
      InterestAggregate.removeFromAggregate
    );
  };

};