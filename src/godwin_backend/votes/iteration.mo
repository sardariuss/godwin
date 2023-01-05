import Vote "vote";
import Types "../types";
import Polarization "../representation/polarization";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";
import CategoryCursorTrie "../representation/categoryCursorTrie";
import Categories "../categories";

import TrieSet "mo:base/TrieSet";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Trie "mo:base/Trie";
import Text "mo:base/Text";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types modules
  type Vote<B, A> = Types.Vote<B, A>;
  type Iteration = Types.Iteration;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Category = Types.Category;

  public func new(date: Int) : Iteration {
    {
      opinion = Vote.new<Cursor, Polarization>(date, Polarization.nil());
      categorization = Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(0, CategoryPolarizationTrie.nil([])); 
    };
  };

  public func openCategorization(iteration: Iteration, date: Int, categories: [Category]) : Iteration {
    { iteration with categorization = Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(date, CategoryPolarizationTrie.nil(categories)); }
  };

  public func putOpinion(iteration: Iteration, principal: Principal, opinion: Cursor) : Iteration {
    { iteration with opinion = Vote.putBallot(iteration.opinion, principal, opinion, Polarization.addCursor, Polarization.subCursor); };
  };

  public func removeOpinion(iteration: Iteration, principal: Principal) : Iteration {
    { iteration with opinion = Vote.removeBallot(iteration.opinion, principal, Polarization.addCursor, Polarization.subCursor); };
  };

  public func putCategorization(iteration: Iteration, principal: Principal, cat: CategoryCursorTrie) : Iteration {
    assert(TrieSet.equal(CategoryPolarizationTrie.keys(iteration.categorization.aggregate), CategoryCursorTrie.keys(cat), Text.equal));
    { iteration with categorization = Vote.putBallot(iteration.categorization, principal, cat, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie); };
  };

  public func removeCategorization(iteration: Iteration, principal: Principal) : Iteration {
    { iteration with categorization = Vote.removeBallot(iteration.categorization, principal, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie); };
  };
  
};