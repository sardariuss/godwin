import Types "../../Types";
import Votes2 "../Votes2";
import BallotAggregator "../BallotAggregator";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Result "mo:base/Result";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Map<K, V> = Map.Map<K, V>;

  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type BallotAggregator<T, A> = BallotAggregator.BallotAggregator<T, A>;
  type GetVoteError = Types.GetVoteError;
  type GetBallotError = Types.GetBallotError;
  type PutBallotError = Types.PutBallotError;
  
  public class PutBallot<T, A>(
    votes_: Votes2.Votes2<T, A>,
    ballot_aggregator_: BallotAggregator<T, A>
  ) {

     public func putBallot(principal: Principal, id: Nat, ballot: Ballot<T>) : Result<(), PutBallotError> {
      // Get the vote
      let vote = switch(votes_.findVote(id)){
        case(null) { return #err(#VoteNotFound); };
        case(?vote) { vote; };
      };
      // Put the ballot
      Result.mapOk<(A, A), (), PutBallotError>(ballot_aggregator_.putBallot(vote, principal, ballot), func((old_aggregate, new_aggregate)) {
        votes_.notifyObs(vote.id, ?old_aggregate, ?vote.aggregate);
      });
    };

  };

  public class PutBallotPayin<T, A>(
    votes_: Votes2.Votes2<T, A>,
    ballot_aggregator_: BallotAggregator<T, A>,
    subaccounts_: Map<Nat, Blob>,
    payin_: (Principal, Blob) -> async Result<(), ()>
  ) {

    public func putBallot(principal: Principal, id: Nat, ballot: Ballot<T>) : async Result<(), PutBallotError> {
      // Get the vote
      let vote = switch(votes_.findVote(id)){
        case(null) { return #err(#VoteNotFound); };
        case(?vote) { vote; };
      };
      // Put a FRESH ballot before paying (required to protect from reentry attack)
      let (old_aggregate, new_aggregate) = switch(ballot_aggregator_.putFreshBallot(vote, principal, ballot)){
        case(#err(err)) { return #err(err); };
        case(#ok((old, new))) { (old, new); };
      };
      // Pay
      let result = switch(Map.get(subaccounts_, Map.nhash, id)) {
        case(null) { #err(#VoteNotFound); }; // @todo
        case(?subaccount) {
          switch(await payin_(principal, subaccount)){
            case(#err(_)) { #err(#VoteNotFound); }; // @todo
            case(#ok(_)) { #ok; };
          };
        };
      };
      // Notify observers on success, rollback on failure
      switch(result) {
        case(#ok(_)) {
          votes_.notifyObs(vote.id, ?old_aggregate, ?vote.aggregate);
        };
        case(#err(_)) {
          ballot_aggregator_.deleteBallot(vote, principal);
        };
      };
      // Return the result
      result;
    };

  };

};