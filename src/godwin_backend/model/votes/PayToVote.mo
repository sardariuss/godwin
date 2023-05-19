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

  type PayoutRecipient        = PayTypes.PayoutRecipient;

  public class PayToVote<T>(
    _pay_for_element: PayForElement.PayForElement
  ) {

    public func payin(vote_id: VoteId, principal: Principal) : async* Result<(), PutBallotError> {
      switch(await* _pay_for_element.payin(vote_id, principal)){
        case(#err(err)) { #err(#PayinError(err)); };
        case(#ok(tx_index)) { #ok; };
      };
    };

    public func payout(vote_id: VoteId, ballots: Map<Principal, Ballot<T>>) : async* () {
      // Compute the recipients with their share
      let recipients = Buffer.Buffer<PayoutRecipient>(0);
      let number_ballots = Map.size(ballots);
      for ((principal, ballot) in Map.entries(ballots)) {
        recipients.add({ to = principal; share = 1.0 / Float.fromInt(number_ballots); }); // @todo: share
      };
      // Payout the recipients
      await* _pay_for_element.payout(vote_id, recipients);
    };

  };

};