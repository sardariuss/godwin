import Votes "votes"; 
import Interests "interests";
import Types "../types";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

module {

  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Vote<T, A> = Types.Vote<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;

  public type Register = Map2D<Nat, Nat, Vote<Interest, InterestAggregate>>;
  public type Interests2 = Votes<Interest, InterestAggregate>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote<Interest, InterestAggregate>>>();
  };

  public func build(register: Register) : Interests2 {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote<Interest, InterestAggregate>>(register, Map.nhash, Map.nhash),
      Interests.emptyAggregate(),
      Interests.addToAggregate,
      Interests.removeFromAggregate
    );
  };

};