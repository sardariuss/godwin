import SubMomentum   "SubMomentum";
import PayTypes      "token/Types";
import VoteTypes     "votes/Types";
import Polarization  "votes/representation/Polarization";

import Math          "../utils/Math";

import Trie          "mo:base/Trie";
import Debug         "mo:base/Debug";
import Int           "mo:base/Int";
import Float         "mo:base/Float";
import Text          "mo:base/Text";
import Option        "mo:base/Option";

module {

  type Appeal               = VoteTypes.Appeal;
  type Interest             = VoteTypes.Interest;
  type CursorMap            = VoteTypes.CursorMap;
  type Cursor               = VoteTypes.Cursor;
  type Polarization         = VoteTypes.Polarization;
  type PolarizationMap      = VoteTypes.PolarizationMap;
  type Category             = VoteTypes.Category;
  type InterestVoteClosure  = VoteTypes.InterestVoteClosure;
  type InterestDistribution = VoteTypes.InterestDistribution;
  type Balance              = PayTypes.Balance;
  type RawPayout            = PayTypes.RawPayout;
  type PayoutArgs           = PayTypes.PayoutArgs;
  type QuestionPayouts      = PayTypes.QuestionPayouts;

  type SubMomentum          = SubMomentum.SubMomentum;
  
  type Payout               = { refund: Float; reward: Float; };

  func key(c: Category) : Trie.Key<Category> { { hash = Text.hash(c); key = c; } };

  func nullPayout() : Payout { { refund = 0.0; reward = 0.0; }; };
  func sumPayouts(x: Payout, y: Payout) : Payout { { refund = x.refund + y.refund; reward = x.reward + y.reward; }; };

  let OPENED_QUESTION_PAYOUT_PARAMS = {
    CREATOR_REWARD_EXTRA_RATIO = 0.05; // @todo: should be a base parameter settable from the master
  };

  public let INTEREST_PAYOUT_PARAMS = {
    REWARD_PARAMS ={
      LOGIT_NORMAL_PDF_PARAMS = {
        sigma = 0.8;
        mu    = 0.0;
      };
      coef = 0.423752;
    };
  };

  let CATEGORIZATION_PAYOUT_PARAMS = {
    SIDE_CONTRIBUTION_LIMIT =  0.333333333333333333333333333;
    LOGIT_NORMAL_CDF_PARAMS = {
      sigma = 0.8;
      mu    = 0.0;
    };
  };

  // @todo: these parameters shall be settable from the master
  let ATTENUATE_MODIFIER_PARAMS = {
    coef     = 2.0; // The greater, the less number of voters it takes to fully apply the payout rules
    exponent = 1.0; // The greater, the more the payout rules are attenuated for a small number of voters
  };

  // Allow to specify only what's required to compute the interest distribution
  type ReducedAppeal = {ups: Nat; downs: Nat};

  public func convertRewardToTokens(reward: ?Float, price: Balance) : ?Balance {
    Option.map(reward, func(r: Float) : Balance { Int.abs(Float.toInt(r * Float.fromInt(price))); });
  };

  // see www.desmos.com/calculator/lejulppdny
  public func computeInterestDistribution(appeal: ReducedAppeal) : InterestDistribution {

    let { ups; downs; } = appeal;

    // Prevent division by 0
    if (ups + downs == 0){ Debug.trap("Cannot compute interest distribution: there is 0 voter"); };

    let total = Float.fromInt(ups + downs);

    let { winners; loosers; } = if (ups >= downs){ 
      { winners = Float.fromInt(ups);   loosers = Float.fromInt(downs); };
    } else {
      { winners = Float.fromInt(downs); loosers = Float.fromInt(ups); };
    };

    let looser_share = loosers / winners;
    let winner_share = 1.0 + (1.0 - looser_share) * looser_share;

    let shares = {
      up   = if (ups >= downs){ winner_share / total; } else { looser_share / total; };
      down = if (ups >= downs){ looser_share / total; } else { winner_share / total; };
    };

    let { LOGIT_NORMAL_PDF_PARAMS; } = INTEREST_PAYOUT_PARAMS.REWARD_PARAMS;

    let reward_ratio = Math.logitNormalPDF(loosers / (winners + loosers), LOGIT_NORMAL_PDF_PARAMS, null);

    { shares; reward_ratio; };
  };

  public func computeQuestionAuthorPayout(closure: InterestVoteClosure, appeal : { score : Float; }) : RawPayout {
    switch(closure){
      case(#CENSORED){
        // If the question has been censored, no refund and no reward
        { refund_share = 0.0; reward = null; };
      };
      case(#TIMED_OUT){
        // If the question has timed out, refund the price it took to open the question, but no reward
        { refund_share = 1.0; reward = null; };
      };
      case(#SELECTED){
        let { score } = appeal;
        if (score <= 0.0) { Debug.trap("Cannot compute question author payout: score must be positive"); };
        // If the question has been selected, reward the price it took to open the question
        // multiplied by the square root of the score
        { refund_share = 1.0; reward = ?Float.sqrt(score); };
      };
    };
  };

  public func deduceSubCreatorReward(author_payout: RawPayout) : ?Float {
    // If the author got any reward, the creator gets a percentage of it
    Option.map(author_payout.reward, func(reward: Float) : Float { reward * OPENED_QUESTION_PAYOUT_PARAMS.CREATOR_REWARD_EXTRA_RATIO; });
  };

  public func computeInterestVotePayout(distribution: InterestDistribution, ballot: Interest) : RawPayout {

    let { shares; reward_ratio; } = distribution;
    let { coef; } = INTEREST_PAYOUT_PARAMS.REWARD_PARAMS;

    {
      refund_share  = switch(ballot){ case(#UP) shares.up; case(#DOWN) shares.down; };
      reward = if (reward_ratio > 0.0) { ?(coef * reward_ratio); } else { null; };
    };
  };

  public func computeCategorizationPayout(ballot: CursorMap, result: PolarizationMap) : RawPayout {

    let accumulate_payout = func(category: Category, result: Polarization, payout: Payout) : Payout {
      sumPayouts(payout, switch(Trie.get(ballot, key(category), Text.equal)){
        case(null) { nullPayout(); };
        case(?answer) { computeCategoryShare(answer, Polarization.toCursor(result)); };
      });
    };

    let payout = Trie.fold<Category, Polarization, Payout>(result, accumulate_payout, nullPayout());

    if (payout.refund < 0.0){ Debug.trap("Negative refund"); };
    if (payout.reward < 0.0){ Debug.trap("Negative reward"); };

    {
      refund_share = payout.refund;
      reward = ?(payout.reward);
    };
  };

  // see www.desmos.com/calculator/voiqqttaog
  public func computeCategoryShare(answer: Cursor, result: Cursor) : Payout {

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
  public func attenuatePayout(payout: RawPayout, num_voters: Nat, nominal_share: Float) : RawPayout {
    
    // Return the original payout if there is no voter, also prevent dividing by 0
    if (num_voters == 0){ return payout; };

    let { refund_share; reward; } = payout;
    let { coef; exponent; } = ATTENUATE_MODIFIER_PARAMS;

    let log_num_voters = Float.log(Float.fromInt(num_voters));
    let confidence = 1.0 - Float.exp(-Float.pow(log_num_voters * coef, exponent));

    {
      refund_share  = confidence * refund_share  + (1.0 - confidence) * nominal_share;
      reward = Option.map(reward, func(r: Float) : Float { r * confidence; });
    };
  };

};
