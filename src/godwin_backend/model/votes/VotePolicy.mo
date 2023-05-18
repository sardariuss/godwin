import Types      "Types";
import UtilsTypes "../../utils/Types";
import Utils      "../../utils/Utils";

import Map        "mo:map/Map";
import Set        "mo:map/Set";

import Principal  "mo:base/Principal";
import Result     "mo:base/Result";
import Debug      "mo:base/Debug";
import Nat        "mo:base/Nat";
import Int        "mo:base/Int";
import Option     "mo:base/Option";

module {

  // For convenience: from base module
  type Principal          = Principal.Principal;
  type Result <Ok, Err>   = Result.Result<Ok, Err>;
    
  type Map<K, V>          = Map.Map<K, V>;
  type Set<K>             = Set.Set<K>;

  type ScanLimitResult<T> = UtilsTypes.ScanLimitResult<T>;

  type VoteId             = Types.VoteId;
  type Ballot<T>       = Types.Ballot<T>;
  type Vote<T, A>      = Types.Vote<T, A>;
  type GetVoteError       = Types.GetVoteError;
  type FindBallotError    = Types.FindBallotError;
  type RevealVoteError    = Types.RevealVoteError;
  type PutBallotError     = Types.PutBallotError;
  type RemoveBallotError  = Types.RemoveBallotError;

  public class VotePolicy<T, A>(
    _change_ballot_authorized: Bool,
    _is_valid_answer: (T) -> Bool,
    _add_to_aggregate: (A, T) -> A,
    _remove_from_aggregate: (A, T) -> A,
    _empty_aggregate: A
  ) {

    public func canPutBallot(votes: Map<VoteId, Vote<T, A>>, vote_id: VoteId, principal: Principal, ballot: Ballot<T>) : Result<Vote<T, A>, PutBallotError> {
      // Find the vote
      let vote = switch(Map.get(votes, Map.nhash, vote_id)){
        case(null) { return #err(#VoteNotFound); };
        case(?v) { v };
      };
      // Check it is not closed
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
      // Verify the principal has not already voted
      if (not _change_ballot_authorized and Map.has(vote.ballots, Map.phash, principal)){
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
