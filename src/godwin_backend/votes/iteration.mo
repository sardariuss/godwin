import Vote "vote";
import Types "../types";
import Polarization "../representation/polarization";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";

import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Trie "mo:base/Trie";

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

  public func new(date: Int) : Iteration { // @todo: date is not good for categorization vote
    {
      opinion = Vote.new<Cursor, Polarization>(date, Polarization.nil());
      categorization = Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(date, Trie.empty<Text, Polarization>()); 
    };
  };

  public func putOpinion(iteration: Iteration, principal: Principal, opinion: Cursor) : Iteration {
    { iteration with opinion = Vote.putBallot(iteration.opinion, principal, opinion, Polarization.addCursor, Polarization.subCursor); };
  };

  public func removeOpinion(iteration: Iteration, principal: Principal) : Iteration {
    { iteration with opinion = Vote.removeBallot(iteration.opinion, principal, Polarization.addCursor, Polarization.subCursor); };
  };

  public func putCategorization(iteration: Iteration, principal: Principal, cat: CategoryCursorTrie) : Iteration {
    { iteration with categorization = Vote.putBallot(iteration.categorization, principal, cat, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie); };
  };

  public func removeCategorization(iteration: Iteration, principal: Principal) : Iteration {
    { iteration with categorization = Vote.removeBallot(iteration.categorization, principal, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie); };
  };
  
};