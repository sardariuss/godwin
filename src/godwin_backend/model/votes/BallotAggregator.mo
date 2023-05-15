import Types     "Types";

import Map       "mo:map/Map";

import Principal "mo:base/Principal";
import Option    "mo:base/Option";
import Result    "mo:base/Result";

module {

  // For convenience: from base module
  type Principal       = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Map<K, V>       = Map.Map<K, V>;

  type Ballot<T>       = Types.Ballot<T>;
  type Vote<T, A>      = Types.Vote<T, A>;
  type AddBallotError  = Types.AddBallotError;

  public class BallotAggregator<T, A>(
    _is_valid_answer: (T) -> Bool,
    _add_to_aggregate: (A, T) -> A,
    _remove_from_aggregate: (A, T) -> A
  ) {

    public func putBallot(vote: Vote<T, A>, principal: Principal, ballot: Ballot<T>) : Result<(A, A), AddBallotError> {
      // Verify the vote is not closed
      if (vote.status == #CLOSED){
        return #err(#VoteClosed);
      };
      // Verify the principal is not anonymous
      if (Principal.isAnonymous(principal)){
        return #err(#PrincipalIsAnonymous);
      };
      // Verify the ballot is valid
      if (not _is_valid_answer(ballot.answer)){
        return #err(#InvalidBallot);
      };
      // Update the vote
      let old_ballot = Map.put(vote.ballots, Map.phash, principal, ballot);
      let old_aggregate = vote.aggregate;
      vote.aggregate := updateAggregate(vote.aggregate, ?ballot, old_ballot);
      #ok(old_aggregate, vote.aggregate);
    };

    public func deleteBallot(vote: Vote<T, A>, principal: Principal) {
      // Update the vote
      let old_ballot = Map.remove(vote.ballots, Map.phash, principal);
      Option.iterate(old_ballot, func(ballot: Ballot<T>) {
        vote.aggregate := updateAggregate(vote.aggregate, null, ?ballot);
      });
    };
 
    func updateAggregate(aggregate: A, new_ballot: ?Ballot<T>, old_ballot: ?Ballot<T>) : A {
      var new_aggregate = aggregate;
      // If there is a new ballot, add it to the aggregate
      Option.iterate(new_ballot, func(ballot: Ballot<T>) {
        new_aggregate := _add_to_aggregate(new_aggregate, ballot.answer);
      });
      // If there was an old ballot, remove it from the aggregate
      Option.iterate(old_ballot, func(ballot: Ballot<T>) {
        new_aggregate := _remove_from_aggregate(new_aggregate, ballot.answer);
      });
      new_aggregate;
    };

  };

};