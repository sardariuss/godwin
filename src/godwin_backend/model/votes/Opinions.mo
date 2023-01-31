import Votes "Votes"; 
import Polarization "representation/Polarization";
import Cursor "representation/Cursor";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";

import Debug "mo:base/Debug";

module {

  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type TypedBallot = Types.TypedBallot;

  public type Vote = Types.Vote<Cursor, Polarization>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Opinions = Votes<Cursor, Polarization>;
  public type Ballot = Types.Ballot<Cursor>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register) : Opinions {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      Cursor.identity(),
      Cursor.isValid,
      Polarization.nil(),
      Polarization.addCursor,
      Polarization.subCursor
    );
  };

  public func toTypedBallot(ballot: Ballot) : TypedBallot {
    #OPINION(ballot);
  };

  public func fromTypedBallot(typed_ballot: TypedBallot) : Ballot {
    switch(typed_ballot){
      case(#OPINION(ballot)) { ballot; };
      case(_) { Debug.trap("@todo"); };
    };
  };

};