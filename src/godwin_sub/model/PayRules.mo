import Types         "Types";
import PayTypes      "token/Types";
import VoteTypes     "votes/Types";
import Polarization  "votes/representation/Polarization";

import Ref           "../utils/Ref";
import WRef          "../utils/wrappers/WRef";

import Trie          "mo:base/Trie";
import Debug         "mo:base/Debug";
import Int           "mo:base/Int";
import Float         "mo:base/Float";
import Text          "mo:base/Text";

module {

  type Ref<K>                    = Ref.Ref<K>;
  type WRef<K>                   = WRef.WRef<K>;

  type PriceParameters           = Types.PriceParameters;
  type Appeal                    = VoteTypes.Appeal;
  type Interest                  = VoteTypes.Interest;
  type CursorMap                 = VoteTypes.CursorMap;
  type Cursor                    = VoteTypes.Cursor;
  type Polarization              = VoteTypes.Polarization;
  type PolarizationMap           = VoteTypes.PolarizationMap;
  type Category                  = VoteTypes.Category;
  type Balance                   = PayTypes.Balance;
  type PayoutArgs                = PayTypes.PayoutArgs;

  func key(c: Category) : Trie.Key<Category> { { hash = Text.hash(c); key = c; } };

  let SIGMOID_COEF         = 10.0;
  let SIGMOID_INTERSECTION = 0.333333333333333333333333333;
  let CONFIDENCE_COEF      = 0.666666666666666666666666666;

  public func build(price_params: Ref<PriceParameters>) : PayRules {
    PayRules(WRef.WRef(price_params));
  };

  public class PayRules(_price_params: WRef<PriceParameters>) {

    public func getOpenVotePrice(): Balance {
      _price_params.get().open_vote_price_e8s;
    };

    public func getInterestVotePrice(): Balance {
      _price_params.get().interest_vote_price_e8s;
    };

    public func getCategorizationVotePrice(): Balance {
      _price_params.get().categorization_vote_price_e8s;
    };

    public func computeOpenVotePayout(result: Appeal, num_voters: Nat) : (Nat, Nat) {
      var payout_args = {
        refund_share = if (result.score >= 0) { 1.0; } else { 0.0; };
        reward_tokens = 0; // @todo: _price_params.open_vote_price if question is selected!
      };
      // If there is no voter, we payout the full amount, otherwise we attenuate the payout
      if (num_voters > 0){
        payout_args := attenuateOrAmplify(payout_args, num_voters);
      };
      (
        Int.abs(Float.toInt(payout_args.refund_share * Float.fromInt(getOpenVotePrice()))),
        payout_args.reward_tokens
      );
    };

    public func computeInterestVotePayout(ballot: Interest, result: Appeal, num_voters: Nat) : PayoutArgs {
      let share = switch(ballot){
        case(#UP){   if (result.score >= 0) { 1.0; } else { 0.0; }; };
        case(#DOWN){ if (result.score <= 0) { 1.0; } else { 0.0; }; };
      };
      
      let payout_args = {
        refund_share = share;
        reward_tokens = Int.abs(Float.toInt(share * Float.fromInt(getInterestVotePrice())));
      };

      attenuateOrAmplify(payout_args, num_voters);
    };

    public func computeCategorizationPayout(ballot: CursorMap, result: PolarizationMap, num_voters: Nat) : PayoutArgs {

      type Payout = { refund: Float; reward: Float; };

      let accumulate_payout = func(category: Category, polarization: Polarization, payout: Payout) : Payout {
        // Compute the cursor weights via the sigmoids
        let cursor_weights = switch(Trie.get(ballot, key(category), Text.equal)){
          case(null) { Polarization.nil(); };
          case(?cursor) { computeCursorWeights(cursor); };
        };
        // Transform the categorization polarization into a cursor
        let categorization_cursor = Polarization.toCursor(polarization);
        // Compute the share of the refund for this category
        let side_coef = categorization_cursor * (if (categorization_cursor >= 0.0) { cursor_weights.right } else { -cursor_weights.left });
        let center_coef = (1.0 - Float.abs(categorization_cursor)) * cursor_weights.center;
        { 
          refund = payout.refund + side_coef + center_coef;
          reward = payout.reward + side_coef;
        };
      };

      let payout = Trie.fold<Category, Polarization, Payout>(result, accumulate_payout, { refund = 0.0; reward = 0.0; });

      if (payout.refund < 0.0){ Debug.trap("Negative refund"); };
      if (payout.reward < 0.0){ Debug.trap("Negative reward"); };

      let payout_args = {
        refund_share = payout.refund;
        reward_tokens = Int.abs(Float.toInt(payout.reward * Float.fromInt(getCategorizationVotePrice())));
      };

      attenuateOrAmplify(payout_args, num_voters);
    };

  };

  // see: https://www.desmos.com/calculator/lnu9rkuxjd
  // @todo: the reward seems bugged: too high or too low
  func attenuateOrAmplify(payout_args: PayoutArgs, num_voters: Nat) : PayoutArgs {
    // It is impossible to attenuate if there is no voter
    if (num_voters == 0){ Debug.trap("Cannot attenuate or amplify the payout: there is 0 voters"); };

    let log_num_voters = Float.log(Float.fromInt(num_voters));
    let result_confidence = 1.0 - Float.exp(-log_num_voters * CONFIDENCE_COEF);
    {
      refund_share = payout_args.refund_share * result_confidence + (1.0 - result_confidence);
      reward_tokens = Int.abs(Float.toInt(Float.fromInt(payout_args.reward_tokens) * result_confidence * log_num_voters));
    };
  };

  // see: https://www.desmos.com/calculator/peuethg7ja
  func computeCursorWeights(user_cursor: Cursor) : Polarization {
    let left   = 1.0 / ( 1 + Float.exp(SIGMOID_COEF * ( user_cursor + SIGMOID_INTERSECTION)));
    let right  = 1.0 / ( 1 + Float.exp(SIGMOID_COEF * (-user_cursor + SIGMOID_INTERSECTION)));
    let center = 1.0 - left - right;
    { left; center; right; };
  };

};
