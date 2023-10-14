import Types        "Types";

import PayRules      "../PayRules";
import PayForElement "../token/PayForElement";
import PayTypes      "../token/Types";

import Map          "mo:map/Map";

import Principal    "mo:base/Principal";
import Result       "mo:base/Result";
import Buffer       "mo:base/Buffer";
import Float        "mo:base/Float";

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
  type RawPayout              = PayTypes.RawPayout;
  type PayoutArgs             = PayTypes.PayoutArgs;
  type TransactionsRecord     = PayTypes.TransactionsRecord;
  type Balance                = PayTypes.Balance;

  public type PayoutFunction<T, A> = (T, A) -> RawPayout;

  public class PayToVote<T, A>(
    _pay_for_element: PayForElement.PayForElement,
    _get_payin_price: () -> Balance,
    _get_reward_coef: () -> Float,
    _compute_payout: PayoutFunction<T, A>
  ) {

    public func payin(vote_id: VoteId, principal: Principal) : async* Result<(), PutBallotError> {
      switch(await* _pay_for_element.payin(vote_id, principal, _get_payin_price())){
        case(#err(err)) { #err(#PayinError(err)); };
        case(#ok(tx_index)) { #ok; };
      };
    };

    public func payout(vote: Vote<T, A>) : async* () {

      let number_voters = Map.size(vote.ballots);
      if (number_voters == 0) {
        return;
      };

      // Compute the raw payouts and accumulate the sum of shares
      // WATCHOUT, it seems that there is a bug with Map.map that replaces 
      // the principals to anonymous principals, use a loop instead
      var sum_shares = 0.0;
      let raw_payouts = Map.new<Principal, RawPayout>(Map.phash);
      for ((principal, ballot) in Map.entries(vote.ballots)){
        let raw_payout = _compute_payout(ballot.answer, vote.aggregate);
        sum_shares += raw_payout.refund_share;
        Map.set(raw_payouts, Map.phash, principal, raw_payout);
      };

      let recipients = Map.new<Principal, PayoutRecipient>(Map.phash);
      for ((principal, raw_payout) in Map.entries(raw_payouts)){
        // Normalize the refund shares, so that the sum of shares makes 1
        let normalized_payout = { raw_payout with refund_share = raw_payout.refund_share / sum_shares; };
        // Convert the reward in tokens
        let payout_args = { normalized_payout with reward_tokens = PayRules.convertRewardToTokens(normalized_payout.reward, _get_payin_price(), _get_reward_coef()); };
        // Return the full recipient (required by the payout function)
        Map.set(recipients, Map.phash, principal, { to = principal; args = payout_args; });
      };

      // Payout the recipients
      await* _pay_for_element.payout(vote.id, Map.vals(recipients));
    };

    public func findTransactionsRecord(principal: Principal, id: VoteId) : ?TransactionsRecord {
      _pay_for_element.findTransactionsRecord(principal, id);
    };

  };

};