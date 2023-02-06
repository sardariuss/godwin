import Votes "Votes"; 
import CursorMap "representation/CursorMap";
import PolarizationMap "representation/PolarizationMap";
import Categories "../Categories";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";
import Utils "../../utils/Utils";
import Poll "Poll";
import Questions "../Questions";

import Map "mo:map/Map";

import Debug "mo:base/Debug";

module {

  type Categories = Categories.Categories;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;  
  type Votes<T, A> = Votes.Votes<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type TypedBallot = Types.TypedBallot;
  type Questions = Questions.Questions;

  public type Vote = Types.Vote<CursorMap, PolarizationMap>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Categorizations = Votes<CursorMap, PolarizationMap>;
  type Categorizations2 = Poll.Poll<CursorMap, PolarizationMap>;
  public type Ballot = Types.Ballot<CursorMap>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build2(register: Register, categories: Categories, questions: Questions) : Categorizations2 {
    let votes = Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      CursorMap.identity(categories),
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.nil(categories),
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
    
    Poll.Poll(#CATEGORIZATION, votes, questions);
  };

  public func build(register: Register, categories: Categories) : Categorizations {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      CursorMap.identity(categories),
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.nil(categories),
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
  };

  public func toTypedBallot(ballot: Ballot) : TypedBallot {
    #CATEGORIZATION({ answer = Utils.trieToArray(ballot.answer); date = ballot.date; });
  };

  public func fromTypedBallot(typed_ballot: TypedBallot) : Ballot {
    switch(typed_ballot){
      case(#CATEGORIZATION(ballot)) { { answer = Utils.arrayToTrie(ballot.answer, Categories.key, Categories.equal); date = ballot.date; }; };
      case(_) { Debug.trap("@todo"); };
    };
  };

};