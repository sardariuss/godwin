import Types "../types";
import Polarization "polarization";

import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Category = Types.Category;
  type Categories = Types.Categories;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;

  public func nil(categories: Categories) : CategoryPolarizationTrie {
    var trie = Trie.empty<Category, Polarization>();
    for ((category, _) in Trie.iter(categories)){
      trie := Trie.put(trie, Types.keyText(category), Text.equal, Polarization.nil()).0;
    };
    trie;
  };

  public func add(polarization_trie: CategoryPolarizationTrie, cursor_trie: CategoryCursorTrie) : CategoryPolarizationTrie {
    // Add the ballot to the polarization trie
    var new_polarization_trie = polarization_trie;
    for ((category, polarization) in Trie.iter(new_polarization_trie)){
      // Assumes that the ballot is valid
      Option.iterate(Trie.get(cursor_trie, Types.keyText(category), Text.equal), func(cursor: Cursor) {
        new_polarization_trie := Trie.put(new_polarization_trie, Types.keyText(category), Text.equal, Polarization.addCursor(polarization, cursor)).0;
      });
    };
    new_polarization_trie;
  };

  public func sub(polarization_trie: CategoryPolarizationTrie, cursor_trie: CategoryCursorTrie) : CategoryPolarizationTrie {
    // Subtract the ballot from the polarization trie
    var new_polarization_trie = polarization_trie;
    for ((category, polarization) in Trie.iter(new_polarization_trie)){
      // Assumes that the ballot is valid
      Option.iterate(Trie.get(cursor_trie, Types.keyText(category), Text.equal), func(cursor: Cursor) {
        new_polarization_trie := Trie.put(new_polarization_trie, Types.keyText(category), Text.equal, Polarization.subCursor(polarization, cursor)).0;
      });
    };
    new_polarization_trie;
  };

  public func equal(trie_1: CategoryPolarizationTrie, trie_2: CategoryPolarizationTrie) : Bool {
    if (Trie.size(trie_1) != Trie.size(trie_2)){
      return false;
    };
    for ((category_1, polarization_1) in Trie.iter(trie_1)){
      switch(Trie.get(trie_2, Types.keyText(category_1), Text.equal)){
        case(null) { return false; };
        case(?polarization_2) { if (not Polarization.equal(polarization_1, polarization_2)) { return false; }; };
      };
    };
    return true;
  };

  public func toText(polarization_trie: CategoryPolarizationTrie) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(Trie.size(polarization_trie));
    for ((category, polarization) in Trie.iter(polarization_trie)){
      buffer.add("(category: " # category # ", polarization: " # Polarization.toText(polarization) # ")");
    };
    Text.join(", ", buffer.vals());
  };

};