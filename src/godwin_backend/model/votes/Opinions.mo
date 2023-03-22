import Votes "Votes"; 
import BallotAggregator "BallotAggregator";
import Polarization "representation/Polarization";
import Cursor "representation/Cursor";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";

module {

  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Votes<T, A> = Votes.Votes<T, A>;
  type BallotAggregator<T, A> = BallotAggregator.BallotAggregator<T, A>;
  type Map<K, V> = Map.Map<K, V>;

  public type Vote = Types.Vote<Cursor, Polarization>;
  public type Register = Map<Nat, Vote>;
  public type Opinions = Votes<Cursor, Polarization>;
  public type Ballot = Types.Ballot<Cursor>;

  public func initRegister() : Register {
    Map.new<Nat, Vote>();
  };

  public func build(register: Register) : Opinions {
    Votes.Votes(
      WMap.WMap<Nat, Vote>(register, Map.nhash),
      BallotAggregator.BallotAggregator<Cursor, Polarization>(
        Cursor.isValid,
        Polarization.addCursor,
        Polarization.subCursor
      ),
      Polarization.nil(),
    );
  };


};