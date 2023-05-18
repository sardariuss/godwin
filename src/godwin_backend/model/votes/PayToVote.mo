import Types               "Types";

import Votes               "Votes";
import BallotAggregator    "BallotAggregator";

import SubaccountGenerator "../token/SubaccountGenerator";
import PayForNew           "../token/PayForNew";
import PayInterface        "../token/PayInterface";
import PayTypes            "../token/Types";

import WRef                "../../utils/wrappers/WRef";
import Ref                 "../../utils/Ref";

import Map                 "mo:map/Map";
import Set                 "mo:map/Set";

import Principal           "mo:base/Principal";
import Result              "mo:base/Result";
import Buffer              "mo:base/Buffer";
import Float               "mo:base/Float";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";

module {

  // For convenience: from base module
  type Principal        = Principal.Principal;
  type Result<Ok, Err>  = Result.Result<Ok, Err>;

  type Map<K, V>        = Map.Map<K, V>;
  type Set<K>           = Set.Set<K>;
  
  type Ref<T>           = Ref.Ref<T>;
  type WRef<T>          = WRef.WRef<T>;

  type VoteId           = Types.VoteId;
  type Vote<T, A>       = Types.Vote<T, A>;
  type OpenVoteError    = Types.OpenVoteError;
  type PutBallotError   = Types.PutBallotError;
  type Ballot<T>        = Types.Ballot<T>;
  type GetVoteError     = Types.GetVoteError;
  type FindBallotError  = Types.FindBallotError;
  type RevealVoteError  = Types.RevealVoteError;
  type BallotTransactions = Types.BallotTransactions;
  type UpdateAggregate<T, A> = Types.UpdateAggregate<T, A>;
  
  type Balance          = PayTypes.Balance;
  type SubaccountPrefix = PayTypes.SubaccountPrefix;
  type PayinError       = PayTypes.PayinError;
  type SinglePayoutRecipient  = PayTypes.SinglePayoutRecipient;
  type PayoutError        = PayTypes.PayoutError;
  type SinglePayoutResult = PayTypes.SinglePayoutResult;

  type PayInterface     = PayInterface.PayInterface;
  type PayForNew        = PayForNew.PayForNew;

  public class PayToVote<T, A>(
    _votes: Votes.Votes<T, A>,
    _ballot_infos: Map<Principal, Map<VoteId, BallotTransactions>>,
    _update_aggregate: UpdateAggregate<T, A>,
    _pay_interface: PayInterface,
    _put_ballot_subaccount_prefix: SubaccountPrefix
  ) {

    public func payout(vote_id: VoteId) : async* () {

      // Compute the recipients with their share
      let recipients = Buffer.Buffer<SinglePayoutRecipient>(0);
      let vote = _votes.getVote(vote_id);
      let number_ballots = Map.size(vote.ballots);
      for ((principal, ballot) in Map.entries(vote.ballots)) {
        recipients.add({ to = principal; share = 1.0 / Float.fromInt(number_ballots); }); // @todo: share
      };

      // Payout the recipients
      let results = Map.new<Principal, SinglePayoutResult>(Map.phash);
      await* _pay_interface.batchPayout(SubaccountGenerator.getSubaccount(_put_ballot_subaccount_prefix, vote_id), recipients, results);
      
      // Add the payout to the ballot transactions
      for ((principal, result) in Map.entries(results)) {
        var transactions = getBallotTransactions(principal, vote_id);
        transactions := { transactions with payout = #PROCESSED({ refund = ?result; reward = null; }) }; // @todo: add the reward
        setBallotTransactions(principal, vote_id, transactions);
      };

    };

    public func putBallot(principal: Principal, vote_id: VoteId, ballot: Ballot<T>, price: Balance) : async* Result<(), PutBallotError> {
      
      let vote = _votes.getVote(vote_id);

      // Check if the principal has already voted
      if (Map.has(vote.ballots, Map.phash, principal)){
        return #err(#AlreadyVoted);
      };

      // Put the ballot before the payin to protect from reentry
      // Do not update the aggregate yet
      switch(_votes.putBallot(principal, vote_id, ballot, func(a: A, new: ?Ballot<T>, old: ?Ballot<T>) : A { a; })){
        case(#err(err)) { return #err(err); };
        case(#ok(_)) {};
      };

      // Pay
      switch(await* _pay_interface.payin(SubaccountGenerator.getSubaccount(_put_ballot_subaccount_prefix, vote_id), principal, price)){ // @todo: price
        case(#err(err)) {
          // Rollback put ballot on failure
          Map.delete(vote.ballots, Map.phash, principal);
          #err(#PayinError(err));
        };
        case(#ok(tx_index)) { 
          // Update the aggregate
          vote.aggregate := _update_aggregate(vote.aggregate, ?ballot, null);
          // Update the ballot infos
          setBallotTransactions(principal, vote_id, { payin = tx_index; payout = #PENDING; });
          #ok;
        };
      };
    };

    func getBallotInfos(principal: Principal) : Map<VoteId, BallotTransactions> {
      Option.get(Map.get(_ballot_infos, Map.phash, principal), Map.new<VoteId, BallotTransactions>(Map.nhash));
    };

    func setBallotTransactions(principal: Principal, vote_id: VoteId, transactions: BallotTransactions) {
      let voter_ballot_infos = getBallotInfos(principal);
      Map.set(voter_ballot_infos, Map.nhash, vote_id, transactions);
    };

    func getBallotTransactions(principal: Principal, vote_id: VoteId) : BallotTransactions {
      switch(Map.get(getBallotInfos(principal), Map.nhash, vote_id)){
        case(null) { Debug.trap("@todo"); };
        case(?transactions) { transactions; };
      };
    };

    // From the votes module

    public func newVote() : VoteId {
      _votes.newVote();
    };

    public func closeVote(id: VoteId) {
      _votes.closeVote(id);
    };

    public func findVote(id: VoteId) : Result<Vote<T, A>, GetVoteError> {
      _votes.findVote(id);
    };

    public func getVote(id: VoteId) : Vote<T, A> {
      _votes.getVote(id);
    };

    public func getBallot(principal: Principal, vote_id: VoteId) : Ballot<T> {
      _votes.getBallot(principal, vote_id);
    };

    public func findBallot(principal: Principal, vote_id: VoteId) : Result<Ballot<T>, FindBallotError> {
      _votes.findBallot(principal, vote_id);
    };

    public func revealVote(id: VoteId) : Result<Vote<T, A>, RevealVoteError> {
      _votes.revealVote(id);
    };

    public func getVoterHistory(principal: Principal) : Set<VoteId> {
      _votes.getVoterHistory(principal);
    };

  };

};