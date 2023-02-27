import Votes "Votes"; 
import Votes2 "Votes2"; 
import Appeal "representation/Appeal";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";

module {

  type Interest = Types.Interest;
  type Appeal = Types.Appeal;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Votes2<T, A> = Votes2.Votes2<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  
  public type Vote = Types.Vote<Interest, Appeal>;
  public type Vote2 = Types.Vote2<Interest, Appeal>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Interests = Votes<Interest, Appeal>;
  public type Interests2 = Votes2<Interest, Appeal>;
  public type Ballot = Types.Ballot<Interest>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register) : Interests {

    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      func(interest: Interest) : Bool { true; },
      Appeal.init(),
      Appeal.add,
      Appeal.remove
    );
  };

  public func build2(register: Register) : Interests2 {

    Votes2.Votes2(
      WMap.WMap<Nat, Vote2>(Map.new<Nat, Vote2>(), Map.nhash),
      func(interest: Interest) : Bool { true; },
      Appeal.init(),
      Appeal.add,
      Appeal.remove
    );
  };

};