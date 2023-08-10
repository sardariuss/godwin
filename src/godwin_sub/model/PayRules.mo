import SubMomentum   "SubMomentum";
import PayTypes      "token/Types";
import VoteTypes     "votes/Types";
import Polarization  "votes/representation/Polarization";
import Types         "../stable/Types";

import Ref           "../utils/Ref";
import WRef          "../utils/wrappers/WRef";
import Math          "../utils/Math";
import Duration      "../utils/Duration";

import Trie          "mo:base/Trie";
import Debug         "mo:base/Debug";
import Int           "mo:base/Int";
import Float         "mo:base/Float";
import Text          "mo:base/Text";
import Option        "mo:base/Option";

module {

  type Ref<K>               = Ref.Ref<K>;
  type WRef<K>              = WRef.WRef<K>;

  type BasePriceParameters  = Types.Current.BasePriceParameters;
  type SelectionParameters  = Types.Current.SelectionParameters;
  type PriceRegister        = Types.Current.PriceRegister;
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

  let ATTENUATE_MODIFIER_PARAMS = {
    coef     = 0.5; // The greater, the less number of voters it takes to fully apply the payout rules
    exponent = 2.5; // The greater, the more the payout rules are attenuated for small number of voters
  };

  // Allow to specify only what's required to compute the interest distribution
  type ReducedAppeal = {ups: Nat; downs: Nat};

  // This type is used by the function computeQuestionAuthorPayouts
  type ClosureInfo = {
    #CENSORED;
    #TIMED_OUT;
    #SELECTED: { score : Float; };
  };

  func toClosureInfo(closure: InterestVoteClosure, appeal: Appeal) : ClosureInfo {
    switch (closure) {
      case(#CENSORED)   { #CENSORED;                          };
      case(#TIMED_OUT)  { #TIMED_OUT;                         };
      case(#SELECTED)   { #SELECTED{ score = appeal.score; }; };
    };
  };

  // see www.desmos.com/calculator/lejulppdny
  public func computeInterestDistribution(appeal: ReducedAppeal) : InterestDistribution {

    let { ups; downs; } = appeal;

    // Prevent division by 0
    if (ups + downs == 0){ Debug.trap("Cannot compute interest distribution: there is 0 voter"); };

    let { winners; loosers; } = if (ups >= downs){ 
      { winners = Float.fromInt(ups);   loosers = Float.fromInt(downs); };
    } else {
      { winners = Float.fromInt(downs); loosers = Float.fromInt(ups); };
    };

    let looser_share = loosers / winners;
    let winner_share = 1.0 + (1.0 - looser_share) * looser_share;

    let shares = {
      up   = if (ups >= downs){ winner_share; } else { looser_share; };
      down = if (ups >= downs){ looser_share; } else { winner_share; };
    };

    let { LOGIT_NORMAL_PDF_PARAMS; } = INTEREST_PAYOUT_PARAMS.REWARD_PARAMS;

    let reward_ratio = Math.logitNormalPDF(loosers / (winners + loosers), LOGIT_NORMAL_PDF_PARAMS, null);

    { shares; reward_ratio; };
  };

  public func computeSubPrices(base_price_params: BasePriceParameters, selection_params: SelectionParameters) : PriceRegister {
    let { base_selection_period; reopen_vote_price_e8s; open_vote_price_e8s; interest_vote_price_e8s; categorization_vote_price_e8s; } = base_price_params;
    let { selection_period } = selection_params;
    let coef = Float.fromInt(Duration.toTime(selection_period)) / Float.fromInt(Duration.toTime(base_selection_period));
    return {
      open_vote_price_e8s           = Int.abs(Float.toInt(Float.fromInt(open_vote_price_e8s          ) * coef));
      reopen_vote_price_e8s         = Int.abs(Float.toInt(Float.fromInt(reopen_vote_price_e8s        ) * coef));
      interest_vote_price_e8s       = Int.abs(Float.toInt(Float.fromInt(interest_vote_price_e8s      ) * coef));
      categorization_vote_price_e8s = Int.abs(Float.toInt(Float.fromInt(categorization_vote_price_e8s) * coef));
    };
  };

  public func build(price_register: Ref<PriceRegister>) : PayRules {
    PayRules(WRef.WRef(price_register));
  };

  public class PayRules(_price_register: WRef<PriceRegister>) {

    public func updatePrices(base_price_params: BasePriceParameters, selection_params: SelectionParameters) {
      _price_register.set(computeSubPrices(base_price_params, selection_params));
    };

    public func getPrices() : PriceRegister {
      _price_register.get();
    };

    public func getQuestionPayouts(appeal: Appeal, closure: InterestVoteClosure, iteration: Nat) : QuestionPayouts {
      let author_payout = attenuatePayout(computeQuestionAuthorPayout(getPrices(), toClosureInfo(closure, appeal), iteration), appeal.ups + appeal.downs);
      let creator_reward = computeQuestionCreatorReward(OPENED_QUESTION_PAYOUT_PARAMS.CREATOR_REWARD_EXTRA_RATIO, author_payout);
      { author_payout; creator_reward; };
    };

    public func getInterestVotePayout(distribution: InterestDistribution, num_voters: Nat, ballot: Interest) : PayoutArgs {
      attenuatePayout(computeInterestVotePayout(getPrices(), distribution, ballot), num_voters);
    };

    public func getCategorizationPayout(ballot: CursorMap, result: PolarizationMap, num_voters: Nat) : PayoutArgs {
      attenuatePayout(computeCategorizationPayout(getPrices(), ballot, result, num_voters), num_voters);
    };

  };

  // see www.desmos.com/calculator/vkyld4yntw
  public func computeQuestionAuthorPayout(price_register: PriceRegister, closure_info: ClosureInfo, iteration: Nat) : PayoutArgs {
    switch(closure_info){
      case(#CENSORED){
        // If the question has been censored, no refund and no reward
        { refund_share = 0.0; reward_tokens = null; };
      };
      case(#TIMED_OUT){
        // If the question has timed out, refund the price it took to open the question, but no reward
        { refund_share = 1.0; reward_tokens = null; };
      };
      case(#SELECTED({score})){
        // @todo: the minimum score shall be a hardcoded parameter, not a magic number
        if (score < 1.0) { Debug.trap("Cannot compute question author payout: score is must be superior than 1"); };
        // If the question has been selected, reward the price it took to open the question
        // multiplied by the square root of the score
        let price_e8s = if (iteration == 0) { price_register.open_vote_price_e8s; } else { price_register.reopen_vote_price_e8s; };
        { refund_share = 1.0; reward_tokens = ?Int.abs(Float.toInt((Float.sqrt(score) - 1.0) * Float.fromInt(price_e8s))); };
      };
    };
  };

  public func computeQuestionCreatorReward(creator_ratio: Float, author_payout: PayoutArgs) : ?Balance {
    // If the author got any reward, the creator gets a percentage of it
    Option.map(author_payout.reward_tokens, func(amount: Balance) : Balance {
      Int.abs(Float.toInt(Float.fromInt(amount) * creator_ratio));
    });
  };

  public func computeInterestVotePayout(price_register: PriceRegister, distribution: InterestDistribution, ballot: Interest) : PayoutArgs {

    let { shares; reward_ratio; } = distribution;
    let { coef; } = INTEREST_PAYOUT_PARAMS.REWARD_PARAMS;
    let price_e8s = price_register.interest_vote_price_e8s;

    {
      refund_share  = switch(ballot){ case(#UP) shares.up; case(#DOWN) shares.down; };
      reward_tokens = if (reward_ratio > 0.0) { ?Int.abs(Float.toInt(coef * reward_ratio * Float.fromInt(price_e8s))) } else { null; };
    };
  };

  public func computeCategorizationPayout(price_register: PriceRegister, ballot: CursorMap, result: PolarizationMap, num_voters: Nat) : PayoutArgs {

    if (num_voters == 0){
      Debug.trap("It is impossible to payout voters if there is no voter");
    };

    let accumulate_payout = func(category: Category, result: Polarization, payout: Payout) : Payout {
      sumPayouts(payout, switch(Trie.get(ballot, key(category), Text.equal)){
        case(null) { nullPayout(); };
        case(?answer) { computeCategoryShare(answer, Polarization.toCursor(result)); };
      });
    };

    let payout = Trie.fold<Category, Polarization, Payout>(result, accumulate_payout, nullPayout());

    if (payout.refund < 0.0){ Debug.trap("Negative refund"); };
    if (payout.reward < 0.0){ Debug.trap("Negative reward"); };

    let price_e8s = price_register.categorization_vote_price_e8s;

    {
      refund_share = payout.refund;
      reward_tokens = ?Int.abs(Float.toInt(payout.reward * Float.fromInt(price_e8s)));
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
  func attenuatePayout(author_payout: PayoutArgs, num_voters: Nat) : PayoutArgs {
    // It is impossible to attenuate if there is no voter
    if (num_voters == 0){ Debug.trap("Cannot attenuate payout: there is 0 voters"); };

    let { refund_share; reward_tokens; } = author_payout;
    let { coef; exponent; } = ATTENUATE_MODIFIER_PARAMS;

    let log_num_voters = Float.log(Float.fromInt(num_voters));
    let confidence = 1.0 - Float.exp(-Float.pow(log_num_voters * coef, exponent));

    {
      refund_share  = refund_share * confidence + 1.0 * (1.0 - confidence);
      reward_tokens = Option.map(reward_tokens, func(amount: Balance) : Balance {
        Int.abs(Float.toInt(Float.fromInt(amount) * confidence));
      });
    };
  };

};
