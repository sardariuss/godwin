import WMap "../wrappers/WMap";
import Types "../types";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;

  // For convenience
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type WMap3D<K1, K2, K3, V> = WMap.WMap3D<K1, K2, K3, V>;
  type Timestamp<T> = Types.Timestamp<T>;
  type QuestionId = Nat;
  type Iteration = Nat;

  // For every principal, have the ballots in order (BallotKey)
  // Map<Principal, RBT<(Date, QuestionId, Iteration), ()>>
  // What pattern for obs <-> queries ?
  public class Votes<B, A>(
    ballots_: WMap3D<Principal, QuestionId, Iteration, Timestamp<B>>,
    aggregates_: WMap2D<QuestionId, Iteration, Timestamp<A>>,
    empty_aggregate_: A,
    add_to_aggregate_: (A, B) -> A,
    remove_from_aggregate_: (A, B) -> A
  ) {

    public func newAggregate(question_id: QuestionId, iteration: Iteration, date: Time){
      if (Option.isSome(aggregates_.put(question_id, iteration, {elem = empty_aggregate_; date;}))){
        Debug.trap("An aggregate already exist for this question and iteration");
      };
    };

    public func getAggregate(question_id: QuestionId, iteration: Iteration) : ?Timestamp<A> {
      aggregates_.get(question_id, iteration);
    };

    public func getBallot(principal: Principal, question_id: QuestionId, iteration: Iteration) : ?Timestamp<B> {
      ballots_.get(principal, question_id, iteration);
    };

    public func putBallot(principal: Principal, question_id: QuestionId, iteration: Iteration, date: Time, ballot: B) {
      let new_ballot = { elem = ballot; date; };
      // Add the ballot
      let old_ballot = ballots_.put(principal, question_id, iteration, new_ballot);
      // Update the aggregate
      switch(aggregates_.get(question_id, iteration)){
        case(null) { Debug.trap("The aggregate shall exist"); };
        case(?aggregate) {
          ignore aggregates_.put(question_id, iteration, updateAggregate(aggregate, ?new_ballot, old_ballot));
        };
      };
    };

    public func removeBallot(principal: Principal, question_id: QuestionId, iteration: Iteration) {
      // Remove the ballot
      let old_ballot = ballots_.remove(principal, question_id, iteration);
      // Update the aggregate
       switch(aggregates_.get(question_id, iteration)){
        case(null) { Debug.trap("The aggregate shall exist"); };
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