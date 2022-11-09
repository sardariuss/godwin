import Types "../types";
import Cursor "cursor";
import Categories "../categories";

import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type Cursor = Types.Cursor;
  type Category = Types.Category; 
  type CategoryCursorTrie = Types.CategoryCursorTrie;

  // For convenience: from other modules
  type Categories = Categories.Categories;

  public func init(categories: Categories) : CategoryCursorTrie {
    var trie = Trie.empty<Category, Cursor>();
    for (category in categories.vals()){
      trie := Trie.put(trie, Types.keyText(category), Text.equal, Cursor.init()).0;
    };
    trie;
  };

  public func isValid(cursor_trie: CategoryCursorTrie, categories: Categories) : Bool {
    if (Trie.size(cursor_trie) != categories.size()){
      return false;
    };
    for ((category, cursor) in Trie.iter(cursor_trie)){
      if (not Cursor.isValid(cursor)){
        return false;
      };
      if (not categories.contains(category)){
        return false;
      };
    };
    true;
  };

  public func equal(trie_1: CategoryCursorTrie, trie_2: CategoryCursorTrie) : Bool {
    if (Trie.size(trie_1) != Trie.size(trie_2)){
      return false;
    };
    for ((category_1, cursor_1) in Trie.iter(trie_1)){
      switch(Trie.get(trie_2, Types.keyText(category_1), Text.equal)){
        case(null) { return false; };
        case(?cursor_2) { if (not Cursor.equal(cursor_1, cursor_2)) { return false; }; };
      };
    };
    return true;
  };

  public func toText(cursor_trie: CategoryCursorTrie) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(Trie.size(cursor_trie));
    for ((category, cursor) in Trie.iter(cursor_trie)){
      buffer.add("(category: " # category # ", cursor: " # Cursor.toText(cursor) # ")");
    };
    Text.join(", ", buffer.vals());
  };

};