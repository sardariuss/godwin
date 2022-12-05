import Types "../types";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;

  // For convenience: from types module
  type VoteState = Types.VoteState;
  type Vote<B, A> = Types.Vote<B, A>;

  // B for ballot, A for aggregate
  public type VoteRegister<B, A> = {
    // map<user, map<item, ballot>>
    ballots: Trie<Principal, Trie<Nat, B>>;
    // map<item, aggregate>
    aggregates: Trie<Nat, A>;
  };

  // For clarity
  type Item = Nat;

  public func empty<B, A>() : VoteRegister<B, A> {
    {
      ballots = Trie.empty<Principal, Trie<Item, B>>();
      aggregates = Trie.empty<Item, A>();
    };
  };

  public func getUserBallots<B, A>(register: VoteRegister<B, A>, user: Principal) : Trie<Item, B> {
    var user_ballots = Trie.empty<Item, B>();
    switch(Trie.get(register.ballots, Types.keyPrincipal(user), Principal.equal)){
      case(null){};
      case(?ballots){
        user_ballots := ballots;
      };
    };
    user_ballots;
  };

  public func getBallot<B, A>(register: VoteRegister<B, A>, user: Principal, item: Item) : ?B {
    Trie.get(getUserBallots<B, A>(register, user), Types.keyNat(item), Nat.equal);
  };

  public func getAggregate<B, A>(register: VoteRegister<B, A>, item: Item) : ?A {
    Trie.get(register.aggregates, Types.keyNat(item), Nat.equal);
  };

  public func putBallot<B, A>(
    register: VoteRegister<B, A>,
    user: Principal,
    item: Item,
    ballot: B,
    empty_aggregate: () -> A,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : (VoteRegister<B, A>, ?B, A, A) {
    // Put the ballot in the user's ballots
    let (user_ballots, removed_ballot) = Trie.put(getUserBallots<B, A>(register, user), Types.keyNat(item), Nat.equal, ballot);
    // Get the aggregate from the register, initialize it with an empty one if not found
    let old_aggregate = Option.get(getAggregate(register, item), empty_aggregate());
    // Add the ballot to the aggregate
    var new_aggregate = add_to_aggregate(old_aggregate, ballot);
    // If there was an old ballot, remove it from the aggregate
    Option.iterate(removed_ballot, func(removed: B) {
      new_aggregate := remove_from_aggregate(new_aggregate, removed);
    });
    // Return the updated register, removed ballot, old aggregate and new aggregate
    (
      {
        ballots = Trie.put(register.ballots, Types.keyPrincipal(user), Principal.equal, user_ballots).0;
        aggregates = Trie.put(register.aggregates, Types.keyNat(item), Nat.equal, new_aggregate).0;
      },
      removed_ballot,
      old_aggregate,
      new_aggregate
    );
  };

  public func removeBallot<B, A>(
    register: VoteRegister<B, A>,
    user: Principal,
    item: Item,
    empty_aggregate: () -> A,
    remove_from_aggregate: (A, B) -> A
  ) : (VoteRegister<B, A>, ?B, A, A) {
    // Remove the ballot from the user's ballots
    let (user_ballots, removed_ballot) = Trie.remove(getUserBallots<B, A>(register, user), Types.keyNat(item), Nat.equal);
    // Get the aggregate from the register, initialize it with an empty one if not found
    let old_aggregate = Option.get(getAggregate(register, item), empty_aggregate());
    // If the ballot has been removed, remove it from the aggregate
    let new_aggregate = switch(removed_ballot){
      case(null){ old_aggregate; };
      case(?old_ballot){ remove_from_aggregate(old_aggregate, old_ballot); };
    };
    // Return the updated register, removed ballot, old aggregate and new aggregate
    (
      {
        ballots = Trie.put(register.ballots, Types.keyPrincipal(user), Principal.equal, user_ballots).0;
        aggregates = Trie.put(register.aggregates, Types.keyNat(item), Nat.equal, new_aggregate).0;
      },
      removed_ballot,
      old_aggregate,
      new_aggregate
    );
  };

  public func new<B, A>(state: VoteState, aggregate: A) : Vote<B, A> {
    {
      state;
      ballots = Trie.empty<Principal, B>();
      aggregate;
    };
  };

  func update<B, A>(vote: Vote<B, A>, ballots: Trie<Principal, B>, aggregate: A) : Vote<B, A> {
    {
      state = vote.state;
      ballots;
      aggregate;
    };
  };

  public func getBallot2<B, A>(
    vote: Vote<B, A>,
    principal: Principal
  ) : ?B {
    Trie.get(vote.ballots, Types.keyPrincipal(principal), Principal.equal);
  };

  public func putBallot2<B, A>(
    vote: Vote<B, A>,
    principal: Principal,
    ballot: B,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : Vote<B, A> {
    // The vote shall be open
    assert(vote.state == #OPEN);
    // Put the ballot in the user's ballots
    let (ballots, removed_ballot) = Trie.put(vote.ballots, Types.keyPrincipal(principal), Principal.equal, ballot);
    // Update the aggregate
    let aggregate = updateAggregate(vote.aggregate, ?ballot, removed_ballot, add_to_aggregate, remove_from_aggregate);
    update(vote, ballots, aggregate);
  };

  public func removeBallot2<B, A>(
    vote: Vote<B, A>,
    principal: Principal,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : Vote<B, A> {
    // The vote shall be open
    assert(vote.state == #OPEN);
    // Remove the ballot from the user's ballots
    let (ballots, removed_ballot) = Trie.remove(vote.ballots, Types.keyPrincipal(principal), Principal.equal);
    // Update the aggregate
    let aggregate = updateAggregate(vote.aggregate, null, removed_ballot, add_to_aggregate, remove_from_aggregate);
    update(vote, ballots, aggregate);
  };

  func updateAggregate<B, A>(
    aggregate: A,
    new_ballot: ?B,
    old_ballot: ?B,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : A {
    var new_aggregate = aggregate;
    // If there is a new ballot, add it to the aggregate
    Option.iterate(new_ballot, func(ballot: B) {
      new_aggregate := add_to_aggregate(new_aggregate, ballot);
    });
    // If there was an old ballot, remove it from the aggregate
    Option.iterate(old_ballot, func(ballot: B) {
      new_aggregate := remove_from_aggregate(new_aggregate, ballot);
    });
    new_aggregate;
  };

};