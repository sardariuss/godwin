import Types "../Types";
import Votes "Votes";
import BallotAggregator "BallotAggregator";

import SubaccountGenerator "../token/SubaccountGenerator";
import PayForNew "../token/PayForNew";
import PayInterface "../token/PayInterface";

import WRef "../../utils/wrappers/WRef";
import Ref "../../utils/Ref";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Map<K, V> = Map.Map<K, V>;
  
  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;

  type SubaccountType = SubaccountGenerator.SubaccountType;

  type Vote<T, A> = Types.Vote<T, A>;
  type OpenVoteError = Types.OpenVoteError;
  type PayInterface = PayInterface.PayInterface;
  type PayForNew = PayForNew.PayForNew;
  type PayInError = PayInterface.PayInError;
  type PayoutRecipient = PayInterface.PayoutRecipient;
  type PayoutError = PayInterface.PayoutError;
  type PutBallotError = Types.PutBallotError;
  type Ballot<T> = Types.Ballot<T>;
  type GetVoteError = Types.GetVoteError;
  type GetBallotError = Types.GetBallotError;

  public class PayToVote<T, A>(
    _votes: Votes.Votes<T, A>,
    _ballot_aggregator: BallotAggregator.BallotAggregator<T, A>,
    _pay_interface: PayInterface,
    _put_ballot_subaccount_type: SubaccountType
  ) {

    public func payout(vote_id: Nat) : async* () {
      let recipients = Buffer.Buffer<PayoutRecipient>(0);
      let vote = _votes.getVote(vote_id);
      for ((principal, ballot) in Map.entries(vote.ballots)) {
        recipients.add({ to = principal; share = 1.0 / Float.fromInt(Map.size(vote.ballots)); }); // @todo: share
      };
      ignore (await* _pay_interface.payOut(SubaccountGenerator.getSubaccount(_put_ballot_subaccount_type, vote_id), recipients));
    };

    public func putBallot(principal: Principal, vote_id: Nat, ballot: Ballot<T>) : async* Result<(), PutBallotError> {
      
      let vote = _votes.getVote(vote_id);

      // Check if the principal has already voted (required to protect from reentry attack)
      if (Map.has(vote.ballots, Map.phash, principal)){
        return #err(#AlreadyVoted);
      };

      // Put the ballot
      let (old_aggregate, new_aggregate) = switch(_ballot_aggregator.putBallot(vote, principal, ballot)){
        case(#err(err)) { return #err(err); };
        case(#ok((old, new))) { (old, new); };
      };

      // Pay
      switch(await* _pay_interface.payIn(SubaccountGenerator.getSubaccount(_put_ballot_subaccount_type, vote_id), principal, 1000)){ // @todo: price
        case(#err(err)) {
          // Rollback put ballot on failure
          _ballot_aggregator.deleteBallot(vote, principal);
          #err(#PayinError(err)); 
        };
        case(#ok(_)) { 
          // Notify observers on success
          //_votes.notifyObs(vote.id, ?old_aggregate, ?new_aggregate); // @todo
          #ok;
        };
      };
    };

    // From the votes module

    public func newVote() : Nat {
      _votes.newVote();
    };

    public func findVote(id: Nat) : Result<Vote<T, A>, GetVoteError> {
      _votes.findVote(id);
    };

    public func getVote(id: Nat) : Vote<T, A> {
      _votes.getVote(id);
    };

    public func getBallot(principal: Principal, id: Nat) : Result<Ballot<T>, GetBallotError> {
      _votes.getBallot(principal, id);
    };

  };

};