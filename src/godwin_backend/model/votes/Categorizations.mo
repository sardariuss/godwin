import Votes "Votes";
import Votes2 "Votes2"; 
import CursorMap "representation/CursorMap";
import PolarizationMap "representation/PolarizationMap";
import Categories "../Categories";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";

module {

  type Categories = Categories.Categories;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;  
  type Votes<T, A> = Votes.Votes<T, A>;
  type Votes2<T, A> = Votes2.Votes2<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;

  public type Vote = Types.Vote<CursorMap, PolarizationMap>;
  public type Vote2 = Types.Vote2<CursorMap, PolarizationMap>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Categorizations = Votes<CursorMap, PolarizationMap>;
  public type Categorizations2 = Votes2<CursorMap, PolarizationMap>;
  public type Ballot = Types.Ballot<CursorMap>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register, categories: Categories) : Categorizations {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.nil(categories),
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
  };

  public func build2(register: Register, categories: Categories) : Categorizations2 {
    Votes2.Votes2(
      WMap.WMap<Nat, Vote2>(Map.new<Nat, Vote2>(), Map.nhash),
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.nil(categories),
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
  };

};