import Types "../../Types";
import Votes "../Votes";
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
  type CloseVoteError = Types.CloseVoteError;
  
  public class CloseVote<T, A>(_votes_: Votes.Votes<T, A>) {

    public func closeVote(id: Nat) : Result<Vote<T, A>, CloseVoteError> {
      _votes_.closeVote(id);
    };

  };

  public class CloseVotePayout<T, A>(
    _votes_: Votes.Votes<T, A>,
    _subaccounts: Map<Nat, Blob>,
    _payout: (Vote<T, A>, Blob) -> ()
  ) {

    public func closeVote(id: Nat) : Result<Vote<T, A>, CloseVoteError> {
      // Get the subaccount
      let subaccount = switch(Map.get(_subaccounts, Map.nhash, id)){
        case(null) { return #err(#VoteNotFound); }; // @todo
        case(?s) { s; };
      };
      // Close the vote
      Result.mapOk<Vote<T, A>, Vote<T, A>, CloseVoteError>(_votes_.closeVote(id), func(vote) {
        // Payout
        _payout(vote, subaccount);
        vote;
      });
    };

  };

};