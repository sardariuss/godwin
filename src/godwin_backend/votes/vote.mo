import Types "../types";

import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;

  // For convenience: from types module
  type Vote<B, A> = Types.Vote<B, A>;

  public func new<B, A>(date: Int, aggregate: A) : Vote<B, A> {
    {
      date;
      ballots = Trie.empty<Principal, B>();
      aggregate;
    };
  };

  public func getBallot<B, A>(
    vote: Vote<B, A>,
    principal: Principal
  ) : ?B {
    Trie.get(vote.ballots, Types.keyPrincipal(principal), Principal.equal);
  };

  public func putBallot<B, A>(
    vote: Vote<B, A>,
    principal: Principal,
    ballot: B,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : Vote<B, A> {
    // Put the ballot in the user's ballots
    let (ballots, removed_ballot) = Trie.put(vote.ballots, Types.keyPrincipal(principal), Principal.equal, ballot);
    // Update the aggregate
    let aggregate = updateAggregate(vote.aggregate, ?ballot, removed_ballot, add_to_aggregate, remove_from_aggregate);
    { vote with ballots; aggregate; };
  };

  public func removeBallot<B, A>(
    vote: Vote<B, A>,
    principal: Principal,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : Vote<B, A> {
    // Remove the ballot from the user's ballots
    let (ballots, removed_ballot) = Trie.remove(vote.ballots, Types.keyPrincipal(principal), Principal.equal);
    // Update the aggregate
    let aggregate = updateAggregate(vote.aggregate, null, removed_ballot, add_to_aggregate, remove_from_aggregate);
    { vote with ballots; aggregate; };
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