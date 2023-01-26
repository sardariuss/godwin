import Cursor "Cursor";
import Types "../../Types";
import Utils "../../../utils/Utils";

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
  type CursorMap = Types.CursorMap;

  public func init(categories: Set<Category>) : CursorMap {
    var trie = Trie.empty<Category, Cursor>();
    for (category in Utils.setIter(categories)){
      trie := Trie.put(trie, Categories.key(category), Categories.equal, Cursor.init()).0;
    };
    trie;
  };

  public func isValid(cursor_trie: CursorMap, categories: Set<Category>) : Bool {
    if (Trie.size(cursor_trie) != TrieSet.size(categories)){
      return false;
    };
    for ((category, cursor) in Trie.iter(cursor_trie)){
      if (not Cursor.isValid(cursor)){
        return false;
      };
      if (Option.isNull(Trie.get(categories, Categories.key(category), Categories.equal))){
        return false;
      };
    };
    true;
  };

  public func keys(cursor_trie: CursorMap) : Set<Category> {
    Utils.keys(cursor_trie, Categories.key, Categories.equal);
  };

  public func equal(a: CursorMap, b: CursorMap) : Bool {
    Trie.equalStructure(a, b, Categories.equal, Cursor.equal);
  };

  public func toText(cursor_trie: CursorMap) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(Trie.size(cursor_trie));
    for ((category, cursor) in Trie.iter(cursor_trie)){
      buffer.add("(category: " # category # ", cursor: " # Cursor.toText(cursor) # ")");
    };
    Text.join(", ", buffer.vals());
  };

};