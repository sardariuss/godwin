import Types               "Types";
import BallotInfos         "BallotInfos";

import SubaccountGenerator "../token/SubaccountGenerator";
import PayInterface        "../token/PayInterface";
import PayTypes            "../token/Types";

import Map                 "mo:map/Map";

import Principal           "mo:base/Principal";
import Result              "mo:base/Result";
import Buffer              "mo:base/Buffer";
import Float               "mo:base/Float";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal              = Principal.Principal;
  type Result<Ok, Err>        = Result.Result<Ok, Err>;

  type Map<K, V>              = Map.Map<K, V>;

  type VoteId                 = Types.VoteId;
  type PutBallotError         = Types.PutBallotError;
  type Ballot<T>              = Types.Ballot<T>;
  type GetVoteError           = Types.GetVoteError;
  type FindBallotError        = Types.FindBallotError;
  type RevealVoteError        = Types.RevealVoteError;
  type BallotTransactions     = Types.BallotTransactions;
  
  type SubaccountPrefix       = PayTypes.SubaccountPrefix;
  type PayinError             = PayTypes.PayinError;
  type SinglePayoutRecipient  = PayTypes.SinglePayoutRecipient;
  type PayoutError            = PayTypes.PayoutError;
  type SinglePayoutResult     = PayTypes.SinglePayoutResult;

  type PayInterface           = PayInterface.PayInterface;
  type BallotInfos            = BallotInfos.BallotInfos;

  public class PayToVote<T>(
    _ballot_infos: BallotInfos,
    _pay_interface: PayInterface,
    _put_ballot_subaccount_prefix: SubaccountPrefix,
    _pay_in_price: Nat
  ) {

    public func payout(vote_id: VoteId, ballots: Map<Principal, Ballot<T>>) : async* () {

      // Compute the recipients with their share
      let recipients = Buffer.Buffer<SinglePayoutRecipient>(0);
      let number_ballots = Map.size(ballots);
      for ((principal, ballot) in Map.entries(ballots)) {
        recipients.add({ to = principal; share = 1.0 / Float.fromInt(number_ballots); }); // @todo: share
      };

      // Payout the recipients
      let results = Map.new<Principal, SinglePayoutResult>(Map.phash);
      await* _pay_interface.batchPayout(SubaccountGenerator.getSubaccount(_put_ballot_subaccount_prefix, vote_id), recipients, results);
      
      // Add the payout to the ballot transactions
      for ((principal, result) in Map.entries(results)) {
        var transactions = _ballot_infos.getBallotTransactions(principal, vote_id);
        transactions := { transactions with payout = #PROCESSED({ refund = ?result; reward = null; }) }; // @todo: add the reward
        _ballot_infos.setBallotTransactions(principal, vote_id, transactions);
      };

    };

    public func payin(vote_id: VoteId, principal: Principal) : async* Result<(), PutBallotError> {

      switch(await* _pay_interface.payin(SubaccountGenerator.getSubaccount(_put_ballot_subaccount_prefix, vote_id), principal, _pay_in_price)){
        case(#err(err)) {
          #err(#PayinError(err));
        };
        case(#ok(tx_index)) { 
          // Update the ballot infos
          _ballot_infos.setBallotTransactions(principal, vote_id, { payin = tx_index; payout = #PENDING; });
          #ok;
        };
      };
    };

  };

};