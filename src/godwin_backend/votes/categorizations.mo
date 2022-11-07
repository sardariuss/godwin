import Votes "votes";
import Types "../types";
import CategoryCursorTrie "../representation/categoryCursorTrie";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";

import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  
  // For convenience: from types modules
  type Categories = Types.Categories;
  type Ballot = Types.CategoryCursorTrie;
  type Aggregate = Types.CategoryPolarizationTrie;

  type Register = Votes.VoteRegister<Ballot, Aggregate>;
  
  public func empty(categories: Categories) : Categorizations {
    Categorizations({ 
      categories;
      register = Votes.empty<Ballot, Aggregate>();
    });
  };

  type Shareable = {
    categories: Categories;
    register: Register;
  };

  public class Categorizations(args: Shareable) {

    let categories_ : Categories = args.categories;
    var register_ : Register = args.register;

    public func share() : Shareable {
      {
        categories = categories_;
        register = register_;
      };
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