import Votes "Votes"; 
import PolarizationMap "representation/PolarizationMap";
import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";

module {

  type Category = Types.Category;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;  
  type Votes<T, A> = Votes.Votes<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;

  public type Vote = Types.Vote<CursorMap, PolarizationMap>;
  public type Register = Map2D<Nat, Nat, Vote>;
  public type Categorizations = Votes<CursorMap, PolarizationMap>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote>>();
  };

  public func build(register: Register, categories: [Category]) : Categorizations {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote>(register, Map.nhash, Map.nhash),
      PolarizationMap.nil(categories),
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
  };

};