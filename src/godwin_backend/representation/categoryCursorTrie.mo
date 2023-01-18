import Types "../types";
import Cursor "cursor";
import Utils "../utils";

import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Set<K> = TrieSet.Set<K>;
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type Cursor = Types.Cursor;
  type Category = Types.Category; 
  type CategoryCursorTrie = Types.CategoryCursorTrie;

  public func init(categories: Set<Category>) : CategoryCursorTrie {
    var trie = Trie.empty<Category, Cursor>();
    for (category in Utils.setIter(categories)){
      trie := Trie.put(trie, Types.keyText(category), Text.equal, Cursor.init()).0;
    };
    trie;
  };

  public func isValid(cursor_trie: CategoryCursorTrie, categories: Set<Category>) : Bool {
    if (Trie.size(cursor_trie) != TrieSet.size(categories)){
      return false;
    };
    for ((category, cursor) in Trie.iter(cursor_trie)){
      if (not Cursor.isValid(cursor)){
        return false;
      };
      if (Option.isNull(Trie.get(categories, Types.keyText(category), Text.equal))){
        return false;
      };
    };
    true;
  };

  public func keys(cursor_trie: CategoryCursorTrie) : Set<Category> {
    Utils.keys(cursor_trie, Types.keyText, Text.equal);
  };

  public func equal(a: CategoryCursorTrie, b: CategoryCursorTrie) : Bool {
    Trie.equalStructure(a, b, Text.equal, Cursor.equal);
  };

  public func toText(cursor_trie: CategoryCursorTrie) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(Trie.size(cursor_trie));
    for ((category, cursor) in Trie.iter(cursor_trie)){
      buffer.add("(category: " # category # ", cursor: " # Cursor.toText(cursor) # ")");
    };
    Text.join(", ", buffer.vals());
  };

};