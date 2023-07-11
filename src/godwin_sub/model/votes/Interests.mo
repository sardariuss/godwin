import Types               "Types";
import Votes               "Votes";
import QuestionVoteJoins   "QuestionVoteJoins";
import PayToVote           "PayToVote";
import PayRules            "../PayRules";
import PayForNew           "../token/PayForNew";
import PayTypes            "../token/Types";
import PayForElement       "../token/PayForElement";
import QuestionTypes       "../questions/Types";
import KeyConverter        "../questions/KeyConverter";

import UtilsTypes          "../../utils/Types";

import Set                 "mo:map/Set";
import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Float               "mo:base/Float";
import Nat                 "mo:base/Nat";
import Option              "mo:base/Option";

module {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Time                   = Int;
  type Set<K>                 = Set.Set<K>;
  type Map<K, V>              = Map.Map<K, V>;
  
  type VoteId                 = Types.VoteId;
  type Vote                   = Types.Vote<Interest, Appeal>;
  type Ballot                 = Types.Ballot<Interest>;
  type PutBallotError         = Types.PutBallotError;
  type FindBallotError        = Types.FindBallotError;
  type RevealVoteError        = Types.RevealVoteError;
  type OpenVoteError          = Types.OpenVoteError;
  type Interest               = Types.Interest;
  type Appeal                 = Types.Appeal;
  type RevealedBallot         = Types.RevealedBallot<Interest>;
  type InterestMomentumArgs   = Types.InterestMomentumArgs;
  type IVotePolicy            = Types.IVotePolicy<Interest, Appeal>;
  type Votes<T, A>            = Votes.Votes<T, A>;
  
  type QuestionVoteJoins      = QuestionVoteJoins.QuestionVoteJoins;
  type Question               = QuestionTypes.Question;
  type Key                    = QuestionTypes.Key;
  type QuestionId             = QuestionTypes.QuestionId;
  type QuestionQueries        = QuestionTypes.QuestionQueries;
  type ITokenInterface        = PayTypes.ITokenInterface;
  type PayForNew              = PayForNew.PayForNew;
  type TransactionsRecord     = PayTypes.TransactionsRecord;
  type PayoutArgs             = PayTypes.PayoutArgs;

  type ScanLimitResult<K>     = UtilsTypes.ScanLimitResult<K>;
  type Direction              = UtilsTypes.Direction;

  type PayRules               = PayRules.PayRules;
  
  public type Register        = Votes.Register<Interest, Appeal>;

  let DECAY_WEIGHT      = 0.5; // Arbitrarily set
  let DECAY_RESISTANCE  = 1.0; // Arbitrarily set

  let PRICE_OPENING_VOTE = 1_000_000_000; // @todo: make this a parameter
  let PRICE_PUT_BALLOT   = 100_000_000; // @todo: make this a parameter

  public func initRegister() : Register {
    Votes.initRegister<Interest, Appeal>();
  };

  public func build(
    vote_register: Votes.Register<Interest, Appeal>,
    transactions_register: Map<Principal, Map<VoteId, TransactionsRecord>>,
    token_interface: ITokenInterface,
    pay_for_new: PayForNew,
    joins: QuestionVoteJoins,
    queries: QuestionQueries,
    pay_rules: PayRules
  ) : Interests {
    Interests(
      Votes.Votes(
        vote_register,
        VotePolicy(),
        ?PayToVote.PayToVote<Interest, Appeal>(
          PayForElement.build(
            transactions_register,
            token_interface,
            #PUT_INTEREST_BALLOT,
          ),
          pay_rules.getInterestVotePrice(),
          pay_rules.computeInterestVotePayout
        )
      ),
      pay_for_new,
      joins,
      queries,
      pay_rules
    );
  };

  public class Interests(
    _votes: Votes<Interest, Appeal>,
    _pay_for_new: PayForNew,
    _joins: QuestionVoteJoins,
    _queries: QuestionQueries,
    _pay_rules: PayRules
  ) {
    
    public func openVote(principal: Principal, date: Time, on_success: (VoteId) -> QuestionId) : async* Result<(QuestionId, VoteId), OpenVoteError> {
      switch(await* _pay_for_new.payin(principal, _pay_rules.getOpenVotePrice(), func() : VoteId { _votes.newVote(date); })){
        case(#err(err)) { #err(err); };
        case(#ok(vote_id)) {
          let question_id = on_success(vote_id);
          _queries.add(KeyConverter.toInterestScoreKey(question_id, 0.0));
          #ok((question_id, vote_id));
        };
      };
    };

    public func closeVote(vote_id: Nat, date: Time) : async* () {
      // Close the vote
      await* _votes.closeVote(vote_id, date);
      let vote = _votes.getVote(vote_id);
      // Remove the vote from the interest query
      _queries.remove(KeyConverter.toInterestScoreKey(_joins.getQuestionIteration(vote_id).0, vote.aggregate.score));
      // Pay out the buyer
      let (refund_amount, reward_amount) = _pay_rules.computeOpenVotePayout(vote.aggregate, Map.size(vote.ballots));
      await* _pay_for_new.payout(vote_id, refund_amount, reward_amount);
    };

    public func putBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Interest) : async* Result<(), PutBallotError> {    
      
      let old_appeal = _votes.getVote(vote_id).aggregate.score;

      Result.mapOk<(), (), PutBallotError>(await* _votes.putBallot(principal, vote_id, {date; answer = interest;}), func(){
        let new_appeal = _votes.getVote(vote_id).aggregate.score;
        let question_id = _joins.getQuestionIteration(vote_id).0;
        _queries.replace(?KeyConverter.toInterestScoreKey(question_id, old_appeal), ?KeyConverter.toInterestScoreKey(question_id, new_appeal));
      });
    };

    public func getVote(vote_id: VoteId) : Vote {
      _votes.getVote(vote_id);
    };

    public func revealBallot(caller: Principal, voter: Principal, vote_id: VoteId) : Result<RevealedBallot, FindBallotError> {
      _votes.revealBallot(caller, voter, vote_id);
    };

    public func revealVote(vote_id: VoteId) : Result<Vote, RevealVoteError> {
      _votes.revealVote(vote_id);
    };

    public func findBallotTransactions(principal: Principal, id: VoteId) : ?TransactionsRecord {
      _votes.findBallotTransactions(principal, id);
    };

    public func findOpenVoteTransactions(principal: Principal, id: VoteId) : ?TransactionsRecord {
      _pay_for_new.findTransactionsRecord(principal, id);
    };

    public func revealBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : ScanLimitResult<RevealedBallot> {
      _votes.revealBallots(caller, voter, direction, limit, previous_id);
    };

    public func getVoterBallots(principal: Principal) : Map<VoteId, Ballot> {
      _votes.getVoterBallots(principal);
    };

  };

  class VotePolicy() : IVotePolicy {

    public func canPutBallot(vote: Vote, principal: Principal, ballot: Ballot) : Result<(), PutBallotError> {
      // The interest variant is always valid.
      #ok;
    };

    public func emptyAggregate() : Appeal {
      { ups = 0; downs = 0; score = 0.0; last_score_switch = null; };
    };

    public func onPutBallot(aggregate: Appeal, new_ballot: Ballot, old_ballot: ?Ballot) : Appeal {
      var appeal = aggregate;
      // Add the new ballot to the appeal
      appeal := addInterest(appeal, new_ballot);
      // If there was an old ballot, remove it from the appeal
      Option.iterate(old_ballot, func(ballot: Ballot) {
        appeal := subInterest(appeal, ballot);
      });
      appeal;
    };

    public func onVoteClosed(aggregate: Appeal, date: Time) : Appeal {
      aggregate;
    };

    public func canRevealVote(vote: Vote) : Bool {
      vote.status == #CLOSED;
    };

    public func canRevealBallot(vote: Vote, caller: Principal, voter: Principal) : Bool {
      vote.status == #CLOSED or caller == voter;
    };
  };

  func initInterest() : Appeal {
    { ups = 0; downs = 0; score = 0.0; last_score_switch = null; };
  };

  func addInterest(appeal: Appeal, ballot: Ballot) : Appeal {
    let ups   = if (ballot.answer == #UP)   { Nat.add(appeal.ups, 1);   } else { appeal.ups;   };
    let downs = if (ballot.answer == #DOWN) { Nat.add(appeal.downs, 1); } else { appeal.downs; };
    let score = computeScore(ups, downs);

    let last_score_switch = if (appeal.last_score_switch == null or ups == downs){
      ?ballot.date;
      } else {
      appeal.last_score_switch;
    };

    { ups; downs; score; last_score_switch; };
  };

  func subInterest(appeal: Appeal, ballot: Ballot) : Appeal {
    let ups   = if (ballot.answer == #UP)   { Nat.sub(appeal.ups, 1);   } else { appeal.ups;   };
    let downs = if (ballot.answer == #DOWN) { Nat.sub(appeal.downs, 1); } else { appeal.downs; };
    let score = computeScore(ups, downs);

    { appeal with ups; downs; score; };
  };

  func computeScore(ups: Nat, downs: Nat) : Float {
    let total = Float.fromInt(ups + downs);
    if (total == 0.0) { return 0.0; };
    let x = Float.fromInt(ups) / total;
    let growth_rate = 20.0;
    let mid_point = 0.5;
    // https://stackoverflow.com/a/3787645: this will underflow to 0 for large negative values of x,
    // but that may be OK depending on your context since the exact result is nearly zero in that case.
    let sigmoid = (2.0 / (1.0 + Float.exp(-1.0 * growth_rate * (x - mid_point)))) - 1.0;
    total * sigmoid;
  };

  
  public func computeSelectionScore(args: InterestMomentumArgs, pick_rate: Time, now: Time): Float {
    let { last_pick_date; last_pick_score; num_votes_opened; minimum_score; } = args;
    let score = computeMomentumCoef(last_pick_date, pick_rate, num_votes_opened, now) * last_pick_score;
    if (score > minimum_score) { score; } else { minimum_score; };
  };

  // https://www.desmos.com/calculator/jcddnwyqbk
  public func computeMomentumCoef(last_pick_date: Time, pick_rate: Time, num_votes_opened: Nat, now: Time): Float {
    let time_passed = Float.fromInt(now - last_pick_date) / Float.fromInt(pick_rate);
    ( 
        (1 - DECAY_WEIGHT) * (1.0 / time_passed)
      +      DECAY_WEIGHT  * Float.exp((-time_passed + 1) / (DECAY_RESISTANCE * (Float.fromInt(num_votes_opened) + 1)))
    );
  };
  
};