import Votes "Votes";
import CursorMap "representation/CursorMap";
import PolarizationMap "representation/PolarizationMap";
import Categories "../Categories";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";
import Utils "../../utils/Utils";

import Map "mo:map/Map";

import Buffer "mo:base/Buffer";

module {

  type Categories = Categories.Categories;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;  
  type Votes<T, A> = Votes.Votes<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type CursorArray = Types.CursorArray;
  type PolarizationArray = Types.PolarizationArray;

  public type Vote = Types.Vote<CursorMap, PolarizationMap>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Categorizations = Votes<CursorMap, PolarizationMap>;
  public type Ballot = Types.Ballot<CursorMap>;


  public type PublicVote = {
    question_id: Nat;
    ballots: [(Principal, Types.Ballot<CursorArray>)];
    aggregate: PolarizationArray;
  };

  public func toPublicVote(vote: Vote) : PublicVote {
    
    let ballots = Buffer.Buffer<(Principal, Types.Ballot<CursorArray>)>(Map.size(vote.ballots));
    for ((principal, ballot) in Map.entries(vote.ballots)) {
      ballots.add((principal, { date = ballot.date; answer = Utils.trieToArray(ballot.answer); }));
    };

    {
      question_id = vote.question_id;
      ballots = Buffer.toArray(ballots);
      aggregate = Utils.trieToArray(vote.aggregate);
    };
  };

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register, categories: Categories) : Categorizations {
    Votes.Votes(
      WMap.WMap<Nat, Vote>(Map.new<Nat, Vote>(), Map.nhash),
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.nil(categories),
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
  };

};