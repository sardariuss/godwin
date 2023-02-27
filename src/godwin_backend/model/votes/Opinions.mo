import Votes "Votes"; 
import Votes2 "Votes2"; 
import Polarization "representation/Polarization";
import Cursor "representation/Cursor";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";

module {

  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Votes2<T, A> = Votes2.Votes2<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;

  public type Vote = Types.Vote<Cursor, Polarization>;
  public type Vote2 = Types.Vote2<Cursor, Polarization>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Opinions = Votes<Cursor, Polarization>;
  public type Opinions2 = Votes2<Cursor, Polarization>;
  public type Ballot = Types.Ballot<Cursor>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register) : Opinions {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      Cursor.isValid,
      Polarization.nil(),
      Polarization.addCursor,
      Polarization.subCursor
    );
  };

  public func build2(register: Register) : Opinions2 {
    Votes2.Votes2(
      WMap.WMap<Nat, Vote2>(Map.new<Nat, Vote2>(), Map.nhash),
      Cursor.isValid,
      Polarization.nil(),
      Polarization.addCursor,
      Polarization.subCursor
    );
  };


};