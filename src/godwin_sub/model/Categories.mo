import Types "../stable/Types";

import WMap  "../utils/wrappers/WMap";

import Map   "mo:map/Map";

import Text  "mo:base/Text";
import Trie  "mo:base/Trie";
import Array "mo:base/Array";

module {

  type Key<K>            = Trie.Key<K>;
  type Map<K, V>         = Map.Map<K, V>;
  type WMap<K, V>        = WMap.WMap<K, V>;

  type Category          = Types.Current.Category;
  type CategoryArray     = Types.Current.CategoryArray;
  type CategoryInfo      = Types.Current.CategoryInfo;

  public type Register   = Map<Category, CategoryInfo>;
  public type Categories = WMap<Category, CategoryInfo>;

  public func key(a: Category) : Key<Category> { { key = a; hash = Text.hash(a); } };
  public func equal(a: Category, b: Category) : Bool { Text.equal(a, b); };

  public func initRegister(array: CategoryArray) : Register {
    Map.fromIter(Array.vals(array), Map.thash);
  };

  public func build(register: Register) : Categories {
    WMap.WMap(register, Map.thash);
  };

};