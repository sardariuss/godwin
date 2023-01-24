import Votes "Votes"; 
import Polarization "representation/Polarization";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";

module {

  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Ballot<T> = Types.Ballot<T>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;

  public type Vote = Types.Vote<Cursor, Polarization>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Opinions = Votes<Cursor, Polarization>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register) : Opinions {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      Polarization.nil(),
      Polarization.addCursor,
      Polarization.subCursor
    );
  };

};