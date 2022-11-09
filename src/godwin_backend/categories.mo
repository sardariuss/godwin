import Types "types";

import Trie "mo:base/Trie";
import Iter "mo:base/Iter";
import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

module {

  // For convenience: from base module
  type Set<K> = TrieSet.Set<K>;
  type Iter<K> = Iter.Iter<K>;
  
  // For convenience: from types modules
  type Category = Types.Category;

  type ChangeType = {
    #ADDED;
    #REMOVED;
  };

  type Callback = (Category, ChangeType) -> ();

  public class Categories(categories: [Category]) {

    var categories_ = TrieSet.fromArray(categories, Text.hash, Text.equal);
    var callbacks_ = Buffer.Buffer<Callback>(0);

    public func share() : [Category] {
      TrieSet.toArray(categories_);
    };

    public func size() : Nat {
      TrieSet.size(categories_);
    };

    public func vals() : Iter<Category> {
      Array.vals(TrieSet.toArray(categories_));
    };

    public func contains(category: Category) : Bool {
      Trie.get(categories_, Types.keyText(category), Text.equal) != null;
    };

    public func add(category: Category) {
      assert(not contains(category));
      categories_ := TrieSet.put(categories_, category, Text.hash(category), Text.equal);
      for(idx in Iter.range(0, callbacks_.size() - 1)){
        callbacks_.get(idx)(category, #ADDED);
      };
    };

    public func remove(category: Category) {
      assert(contains(category));
      categories_ := TrieSet.delete(categories_, category, Text.hash(category), Text.equal);
      for(idx in Iter.range(0, callbacks_.size() - 1)){
        callbacks_.get(idx)(category, #REMOVED);
      };
    };

    public func addCallback(callback: Callback) {
      callbacks_.add(callback);
    };

  };
};