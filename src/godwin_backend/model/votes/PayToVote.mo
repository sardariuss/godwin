import Types               "Types";

import PayForElement        "../token/PayForElement";
import PayTypes             "../token/Types";

import Map                 "mo:map/Map";

import Principal           "mo:base/Principal";
import Result              "mo:base/Result";
import Buffer              "mo:base/Buffer";
import Float               "mo:base/Float";

module {

  // For convenience: from base module
  type Principal              = Principal.Principal;
  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Map<K, V>              = Map.Map<K, V>;

  type VoteId                 = Types.VoteId;
  type PutBallotError         = Types.PutBallotError;
  type Ballot<T>              = Types.Ballot<T>;
  type Vote<T, A>             = Types.Vote<T, A>;

  type PayoutRecipient        = PayTypes.PayoutRecipient;
  type PayoutArgs             = PayTypes.PayoutArgs;
  type TransactionsRecord     = PayTypes.TransactionsRecord;
  type Balance                = PayTypes.Balance;

  public class PayToVote<T, A>(
    _pay_for_element: PayForElement.PayForElement,
    _payin_price: Balance,
    _compute_payout: (T, A) -> PayoutArgs
  ) {

    public func payin(vote_id: VoteId, principal: Principal) : async* Result<(), PutBallotError> {
      switch(await* _pay_for_element.payin(vote_id, principal, _payin_price)){
        case(#err(err)) { #err(#PayinError(err)); };
        case(#ok(tx_index)) { #ok; };
      };
    };

    public func payout(vote: Vote<T, A>) : async* () {
      // Compute the recipients with their share
      let recipients = Buffer.Buffer<PayoutRecipient>(0);
      let number_ballots = Map.size(vote.ballots);
      for ((principal, ballot) in Map.entries(vote.ballots)) {
        recipients.add({ to = principal; args = _compute_payout(ballot.answer, vote.aggregate); });
      };
      // Payout the recipients
      await* _pay_for_element.payout(vote.id, recipients);
    };

    public func findTransactionsRecord(principal: Principal, id: VoteId) : ?TransactionsRecord {
      _pay_for_element.findTransactionsRecord(principal, id);
    };

  };

};