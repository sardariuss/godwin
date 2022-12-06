import Types "../types";
import Interests "interests";
import Iteration "iteration";
import Polarization "../representation/polarization";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";
import Vote "vote";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Iteration = Types.Iteration;
  type Vote<B, A> = Types.Vote<B, A>;

  public type Register = {
    iterations: Trie<Nat, Iteration>;
    index: Nat;
  };

  public func empty() : Register {
    {
      iterations = Trie.empty<Nat, Iteration>();
      index = 0;
    };
  };

  public func getIteration(register: Register, index: Nat) : Iteration {
    switch(Trie.get(register.iterations, Types.keyNat(index), Nat.equal)){
      case(null) { Debug.trap("The iteration does not exist"); };
      case(?iteration) { iteration; }
    }
  };

  public func findIteration(register: Register, index: Nat) : ?Iteration {
    Trie.get(register.iterations, Types.keyNat(index), Nat.equal);
  };

  public func newIteration(
    register: Register,
    question_id: Nat,
    opening_date: Int,
  ) : (Register, Iteration) {
    let iteration = {
      id = register.index;
      question_id;
      opening_date;
      closing_date = null;
      current_vote = #INTEREST;
      interest = ?Vote.new<Interest, InterestAggregate>(opening_date, #OPEN, { ups = 0; downs = 0; score = 0; });
      opinion = null; // Vote.new<Cursor, Polarization>(opening_date, #PENDING, Polarization.nil()); @todo
      categorization = null; // Vote.new<CategoryCursorTrie, CategoryPolarizationTrie>(opening_date, #PENDING, Trie.empty<Text, Polarization>()); @todo
    };

    (
      {
        iterations = Trie.put(register.iterations, Types.keyNat(iteration.id), Nat.equal, iteration).0;
        index = register.index + 1;
      },
      iteration
    );
  };

  public func updateIteration(register: Register, iteration: Iteration) : Register {
    // @todo: assert it is in it ?
    {
      iterations = Trie.put(register.iterations, Types.keyNat(iteration.id), Nat.equal, iteration).0;
      index = register.index;
    };
  };

  public func getInterest(register: Register, id: Nat, principal: Principal) : ?Interest {
    Option.chain(getIteration(register, id).interest, func(iteration_interest: Vote<Interest, InterestAggregate>) : ?Interest {
      Vote.getBallot2<Interest, InterestAggregate>(iteration_interest, principal);
    });
  };

  public func putInterest(register: Register, id: Nat, principal: Principal, interest: Interest) : Register {
    let iteration = getIteration(register, id);
    assert(iteration.current_vote == #INTEREST);
    assert(iteration.interest != null);
    Option.getMapped(
      iteration.interest,
      func(iteration_interest: Vote<Interest, InterestAggregate>) : Register {
        let new_interest = Vote.putBallot2<Interest, InterestAggregate>(iteration_interest, principal, interest, Interests.addToAggregate, Interests.removeFromAggregate);
        updateIteration(register, Iteration.updateInterests(iteration, ?new_interest));
      },
      register);
  };

  public func removeInterest(register: Register, id: Nat, principal: Principal) : Register {
    let iteration = getIteration(register, id);
    assert(iteration.current_vote == #INTEREST);
    assert(iteration.interest != null);
    Option.getMapped(
      iteration.interest, 
      func(iteration_interest: Vote<Interest, InterestAggregate>) : Register {
        let new_interest = Vote.removeBallot2<Interest, InterestAggregate>(iteration_interest, principal, Interests.addToAggregate, Interests.removeFromAggregate);
        updateIteration(register, Iteration.updateInterests(iteration, ?new_interest));
      },
      register);
  };

  public func getOpinion(register: Register, id: Nat, principal: Principal) : ?Cursor {
    Option.chain(getIteration(register, id).opinion, func(iteration_opinion: Vote<Cursor, Polarization>) : ?Cursor {
      Vote.getBallot2<Cursor, Polarization>(iteration_opinion, principal);
    });
  };

  public func putOpinion(register: Register, id: Nat, principal: Principal, opinion: Cursor) : Register {
    let iteration = getIteration(register, id);
    assert(iteration.current_vote == #OPINION);
    assert(iteration.opinion != null);
    Option.getMapped(
      iteration.opinion,
      func(iteration_opinion: Vote<Cursor, Polarization>) : Register {
        let new_opinion = Vote.putBallot2<Cursor, Polarization>(iteration_opinion, principal, opinion, Polarization.addCursor, Polarization.subCursor);
        updateIteration(register, Iteration.updateOpinions(iteration, ?new_opinion));
      },
      register);
  };

  public func removeOpinion(register: Register, id: Nat, principal: Principal) : Register {
    let iteration = getIteration(register, id);
    assert(iteration.current_vote == #OPINION);
    assert(iteration.opinion != null);
    Option.getMapped(
      iteration.opinion,
      func(iteration_opinion: Vote<Cursor, Polarization>) : Register {
        let new_opinion = Vote.removeBallot2<Cursor, Polarization>(iteration_opinion, principal, Polarization.addCursor, Polarization.subCursor);
        updateIteration(register, Iteration.updateOpinions(iteration, ?new_opinion));
      },
      register);
  };

  public func getCategorization(register: Register, id: Nat, principal: Principal) : ?CategoryCursorTrie {
    Option.chain(getIteration(register, id).categorization, func(iteration_categorization: Vote<CategoryCursorTrie, CategoryPolarizationTrie>) : ?CategoryCursorTrie {
      Vote.getBallot2<CategoryCursorTrie, CategoryPolarizationTrie>(iteration_categorization, principal);
    });
  };

  public func putCategorization(register: Register, id: Nat, principal: Principal, categorization: CategoryCursorTrie) : Register {
    let iteration = getIteration(register, id);
    assert(iteration.current_vote == #CATEGORIZATION);
    assert(iteration.categorization != null);
    Option.getMapped(
      iteration.categorization,
      func(iteration_categorization: Vote<CategoryCursorTrie, CategoryPolarizationTrie>) : Register {
        let new_categorization = Vote.putBallot2<CategoryCursorTrie, CategoryPolarizationTrie>(iteration_categorization, principal, categorization, CategoryPolarizationTrie.add, CategoryPolarizationTrie.sub);
        updateIteration(register, Iteration.updateCategorizations(iteration, ?new_categorization));
      },
      register);
  };

  public func removeCategorization(register: Register, id: Nat, principal: Principal) : Register {
    let iteration = getIteration(register, id);
    assert(iteration.current_vote == #CATEGORIZATION);
    assert(iteration.categorization != null);
    Option.getMapped(
      iteration.categorization,
      func(iteration_categorization: Vote<CategoryCursorTrie, CategoryPolarizationTrie>) : Register {
        let new_categorization = Vote.removeBallot2<CategoryCursorTrie, CategoryPolarizationTrie>(iteration_categorization, principal, CategoryPolarizationTrie.add, CategoryPolarizationTrie.sub);
        updateIteration(register, Iteration.updateCategorizations(iteration, ?new_categorization));
      },
      register);
  };

};