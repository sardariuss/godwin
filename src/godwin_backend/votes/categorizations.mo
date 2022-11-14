import Votes "votes";
import Types "../types";
import Categories "../categories";
import Polarization "../representation/polarization";
import CategoryCursorTrie "../representation/categoryCursorTrie";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  
  // For convenience: from types modules  
  type Ballot = Types.CategoryCursorTrie;
  type Aggregate = Types.CategoryPolarizationTrie;
  type Category = Types.Category;

  // For convenience: from other modules
  type Categories = Categories.Categories;
  type UpdateType = Categories.UpdateType;
  
  // Ballot = CategoryCursorTrie = Trie<Category, Cursor>
  // Aggregate = CategoryPolarizationTrie = Trie<Category, Polarization>
  type Register = Votes.VoteRegister<Ballot, Aggregate>;
  
  public func empty(categories: Categories) : Categorizations {
    Categorizations(Votes.empty<Ballot, Aggregate>(), categories);
  };

  public class Categorizations(register: Register, categories: Categories) {

    var register_ : Register = register;
    let categories_ : Categories = categories;

    public func share() : Register {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Ballot> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Ballot {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, ballot: Ballot) {
      assert(CategoryCursorTrie.isValid(ballot, categories_));
      register_ := Votes.putBallot(register_, principal, question_id, ballot, nilAggregate, CategoryPolarizationTrie.add, CategoryPolarizationTrie.sub).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      register_ := Votes.removeBallot(register_, principal, question_id, CategoryPolarizationTrie.sub).0;
    };

    public func getAggregate(question_id: Nat) : Aggregate {
      switch(Votes.getAggregate(register_, question_id)){
        case(?aggregate) { return aggregate;       };
        case(null)       { return nilAggregate();  };
      };
    };

    public func verifyBallot(ballot: Ballot) : ?Ballot {
      if (CategoryCursorTrie.isValid(ballot, categories_)) { ?ballot; }
      else                                                 { null;    };
    };

    func nilAggregate() : Aggregate {
      CategoryPolarizationTrie.nil(categories_);
    };

    /// For every question in the register, adds a null aggregate for the category
    /// \param[in] category The category to add to the categorizations
    func addCategory(category: Category) {
      for ((question_id, aggregate) in Trie.iter(register_.aggregates)){
        let updated_aggregate = Trie.put(aggregate, Types.keyText(category), Text.equal, Polarization.nil()).0;
        register_ := {
          ballots = register_.ballots;
          aggregates = Trie.put(register_.aggregates, Types.keyNat(question_id), Nat.equal, updated_aggregate).0;
        };
      };
    };

    /// For every question in the register, remove the category's aggregate
    /// \param[in] category The category to remove from the categorizations
    func removeCategory(category: Category) {
      for ((question_id, aggregate) in Trie.iter(register_.aggregates)){
        let updated_aggregate = Trie.remove(aggregate, Types.keyText(category), Text.equal).0;
        register_ := {
          ballots = register_.ballots;
          aggregates = Trie.put(register_.aggregates, Types.keyNat(question_id), Nat.equal, updated_aggregate).0;
        };
      };
    };

    /// Add an observer on the categories at construction, so that every time a category
    /// is added or removed, all aggregates are updated
    categories_.addCallback(func(category: Category, update_type: UpdateType) { 
      switch(update_type){
        case(#CATEGORY_ADDED){ addCategory(category); };
        case(#CATEGORY_REMOVED) { removeCategory(category); };
      };
    });

  };

};