import Types "../types";
import Interests "interests";
import Iteration "iteration";
import Polarization "../representation/polarization";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";
import Vote "vote";
import Queries "queries";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import Option "mo:base/Option";
import Prelude "mo:base/Prelude";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

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
  type Question = Types.Question;
  type Vote<B, A> = Types.Vote<B, A>;

  public type Register = {
    iterations: Trie<Nat, Iteration>;
    index: Nat;
    rbts: Queries.IterationRBTs;
  };

  public func empty() : Register {
    var rbts = Queries.init();
    rbts := Queries.addOrderBy(rbts, #VOTE_AGGREGATE);
    rbts := Queries.addOrderBy(rbts, #VOTE_DATE);
    {
      iterations = Trie.empty<Nat, Iteration>();
      index = 0;
      rbts;
    };
  };

  public func getMostInteresting(register: Register) : ?Iteration {
    let result = Queries.queryQuestions(
      register.rbts,
      #VOTE_AGGREGATE,
      ?{ id = 0; data = #VOTE_AGGREGATE(#INTEREST(0)); },
      ?{ id = 0; data = #VOTE_AGGREGATE(#INTEREST(1_000_000_000_000)); }, // @todo: what could be a max for the score?
      #bwd,
      1);
    if (result.ids.size() == 0) { return null; }
    else { return ?get(register, result.ids[0]); };
  };

  public func getOldestInterest(register: Register) : ?Iteration {
    let result = Queries.queryQuestions(
      register.rbts,
      #VOTE_DATE,
      ?{ id = 0; data = #VOTE_DATE({ stage = #INTEREST; date = 0; }); },
      ?{ id = 0; data = #VOTE_DATE({ stage = #INTEREST; date = 1_000_000_000_000; }); }, // @todo: what could be a max for the score?
      #bwd,
      1);
    if (result.ids.size() == 0) { return null; }
    else { return ?get(register, result.ids[0]); };
  };

  public func getOldestOpinion(register: Register) : ?Iteration {
    let result = Queries.queryQuestions(
      register.rbts,
      #VOTE_DATE,
      ?{ id = 0; data = #VOTE_DATE({ stage = #OPINION; date = 0; }); },
      ?{ id = 0; data = #VOTE_DATE({ stage = #OPINION; date = 1_000_000_000_000; }); }, // @todo: what could be a max for the score?
      #fwd,
      1);
    if (result.ids.size() == 0) { return null; }
    else { return ?get(register, result.ids[0]); };
  };

    public func getOldestCategorization(register: Register) : ?Iteration {
    let result = Queries.queryQuestions(
      register.rbts,
      #VOTE_DATE,
      ?{ id = 0; data = #VOTE_DATE({ stage = #CATEGORIZATION; date = 0; }); },
      ?{ id = 0; data = #VOTE_DATE({ stage = #CATEGORIZATION; date = 1_000_000_000_000; }); }, // @todo: what could be a max for the score?
      #fwd,
      1);
    if (result.ids.size() == 0) { return null; }
    else { return ?get(register, result.ids[0]); };
  };

  public func get(register: Register, index: Nat) : Iteration {
    switch(Trie.get(register.iterations, Types.keyNat(index), Nat.equal)){
      case(null) { Debug.trap("The iteration does not exist"); };
      case(?iteration) { iteration; }
    }
  };

  public func find(register: Register, index: Nat) : ?Iteration {
    Trie.get(register.iterations, Types.keyNat(index), Nat.equal);
  };

  public func newIteration(
    register: Register,
    opening_date: Int,
  ) : (Register, Iteration) {
    let iteration = Iteration.new(register.index, opening_date);
    (
      {
        iterations = Trie.put(register.iterations, Types.keyNat(iteration.id), Nat.equal, iteration).0;
        index = register.index + 1;
        rbts = Queries.add(register.rbts, iteration);
      },
      iteration
    );
  };

  public func updateIteration(register: Register, iteration: Iteration) : Register {
    // @todo: assert it is in it ?
    let (iterations, old_iteration) = Trie.put(register.iterations, Types.keyNat(iteration.id), Nat.equal, iteration);
    switch(old_iteration){
      case(null) { Debug.trap("@todo"); };
      case(?old) {
        { 
          register with 
          iterations;
          rbts = Queries.replace(register.rbts, old, iteration);
        };
      };
    };
  };

  public func getInterest(register: Register, id: Nat, principal: Principal) : ?Interest {
    Option.chain(get(register, id).interest, func(iteration_interest: Vote<Interest, InterestAggregate>) : ?Interest {
      Vote.getBallot(iteration_interest, principal);
    });
  };

  public func putInterest(register: Register, id: Nat, principal: Principal, interest: Interest) : Register {
    let iteration = get(register, id);
    assert(iteration.voting_stage == #INTEREST);
    switch(iteration.interest){
      case(null) { Prelude.unreachable(); };
      case(?iteration_interest) {
        let new_interest = Vote.putBallot(iteration_interest, principal, interest, Interests.addToAggregate, Interests.removeFromAggregate);
        updateIteration(register, { iteration with new_interest });
      };
    };
  };

  public func removeInterest(register: Register, id: Nat, principal: Principal) : Register {
    let iteration = get(register, id);
    assert(iteration.voting_stage == #INTEREST);
    switch(iteration.interest) {
      case(null) { Prelude.unreachable(); };
      case(?iteration_interest) {
        let new_interest = Vote.removeBallot(iteration_interest, principal, Interests.addToAggregate, Interests.removeFromAggregate);
        updateIteration(register, { iteration with new_interest });
      };
    };
  };

  public func getOpinion(register: Register, id: Nat, principal: Principal) : ?Cursor {
    Option.chain(get(register, id).opinion, func(iteration_opinion: Vote<Cursor, Polarization>) : ?Cursor {
      Vote.getBallot(iteration_opinion, principal);
    });
  };

  public func putOpinion(register: Register, id: Nat, principal: Principal, opinion: Cursor) : Register {
    let iteration = get(register, id);
    assert(iteration.voting_stage == #OPINION);
    switch(iteration.opinion) {
      case(null) { Prelude.unreachable(); };
      case(?iteration_opinion) {
        let new_opinion = Vote.putBallot(iteration_opinion, principal, opinion, Polarization.addCursor, Polarization.subCursor);
        updateIteration(register, { iteration with new_opinion });
      };
    };
  };

  public func removeOpinion(register: Register, id: Nat, principal: Principal) : Register {
    let iteration = get(register, id);
    assert(iteration.voting_stage == #OPINION);
    switch(iteration.opinion) {
      case(null) { Prelude.unreachable(); };
      case(?iteration_opinion) {
        let new_opinion = Vote.removeBallot(iteration_opinion, principal, Polarization.addCursor, Polarization.subCursor);
        updateIteration(register, { iteration with new_opinion });
      };
    };
  };

  public func getCategorization(register: Register, id: Nat, principal: Principal) : ?CategoryCursorTrie {
    Option.chain(get(register, id).categorization, func(iteration_categorization: Vote<CategoryCursorTrie, CategoryPolarizationTrie>) : ?CategoryCursorTrie {
      Vote.getBallot(iteration_categorization, principal);
    });
  };

  public func putCategorization(register: Register, id: Nat, principal: Principal, categorization: CategoryCursorTrie) : Register {
    let iteration = get(register, id);
    assert(iteration.voting_stage == #CATEGORIZATION);
    switch(iteration.categorization) {
      case(null) { Prelude.unreachable(); };
      case(?iteration_categorization) {
        let new_categorization = Vote.putBallot(iteration_categorization, principal, categorization, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie);
        updateIteration(register, { iteration with new_categorization });
      };
    };
  };

  public func removeCategorization(register: Register, id: Nat, principal: Principal) : Register {
    let iteration = get(register, id);
    assert(iteration.voting_stage == #CATEGORIZATION);
    switch(iteration.categorization) {
      case(null) { Prelude.unreachable(); };
      case(?iteration_categorization) {
        let new_categorization = Vote.removeBallot(iteration_categorization, principal, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie);
        updateIteration(register, { iteration with new_categorization });
      };
    };
  };

};