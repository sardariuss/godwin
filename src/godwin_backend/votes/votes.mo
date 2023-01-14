import WrappedRef "../ref/wrappedRef";
import TrieRef "../ref/trieRef";
import Types "../types";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie2D<K1, K2, V> = Trie.Trie2D<K1, K2, V>;
  type Trie3D<K1, K2, K3, V> = Trie.Trie3D<K1, K2, K3, V>;
  type Principal = Principal.Principal;
  type Time = Int;

  // For convenience
  type WrappedRef<T> = WrappedRef.WrappedRef<T>;
  type QuestionId = Nat32;
  type Iteration = Nat;

  public type Timestamp<T> = {
    elem: T;
    date: Time;
  };

  public class Votes<B, A>(
    ballots: WrappedRef<Trie3D<Principal, QuestionId, Iteration, Timestamp<B>>>,
    aggregates: WrappedRef<Trie2D<QuestionId, Iteration, Timestamp<A>>>,
    new_aggregate: () -> A,
    add_to_aggregate_: (A, B) -> A,
    remove_from_aggregate_: (A, B) -> A
  ) {

    let ballots_ = TrieRef.Trie3DRef<Principal, QuestionId, Iteration, Timestamp<B>>(
      ballots, Types.keyPrincipal, Principal.equal, Types.keyNat32, Nat32.equal, Types.keyNat, Nat.equal);

    let aggregates_ = TrieRef.Trie2DRef<QuestionId, Iteration, Timestamp<A>>(
      aggregates, Types.keyNat32, Nat32.equal, Types.keyNat, Nat.equal);

    public func newVote(question_id: QuestionId, iteration: Iteration, date: Int){
      if (Option.isSome(aggregates_.put(question_id, iteration, {elem = new_aggregate(); date;}))){
        Debug.trap("A vote already exist for this question and iteration");
      };
    };

    public func getBallot(principal: Principal, question_id: QuestionId, iteration: Iteration) : ?Timestamp<B> {
      ballots_.get(principal, question_id, iteration);
    };

    public func putBallot(principal: Principal, question_id: QuestionId, iteration: Iteration, ballot: Timestamp<B>) {
      // Add the ballot
      let old_ballot = ballots_.put(principal, question_id, iteration, ballot);
      // Update the aggregate
      switch(aggregates_.get(question_id, iteration)){
        case(null) { Debug.trap("The vote shall exist"); };
        case(?aggregate) {
          ignore aggregates_.put(question_id, iteration, updateAggregate(aggregate, ?ballot, old_ballot));
        };
      };
    };

    public func removeBallot(principal: Principal, question_id: QuestionId, iteration: Iteration) {
      // Remove the ballot
      let old_ballot = ballots_.remove(principal, question_id, iteration);
      // Update the aggregate
       switch(aggregates_.get(question_id, iteration)){
        case(null) { Debug.trap("The vote shall exist"); };
        case(?aggregate) {
          ignore aggregates_.put(question_id, iteration, updateAggregate(aggregate, null, old_ballot));
        };
      };
    };

    func updateAggregate(aggregate: Timestamp<A>, new_ballot: ?Timestamp<B>, old_ballot: ?Timestamp<B>) : Timestamp<A> {
      var new_aggregate = aggregate.elem;
      // If there is a new ballot, add it to the aggregate
      Option.iterate(new_ballot, func(ballot: Timestamp<B>) {
        new_aggregate := add_to_aggregate_(new_aggregate, ballot.elem);
      });
      // If there was an old ballot, remove it from the aggregate
      Option.iterate(old_ballot, func(ballot: Timestamp<B>) {
        new_aggregate := remove_from_aggregate_(new_aggregate, ballot.elem);
      });
      {
        elem = new_aggregate;
        date = aggregate.date;
      };
    };

  };

};