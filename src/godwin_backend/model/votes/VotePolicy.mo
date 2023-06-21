import Types      "Types";

import Map        "mo:map/Map";

import Principal  "mo:base/Principal";
import Result     "mo:base/Result";
import Option     "mo:base/Option";

module {

  // For convenience: from base module
  type Principal                 = Principal.Principal;
  type Result <Ok, Err>          = Result.Result<Ok, Err>;
    
  type Map<K, V>                 = Map.Map<K, V>;

  type VoteId                    = Types.VoteId;
  type Ballot<T>                 = Types.Ballot<T>;
  type Vote<T, A>                = Types.Vote<T, A>;
  type PutBallotError            = Types.PutBallotError;
  type BallotChangeAuthorization = Types.BallotChangeAuthorization;

  public class VotePolicy<T, A>(
    _ballot_change_authorization: BallotChangeAuthorization,
    _is_valid_answer: (T) -> Bool,
    _add_to_aggregate: (A, Ballot<T>) -> A,
    _remove_from_aggregate: (A, Ballot<T>) -> A,
    _empty_aggregate: A
  ) {

    public func canPutBallot(votes: Map<VoteId, Vote<T, A>>, vote_id: VoteId, principal: Principal, ballot: Ballot<T>) : Result<Vote<T, A>, PutBallotError> {
      // Find the vote
      let vote = switch(Map.get(votes, Map.nhash, vote_id)){
        case(null) { return #err(#VoteNotFound); };
        case(?v) { v };
      };
      // Check it is not closed
      switch(vote.status){
        case(#CLOSED(_)) { return #err(#VoteClosed); };
        case(_) {};
      };
      // Verify the principal is not anonymous
      if (Principal.isAnonymous(principal)){
        return #err(#PrincipalIsAnonymous);
      };
      // Verify the ballot is valid
      if (not _is_valid_answer(ballot.answer)){
        return #err(#InvalidBallot);
      };
      // Verify the principal has not already voted
      if (_ballot_change_authorization == #BALLOT_CHANGE_FORBIDDEN and Map.has(vote.ballots, Map.phash, principal)){
        return #err(#ChangeBallotNotAllowed);
      };
      #ok(vote);
    };

    public func emptyAggregate() : A {
      _empty_aggregate;
    };

    public func updateAggregate(aggregate: A, new_ballot: ?Ballot<T>, old_ballot: ?Ballot<T>) : A {
      var new_aggregate = aggregate;
      // If there is a new ballot, add it to the aggregate
      Option.iterate(new_ballot, func(ballot: Ballot<T>) {
        new_aggregate := _add_to_aggregate(new_aggregate, ballot);
      });
      // If there was an old ballot, remove it from the aggregate
      Option.iterate(old_ballot, func(ballot: Ballot<T>) {
        new_aggregate := _remove_from_aggregate(new_aggregate, ballot);
      });
      new_aggregate;
    };

  };

};
