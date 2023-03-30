import Types "../../Types";
import Votes "../Votes";
import BallotAggregator "../BallotAggregator";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Map<K, V> = Map.Map<K, V>;

  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type BallotAggregator<T, A> = BallotAggregator.BallotAggregator<T, A>;
  type PutBallotError = Types.PutBallotError;
  
  public class PutBallot<T, A>(
    _votes: Votes.Votes<T, A>,
    _ballot_aggregator: BallotAggregator<T, A>
  ) {

     public func putBallot(principal: Principal, vote_id: Nat, ballot: Ballot<T>) : Result<(), PutBallotError> {
      // Get the vote
      let vote = switch(_votes.findVote(vote_id)){
        case(null) { return #err(#VoteNotFound); };
        case(?vote) { vote; };
      };
      // Put the ballot
      Result.mapOk<(A, A), (), PutBallotError>(_ballot_aggregator.addBallot(vote, principal, ballot), func((old_aggregate, new_aggregate)) {
        _votes.notifyObs(vote.id, ?old_aggregate, ?vote.aggregate);
      });
    };

  };

  public class PutBallotPayin<T, A>(
    _votes: Votes.Votes<T, A>,
    _ballot_aggregator: BallotAggregator<T, A>,
    _subaccounts: Map<Nat, Blob>,
    _payin: (Principal, Blob) -> async* Result<(), ()>
  ) {

    public func putBallot(principal: Principal, vote_id: Nat, ballot: Ballot<T>) : async* Result<(), PutBallotError> {
      // Get the vote
      let vote = switch(_votes.findVote(vote_id)){
        case(null) { return #err(#VoteNotFound); };
        case(?vote) { vote; };
      };
      // Check if the principal has already voted (required to protect from reentry attack)
      if (Map.has(vote.ballots, Map.phash, principal)){
        return #err(#AlreadyVoted);
      };
      // Put the ballot
      let (old_aggregate, new_aggregate) = switch(_ballot_aggregator.addBallot(vote, principal, ballot)){
        case(#err(err)) { return #err(err); };
        case(#ok((old, new))) { (old, new); };
      };
      // Pay
      let result = switch(Map.get(_subaccounts, Map.nhash, vote_id)) {
        case(null) { #err(#NoSubacountLinked); };
        case(?subaccount) {
          switch(await* _payin(principal, subaccount)){
            case(#err(_)) { #err(#PayinError); };
            case(#ok(_)) { #ok; };
          };
        };
      };
      // Notify observers on success, rollback on failure
      switch(result) {
        case(#ok(_)) {
          _votes.notifyObs(vote.id, ?old_aggregate, ?vote.aggregate);
        };
        case(#err(_)) {
          _ballot_aggregator.deleteBallot(vote, principal);
        };
      };
      // Return the result
      result;
    };

  };

};