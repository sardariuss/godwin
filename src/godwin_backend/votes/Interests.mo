import Votes "Votes"; 
import Appeal "../representation/Appeal";
import Types "../Types";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

import Order "mo:base/Order";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Option "mo:base/Option";

module {

  type Interest = Types.Interest;
  type Appeal = Types.Appeal;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  
  public type Vote = Types.Vote<Interest, Appeal>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Interests = Votes<Interest, Appeal>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register) : Interests {

    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      Appeal.init(),
      Appeal.add,
      Appeal.remove
    );
  };

};