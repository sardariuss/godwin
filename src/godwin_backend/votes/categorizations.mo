import Votes "votes";
import Types "../types";
import Categories "../categories";
import CategoryCursorTrie "../representation/categoryCursorTrie";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";

import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  
  // For convenience: from types modules  
  type Ballot = Types.CategoryCursorTrie;
  type Aggregate = Types.CategoryPolarizationTrie;

  // For convenience: from other modules
  type Categories = Categories.Categories;
  
  // Ballot = CategoryCursorTrie = Trie<Category, Cursor>
  // Aggregate = CategoryPolarizationTrie = Trie<Category, Polarization>
  type Register = Votes.VoteRegister<Ballot, Aggregate>;
  
  public func empty(categories: Categories) : Categorizations {
    Categorizations(categories, Votes.empty<Ballot, Aggregate>());
  };

  public class Categorizations(categories: Categories, register: Register) {

    let categories_ : Categories = categories;
    var register_ : Register = register;

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

  };

};