import Votes "votes"; 
import Polarization "../representation/polarization";
import Types "../types";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

module {

  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Vote<T, A> = Types.Vote<T, A>;
  type Ballot<T> = Types.Ballot<T>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;

  public type Register = Map2D<Nat, Nat, Vote<Cursor, Polarization>>;
  public type Opinions = Votes<Cursor, Polarization>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote<Cursor, Polarization>>>();
  };

  public func build(register: Register) : Opinions {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote<Cursor, Polarization>>(register, Map.nhash, Map.nhash),
      Polarization.nil(),
      Polarization.addCursor,
      Polarization.subCursor
    );
  };

};