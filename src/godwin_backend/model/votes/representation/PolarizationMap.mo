import Polarization "Polarization";
import Types "../../Types";
import Categories "../../Categories";
import Utils "../../../utils/Utils";

import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import TrieSet "mo:base/TrieSet";

module {

  // For convenience: from base module
  type Set<K> = TrieSet.Set<K>;
  // For convenience: from types module
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Category = Types.Category;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;

  // For convenience: from other modules

  public func nil(categories: [Category]) : PolarizationMap {
    Utils.make(categories, Categories.key, Categories.equal, Polarization.nil());
  };

  public func addCursorMap(polarization_trie: PolarizationMap, cursor_trie: CursorMap) : PolarizationMap {
    Utils.leftJoin(polarization_trie, cursor_trie, Categories.key, Categories.equal, func(polarization: Polarization, cursor: ?Cursor) : Polarization {
      Polarization.addOptCursor(polarization, cursor);
    });
  };

  public func subCursorMap(polarization_trie: PolarizationMap, cursor_trie: CursorMap) : PolarizationMap {
    Utils.leftJoin(polarization_trie, cursor_trie, Categories.key, Categories.equal, func(polarization: Polarization, cursor: ?Cursor) : Polarization {
      Polarization.subOptCursor(polarization, cursor);
    });
  };

  public func mulCursorMap(polarization_trie: PolarizationMap, cursor_trie: CursorMap) : PolarizationMap {
    Utils.leftJoin(polarization_trie, cursor_trie, Categories.key, Categories.equal, func(polarization: Polarization, cursor: ?Cursor) : Polarization {
      Polarization.mul(polarization, Option.get(cursor, 0.0)); // 0 because if the cursor does not have this category, the resulting polarization shall be nil
    });
  };

  public func mul(polarization_trie: PolarizationMap, coef: Float) : PolarizationMap {
    Trie.mapFilter(polarization_trie, func(category: Category, polarization: Polarization) : ?Polarization {
      ?Polarization.mul(polarization, coef);
    });
  };

  public func add(a: PolarizationMap, b: PolarizationMap) : PolarizationMap {
    Utils.leftJoin(a, b, Categories.key, Categories.equal, func(polarization_a: Polarization, polarization_b: ?Polarization) : Polarization {
      Polarization.addOpt(polarization_a, polarization_b);
    });
  };

  public func sub(a: PolarizationMap, b: PolarizationMap) : PolarizationMap {
    Utils.leftJoin(a, b, Categories.key, Categories.equal, func(polarization_a: Polarization, polarization_b: ?Polarization) : Polarization {
      Polarization.subOpt(polarization_a, polarization_b);
    });
  };

  public func toCursorMap(polarization_trie: PolarizationMap) : CursorMap {
    Trie.mapFilter(polarization_trie, func(_: Text, polarization: Polarization) : ?Cursor { ?Polarization.toCursor(polarization); });
  };

  public func keys(polarization_trie: PolarizationMap) : Set<Category> {
    Utils.keys(polarization_trie, Categories.key, Categories.equal);
  };

  public func equal(a: PolarizationMap, b: PolarizationMap) : Bool {
    Trie.equalStructure(a, b, Categories.equal, Polarization.equal);
  };

  public func toText(polarization_trie: PolarizationMap) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(Trie.size(polarization_trie));
    for ((category, polarization) in Trie.iter(polarization_trie)){
      buffer.add("(category: " # category # ", polarization: " # Polarization.toText(polarization) # ")");
    };
    Text.join(", ", buffer.vals());
  };

};