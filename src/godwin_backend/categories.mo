import Types "types";

import Trie "mo:base/Trie";
import Iter "mo:base/Iter";
import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";
import Array "mo:base/Array";

module {

  // For convenience: from base module
  type Set<K> = TrieSet.Set<K>;
  type Iter<K> = Iter.Iter<K>;
  
  // For convenience: from types modules
  type Category = Types.Category;

  public type Categories = Set<Category>;

  public func fromArray(categories_: [Category]) : Categories {
    TrieSet.fromArray(categories_, Text.hash, Text.equal);
  };

  public func toArray(categories_: Categories) : [Category] {
    TrieSet.toArray(categories_);
  };

  public func size(categories_: Categories) : Nat {
    TrieSet.size(categories_);
  };

  public func vals(categories_: Categories) : Iter<Category> {
    Array.vals(TrieSet.toArray(categories_));
  };

  public func contains(categories_: Categories, category: Category) : Bool {
    Trie.get(categories_, Types.keyText(category), Text.equal) != null;
  };

  public func add(categories_: Categories, category: Category) : Categories {
    TrieSet.put(categories_, category, Text.hash(category), Text.equal);
  };

  public func remove(categories_: Categories, category: Category) : Categories {
    TrieSet.delete(categories_, category, Text.hash(category), Text.equal);
  };

};