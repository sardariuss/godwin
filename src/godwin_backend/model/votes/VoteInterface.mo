import Types "../Types";
import Votes "Votes";
import BallotAggregator "BallotAggregator";

import SubaccountGenerator "../token/SubaccountGenerator";

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
  type SubaccountType = SubaccountGenerator.SubaccountType;
  
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
    _subaccount_type: SubaccountType,
    _payin: (Principal, Blob) -> async* Result<(), Text>
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
      switch(await* _payin(principal, SubaccountGenerator.getSubaccount(_subaccount_type, vote_id))){
        case(#err(err)) {
          // Rollback put ballot on failure
          _ballot_aggregator.deleteBallot(vote, principal);
          #err(#PayinError(err)); 
        };
        case(#ok(_)) { 
          // Notify observers on success
          _votes.notifyObs(vote.id, ?old_aggregate, ?vote.aggregate);
          #ok; 
        };
      };
    };

  };

};