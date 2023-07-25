import Types         "Types";
import PayTypes      "token/Types";
import VoteTypes     "votes/Types";
import Polarization  "votes/representation/Polarization";

import Ref           "../utils/Ref";
import WRef          "../utils/wrappers/WRef";
import Math          "../utils/Math";

import Trie          "mo:base/Trie";
import Debug         "mo:base/Debug";
import Int           "mo:base/Int";
import Float         "mo:base/Float";
import Text          "mo:base/Text";

module {

  type Ref<K>              = Ref.Ref<K>;
  type WRef<K>             = WRef.WRef<K>;

  type PriceParameters     = Types.PriceParameters;
  type Appeal              = VoteTypes.Appeal;
  type Interest            = VoteTypes.Interest;
  type CursorMap           = VoteTypes.CursorMap;
  type Cursor              = VoteTypes.Cursor;
  type Polarization        = VoteTypes.Polarization;
  type PolarizationMap     = VoteTypes.PolarizationMap;
  type Category            = VoteTypes.Category;
  type InterestVoteClosure = VoteTypes.InterestVoteClosure;
  type Balance             = PayTypes.Balance;
  type PayoutArgs          = PayTypes.PayoutArgs;
  
  type Payout              = { refund: Float; reward: Float; };

  func key(c: Category) : Trie.Key<Category> { { hash = Text.hash(c); key = c; } };

  func nullPayout() : Payout { { refund = 0.0; reward = 0.0; }; };
  func sumPayouts(x: Payout, y: Payout) : Payout { { refund = x.refund + y.refund; reward = x.reward + y.reward; }; };

  let INTEREST_PAYOUT_PARAMS = {
    REWARD_PARAMS ={
      LOGIT_NORMAL_PDF_PARAMS = {
        sigma = 0.8;
        mu    = 0.0;
      };
      COEF = 0.5;
    };
  };

  let CATEGORIZATION_PAYOUT_PARAMS = {
    SIDE_CONTRIBUTION_LIMIT =  0.333333333333333333333333333;
    LOGIT_NORMAL_CDF_PARAMS = {
      sigma = 0.8;
      mu    = 0.0;
    };
  };

  let ATTENUATE_MODIFIER_PARAMS = {
    coef     = 0.5; // The greater, the less number of voters it takes to fully apply the payout rules
    exponent = 2.5; // The greater, the more the payout rules are attenuated for small number of voters
  };

  public func build(price_params: Ref<PriceParameters>) : PayRules {
    PayRules(WRef.WRef(price_params));
  };

  type InterestDistribution = {
    shares: {
      up:   Float;
      down: Float;
    };
    reward_ratio: Float;
  };

  // see www.desmos.com/calculator/lhubb03yud
  public func computeInterestDistribution(appeal: Appeal) : InterestDistribution {
    let { ups; downs; } = appeal;

    let loosers = Float.fromInt(if (ups >= downs){ downs; } else { ups;   });
    let winners = Float.fromInt(if (ups >= downs){ ups;   } else { downs; });

    let looser_share = loosers / winners;
    let winner_share = 1.0 + (1.0 - looser_share) * looser_share;

    let shares = {
      up   = if (ups >= downs){ winner_share; } else { looser_share; };
      down = if (ups >= downs){ looser_share; } else { winner_share; };
    };

    let { LOGIT_NORMAL_PDF_PARAMS; COEF; } = INTEREST_PAYOUT_PARAMS.REWARD_PARAMS;

    let reward_ratio = COEF * Math.logitNormalPDF(loosers / (winners + loosers), LOGIT_NORMAL_PDF_PARAMS, null);

    { shares; reward_ratio; };
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

    // see www.desmos.com/calculator/xcvnh9oxrq
    public func computeAuthorPayout(appeal: Appeal, closure: InterestVoteClosure) : PayoutArgs {

      let num_voters = appeal.ups + appeal.downs;

      // If there is no voter, refund the full amount, no reward
      if (num_voters == 0){
        return { refund_share = 1.0; reward_tokens = 0; };
      };

      let payout_args = {
        // Refund the full amount if the vote has not been censored
        refund_share  = if (closure == #CENSORED){ 0.0; } else { 1.0 };
        // If the question has been selected, reward the price it took to open the question
        // multiplied by the square root of the score
        reward_tokens = if (closure != #SELECTED){ 0; } else {
          Int.abs(Float.toInt((Float.sqrt(appeal.score) - 1) * Float.fromInt(getOpenVotePrice())));
        };
      };
     
      attenuatePayout(payout_args, num_voters);
    };

    public func computeInterestVotePayout(distribution: InterestDistribution, num_voters: Nat, ballot: Interest) : PayoutArgs {
      
      if (num_voters == 0){
        Debug.trap("It is impossible to payout voters if there is no voter");
      };

      let { shares; reward_ratio; } = distribution;
     
      let payout_args = {
        refund_share  = switch(ballot){ case(#UP) shares.up; case(#DOWN) shares.down; };
        reward_tokens = Int.abs(Float.toInt(reward_ratio * Float.fromInt(getInterestVotePrice())));
      };

      attenuatePayout(payout_args, num_voters);
    };

    public func computeCategorizationPayout(ballot: CursorMap, result: PolarizationMap, num_voters: Nat) : PayoutArgs {

      let accumulate_payout = func(category: Category, result: Polarization, payout: Payout) : Payout {
        sumPayouts(payout, switch(Trie.get(ballot, key(category), Text.equal)){
          case(null) { nullPayout(); };
          case(?answer) { computeCategoryShare(answer, Polarization.toCursor(result)); };
        });
      };

      let payout = Trie.fold<Category, Polarization, Payout>(result, accumulate_payout, nullPayout());

      if (payout.refund < 0.0){ Debug.trap("Negative refund"); };
      if (payout.reward < 0.0){ Debug.trap("Negative reward"); };

      let payout_args = {
        refund_share = payout.refund;
        reward_tokens = Int.abs(Float.toInt(payout.reward * Float.fromInt(getCategorizationVotePrice())));
      };

      attenuatePayout(payout_args, num_voters);
    };

  };

  // see www.desmos.com/calculator/voiqqttaog
  func computeCategoryShare(answer: Cursor, result: Cursor) : Payout {

    let { SIDE_CONTRIBUTION_LIMIT; LOGIT_NORMAL_CDF_PARAMS; } = CATEGORIZATION_PAYOUT_PARAMS;

    let left  = if (answer >  SIDE_CONTRIBUTION_LIMIT ) { 0.0; } else {
      Math.logitNormalCDF(answer, LOGIT_NORMAL_CDF_PARAMS, ?{ k = -1.0; l = SIDE_CONTRIBUTION_LIMIT; });
    };
    let right = if (answer < -SIDE_CONTRIBUTION_LIMIT)  { 0.0; } else {
      Math.logitNormalCDF(answer, LOGIT_NORMAL_CDF_PARAMS, ?{ k =  1.0; l = SIDE_CONTRIBUTION_LIMIT; });
    };
    let center = 1.0 - left - right;
    
    let abs_result = Float.abs(result);
    let side_coef = if (abs_result >= 0) right else left;

    {
      refund = abs_result * side_coef + (1.0 - abs_result) * center;
      reward = abs_result * side_coef; // Do not reward the center
    };
  };

  // see www.desmos.com/calculator/iv87gjyqlx
  func attenuatePayout(payout_args: PayoutArgs, num_voters: Nat) : PayoutArgs {
    // It is impossible to attenuate if there is no voter
    if (num_voters == 0){ Debug.trap("Cannot attenuate payout: there is 0 voters"); };

    let { refund_share; reward_tokens; } = payout_args;
    let { coef; exponent; } = ATTENUATE_MODIFIER_PARAMS;

    let log_num_voters = Float.log(Float.fromInt(num_voters));
    let confidence = 1.0 - Float.exp(-Float.pow(log_num_voters * coef, exponent));

    {
      refund_share  = refund_share * confidence + 1.0 * (1.0 - confidence);
      reward_tokens = Int.abs(Float.toInt(Float.fromInt(reward_tokens) * confidence));
    };
  };

};
