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
  type CloseVoteError = Types.CloseVoteError;
  
  public class CloseVote<T, A>(votes_: Votes2.Votes2<T, A>) {

    public func closeVote(id: Nat) : Result<(), CloseVoteError> {
      Result.mapOk<Vote<T, A>, (), CloseVoteError>(votes_.closeVote(id), func(_) {});
    };

  };

  public class CloseVotePayout<T, A>(
    votes_: Votes2.Votes2<T, A>,
    subaccounts_: Map<Nat, Blob>,
    payout_: (Vote<T, A>, Blob) -> ()
  ) {

    public func closeVote(id: Nat) : Result<(), CloseVoteError> {
      // Get the subaccount
      let subaccount = switch(Map.get(subaccounts_, Map.nhash, id)){
        case(null) { return #err(#VoteNotFound); }; // @todo
        case(?s) { s; };
      };
      // Close the vote
      Result.mapOk<Vote<T, A>, (), CloseVoteError>(votes_.closeVote(id), func(vote) {
        // Payout
        payout_(vote, subaccount);
      });
    };

  };

};