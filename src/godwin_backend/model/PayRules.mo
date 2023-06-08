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

  let SIGMOID_COEF = 10.0;
  let SIGMOID_INTERSECTION = 0.333333333333333333333333333;

  public func build(price_parameters: Ref<PriceParameters>) : PayRules {
    PayRules(WRef.WRef(price_parameters));
  };

  public class PayRules(_price_parameters: WRef<PriceParameters>) {

    public func getOpenVotePrice(): Balance {
      _price_parameters.get().open_vote_price_e8s;
    };

    public func getInterestVotePrice(): Balance {
      _price_parameters.get().interest_vote_price_e8s;
    };

    public func getCategorizationVotePrice(): Balance {
      _price_parameters.get().categorization_vote_price_e8s;
    };

    public func computeOpenVotePayout(appeal: Appeal) : (Nat, ?Nat) {
      (
        if (appeal.score >= 0) { getOpenVotePrice(); } else { 0; },
        ?0 // @todo: _price_parameters.open_vote_price if question is selected!
      );
    };

    public func computeInterestVotePayout(answer: Interest, appeal: Appeal) : PayoutArgs {
      let share = switch(answer){
        case(#UP){   if (appeal.score >= 0) { 1.0; } else { 0.0; }; };
        case(#DOWN){ if (appeal.score <= 0) { 1.0; } else { 0.0; }; };
      };
      {
        refund_share = share;
        reward_tokens = if (share > 0.0) { ?(Int.abs(Float.toInt(share)) * getInterestVotePrice()); } else { null };
      };
    };

    // see: https://www.desmos.com/calculator/peuethg7ja
    public func computeCategorizationPayout(answer: CursorMap, aggregate: PolarizationMap) : PayoutArgs {

      type Payout = { refund: Float; reward: Float; };

      let accumulate_payout = func(category: Category, polarization: Polarization, payout: Payout) : Payout {
        // Compute the cursor weights via the sigmoids
        let cursor_weights = switch(Trie.get(answer, key(category), Text.equal)){
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

      let payout = Trie.fold<Category, Polarization, Payout>(aggregate, accumulate_payout, { refund = 0.0; reward = 0.0; });

      if (payout.refund < 0.0){ Debug.trap("Negative refund"); };
      if (payout.reward < 0.0){ Debug.trap("Negative reward"); };

      {
        refund_share = payout.refund;
        reward_tokens = if (payout.reward == 0.0) { null; } else { ?(Int.abs(Float.toInt(payout.reward)) * getCategorizationVotePrice()); };
      };
    };

  };

  func computeCursorWeights(user_cursor: Cursor) : Polarization {
    let left   = 1.0 / ( 1 + Float.exp(SIGMOID_COEF * ( user_cursor + SIGMOID_INTERSECTION)));
    let right  = 1.0 / ( 1 + Float.exp(SIGMOID_COEF * (-user_cursor + SIGMOID_INTERSECTION)));
    let center = 1.0 - left - right;
    { left; center; right; };
  };

};
