import Votes "Votes"; 
import BallotAggregator "BallotAggregator";
import Appeal "representation/Appeal";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";

module {

  type Interest = Types.Interest;
  type Appeal = Types.Appeal;
  type Votes<T, A> = Votes.Votes<T, A>;
  type BallotAggregator<T, A> = BallotAggregator.BallotAggregator<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  
  public type Vote = Types.Vote<Interest, Appeal>;
  public type Register = Map<Nat, Vote>;
  public type Interests = Votes<Interest, Appeal>;
  public type Ballot = Types.Ballot<Interest>;

  public func initRegister() : Register {
    Map.new<Nat, Vote>();
  };

  public func build(register: Register) : Interests {

    Votes.Votes(
      WMap.WMap<Nat, Vote>(register, Map.nhash),
      BallotAggregator.BallotAggregator<Interest, Appeal>(
        func(interest: Interest) : Bool { true; },
        Appeal.add,
        Appeal.remove
      ),
      Appeal.init()
    );
  };

};