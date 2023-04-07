import Types "../../Types";
import Votes "../Votes";

import Map "mo:map/Map";

import SubaccountGenerator "../../token/SubaccountGenerator";

import Principal "mo:base/Principal";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Map<K, V> = Map.Map<K, V>;

  type Vote<T, A> = Types.Vote<T, A>;
  type CloseVoteError = Types.CloseVoteError;
  type SubaccountType = SubaccountGenerator.SubaccountType;
  
  public class CloseVote<T, A>(_votes: Votes.Votes<T, A>) {

    public func closeVote(id: Nat) : Result<Vote<T, A>, CloseVoteError> {
      _votes.closeVote(id);
    };

  };

  public class ClosePayableVote<T, A>(
    _votes: Votes.Votes<T, A>,
    _subaccounts: Map<Nat, Blob>,
    _subaccount_type: SubaccountType,
    _payout: (Vote<T, A>, Blob) -> ()
  ) {

    public func closeVote(id: Nat) : Result<Vote<T, A>, CloseVoteError> {
      // Get the subaccount
      let subaccount = switch(Map.get(_subaccounts, Map.nhash, id)){
        case(null) { return #err(#NoSubacountLinked); };
        case(?s) { s; };
      };
      // Close the vote
      Result.mapOk<Vote<T, A>, Vote<T, A>, CloseVoteError>(_votes.closeVote(id), func(vote) {
        // Payout
        _payout(vote, subaccount); // @todo: for opening up the question
        _payout(vote, SubaccountGenerator.getSubaccount(_subaccount_type, id)); // @todo: for the votes
        vote;
      });
    };

  };

  public class CloseRedistributeVote<T, A>(
    _votes: Votes.Votes<T, A>,
    _subaccount_type: SubaccountType,
    _payout: (Vote<T, A>, Blob) -> ()
  ) {

    public func closeVote(id: Nat) : Result<Vote<T, A>, CloseVoteError> {
      // Close the vote
      Result.mapOk<Vote<T, A>, Vote<T, A>, CloseVoteError>(_votes.closeVote(id), func(vote) {
        // Payout
        _payout(vote, SubaccountGenerator.getSubaccount(_subaccount_type, id)); // @todo: for the votes
        vote;
      });
    };

  };

};