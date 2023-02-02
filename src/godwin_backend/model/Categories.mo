import Types "Types";

import WSet "../utils/wrappers/WSet";

import Set "mo:map/Set";

import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Array "mo:base/Array";

module {

  type Key<K> = Trie.Key<K>;
  type Category = Types.Category;
  type Set<K> = Set.Set<K>;
  type WSet<K> = WSet.WSet<K>;

  public type Register = Set<Category>;
  public type Categories = WSet<Category>;

  public func key(a: Category) : Key<Category> { { key = a; hash = Text.hash(a); } };
  public func equal(a: Category, b: Category) : Bool { Text.equal(a, b); };

  public func initRegister(array: [Category]) : Register {
    Set.fromIter(Array.vals(array), Set.thash);
  };

  public func build(register: Register) : Categories {
    WSet.WSet(register, Set.thash);
  };

};