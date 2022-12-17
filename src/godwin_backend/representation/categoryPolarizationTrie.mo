import Types "../types";
import Polarization "polarization";
import Utils "../utils";

import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from types module
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Category = Types.Category;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;

  // For convenience: from other modules

  public func nil(categories: [Category]) : CategoryPolarizationTrie {
    Utils.make(categories, Types.keyText, Text.equal, Polarization.nil());
  };

  public func addCategoryCursorTrie(polarization_trie: CategoryPolarizationTrie, cursor_trie: CategoryCursorTrie) : CategoryPolarizationTrie {
    Utils.leftJoin(polarization_trie, cursor_trie, Types.keyText, Text.equal, func(polarization: Polarization, cursor: ?Cursor) : Polarization {
      Polarization.addOptCursor(polarization, cursor);
    });
  };

  public func subCategoryCursorTrie(polarization_trie: CategoryPolarizationTrie, cursor_trie: CategoryCursorTrie) : CategoryPolarizationTrie {
    Utils.leftJoin(polarization_trie, cursor_trie, Types.keyText, Text.equal, func(polarization: Polarization, cursor: ?Cursor) : Polarization {
      Polarization.subOptCursor(polarization, cursor);
    });
  };

  public func mulCategoryCursorTrie(polarization_trie: CategoryPolarizationTrie, cursor_trie: CategoryCursorTrie) : CategoryPolarizationTrie {
    Utils.leftJoin(polarization_trie, cursor_trie, Types.keyText, Text.equal, func(polarization: Polarization, cursor: ?Cursor) : Polarization {
      Polarization.mul(polarization, Option.get(cursor, 0.0)); // 0 because if the cursor does not have this category, the resulting polarization shall be nil
    });
  };

  public func mul(polarization_trie: CategoryPolarizationTrie, coef: Float) : CategoryPolarizationTrie {
    Trie.mapFilter(polarization_trie, func(category: Category, polarization: Polarization) : ?Polarization {
      ?Polarization.mul(polarization, coef);
    });
  };

  public func add(a: CategoryPolarizationTrie, b: CategoryPolarizationTrie) : CategoryPolarizationTrie {
    Utils.leftJoin(a, b, Types.keyText, Text.equal, func(polarization_a: Polarization, polarization_b: ?Polarization) : Polarization {
      Polarization.addOpt(polarization_a, polarization_b);
    });
  };

  public func sub(a: CategoryPolarizationTrie, b: CategoryPolarizationTrie) : CategoryPolarizationTrie {
    Utils.leftJoin(a, b, Types.keyText, Text.equal, func(polarization_a: Polarization, polarization_b: ?Polarization) : Polarization {
      Polarization.subOpt(polarization_a, polarization_b);
    });
  };

  public func toCategoryCursorTrie(polarization_trie: CategoryPolarizationTrie) : CategoryCursorTrie {
    Trie.mapFilter(polarization_trie, func(_: Text, polarization: Polarization) : ?Cursor { ?Polarization.toCursor(polarization); });
  };

  // @todo: check if the test on size is really required.
  public func equal(a: CategoryPolarizationTrie, b: CategoryPolarizationTrie) : Bool {
    (Trie.size(a) == Trie.size(b)) and Trie.equalStructure(a, b, Text.equal, Polarization.equal);
  };

  public func toText(polarization_trie: CategoryPolarizationTrie) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(Trie.size(polarization_trie));
    for ((category, polarization) in Trie.iter(polarization_trie)){
      buffer.add("(category: " # category # ", polarization: " # Polarization.toText(polarization) # ")");
    };
    Text.join(", ", buffer.vals());
  };

};