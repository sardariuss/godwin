import Cursor "Cursor";
import Types "../../Types";
import Utils "../../../utils/Utils";
import Categories "../../Categories";

import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type Cursor = Types.Cursor;
  type Category = Types.Category; 
  type CursorMap = Types.CursorMap;
  type Categories = Categories.Categories;

  public func identity(categories: Categories) : CursorMap {
    var trie = Trie.empty<Category, Cursor>();
    for (category in categories.keys()){
      trie := Trie.put(trie, Categories.key(category), Categories.equal, Cursor.identity()).0;
    };
    trie;
  };

  public func isValid(cursor_trie: CursorMap, categories: Categories) : Bool {
    if (Trie.size(cursor_trie) != categories.size()){
      return false;
    };
    for ((category, cursor) in Trie.iter(cursor_trie)){
      if (not Cursor.isValid(cursor)){
        return false;
      };
      if (not categories.has(category)){
        return false;
      };
    };
    true;
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