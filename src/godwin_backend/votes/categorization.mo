import Votes "votes"; 
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";
import Types "../types";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

module {

  type Category = Types.Category;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;  
  type Vote<T, A> = Types.Vote<T, A>;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Map<K, V> = Map.Map<K, V>;
  type Map2D<K1, K2, V> = Map<K1, Map<K2, V>>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;

  public type Register = Map2D<Nat, Nat, Vote<CategoryCursorTrie, CategoryPolarizationTrie>>;
  public type Categorizations = Votes<CategoryCursorTrie, CategoryPolarizationTrie>;

  public func initRegister() : Register {
    Map.new<Nat, Map<Nat, Vote<CategoryCursorTrie, CategoryPolarizationTrie>>>();
  };

  public func build(register: Register, categories: [Category]) : Categorizations {
    Votes.Votes(
      WMap.WMap2D<Nat, Nat, Vote<CategoryCursorTrie, CategoryPolarizationTrie>>(register, Map.nhash, Map.nhash),
      CategoryPolarizationTrie.nil(categories),
      CategoryPolarizationTrie.addCategoryCursorTrie,
      CategoryPolarizationTrie.subCategoryCursorTrie
    );
  };

};