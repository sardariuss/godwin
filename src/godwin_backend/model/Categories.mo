import Types "Types";

import WSet "../utils/wrappers/WSet";

import Text "mo:base/Text";
import Trie "mo:base/Trie";

module {

  type Key<K> = Trie.Key<K>;
  type Category = Types.Category;
  type WSet<K> = WSet.WSet<K>;

  public type Categories = WSet<Category>;

  public func key(a: Category) : Key<Category> { { key = a; hash = Text.hash(a); } };
  public func equal(a: Category, b: Category) : Bool { Text.equal(a, b); };

};