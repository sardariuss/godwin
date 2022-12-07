import Types "types";

import Trie "mo:base/Trie";
import Iter "mo:base/Iter";
import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

// categories management:
//  - to compute the user convictions, always iterate on the current definition of the categories (not the ones from the categorization)
//     - if the category from the definition is not found in the questions's categorization, do nothing
//     - if a question's categorization category is not in the definition of categories, do nothing
//  - if a category is removed, remove it from all users convictions
//  - if a category is added, nothing to do
module {

  // For convenience: from base module
  type Set<K> = TrieSet.Set<K>;
  type Iter<K> = Iter.Iter<K>;
  
  // For convenience: from types modules
  type Category = Types.Category;

  public type UpdateType = {
    #CATEGORY_ADDED;
    #CATEGORY_REMOVED;
  };

  type Callback = (Category, UpdateType) -> ();

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
        callbacks_.get(idx)(category, #CATEGORY_ADDED);
      };
    };

    public func remove(category: Category) {
      assert(contains(category));
      categories_ := TrieSet.delete(categories_, category, Text.hash(category), Text.equal);
      for(idx in Iter.range(0, callbacks_.size() - 1)){
        callbacks_.get(idx)(category, #CATEGORY_REMOVED);
      };
    };

    public func addCallback(callback: Callback) {
      callbacks_.add(callback);
    };

  };
};