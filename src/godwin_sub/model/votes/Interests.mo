import Types               "Types";
import Votes               "Votes";
import QuestionVoteJoins   "QuestionVoteJoins";
import PayToVote           "PayToVote";
import InterestRules       "InterestRules";
import PayRules            "../PayRules";
import PayForNew           "../token/PayForNew";
import PayTypes            "../token/Types";
import PayForElement       "../token/PayForElement";
import RewardForElement    "../token/RewardForElement";
import QuestionTypes       "../questions/Types";
import KeyConverter        "../questions/KeyConverter";

import UtilsTypes          "../../utils/Types";
import WMap                "../../utils/wrappers/WMap";
import Ref                 "../../utils/Ref";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Nat                 "mo:base/Nat";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";

module {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Time                   = Int;
  type Map<K, V>              = Map.Map<K, V>;
  type WMap2D<K1, K2, V>      = WMap.WMap2D<K1, K2, V>;
  type Ref<T>                 = Ref.Ref<T>;
  
  type PriceParameters        = Types.PriceParameters;
  type VoteId                 = Types.VoteId;
  type Vote                   = Types.Vote<Interest, Appeal>;
  type Ballot                 = Types.Ballot<Interest>;
  type PutBallotError         = Types.PutBallotError;
  type FindBallotError        = Types.FindBallotError;
  type RevealVoteError        = Types.RevealVoteError;
  type OpenVoteError          = Types.OpenVoteError;
  type GetVoteError           = Types.GetVoteError;
  type Interest               = Types.Interest;
  type Appeal                 = Types.Appeal;
  type VoteStatus             = Types.VoteStatus;
  type RevealableBallot       = Types.RevealableBallot<Interest>;
  type IVotePolicy            = Types.IVotePolicy<Interest, Appeal>;
  type InterestVoteClosure    = Types.InterestVoteClosure;
  type IVotersHistory         = Types.IVotersHistory;

  type Votes<T, A>            = Votes.Votes<T, A>;
  
  type QuestionVoteJoins      = QuestionVoteJoins.QuestionVoteJoins;
  type Question               = QuestionTypes.Question;
  type Key                    = QuestionTypes.Key;
  type QuestionId             = QuestionTypes.QuestionId;
  type QuestionQueries        = QuestionTypes.QuestionQueries;
  type ITokenInterface        = PayTypes.ITokenInterface;
  type TransactionsRecord     = PayTypes.TransactionsRecord;
  type MintResult             = PayTypes.MintResult;
  type RawPayout              = PayTypes.RawPayout;
  type PayForNew              = PayForNew.PayForNew;

  type PayoutFunction         = PayToVote.PayoutFunction<Interest, Appeal>;

  type ScanLimitResult<K>     = UtilsTypes.ScanLimitResult<K>;
  type Direction              = UtilsTypes.Direction;

  type RewardForElement       = RewardForElement.RewardForElement;
  
  public type Register        = Votes.Register<Interest, Appeal>;

  let HOTNESS_TIME_UNIT_NS = 86_400_000_000_000; // 24 hours in nanoseconds @todo: make this a parameter

  public func initRegister() : Register {
    Votes.initRegister<Interest, Appeal>();
  };

  public func build(
    vote_register: Votes.Register<Interest, Appeal>,
    open_by: Map<Principal, Map<VoteId, Time>>,
    voters_history: IVotersHistory,
    transactions_register: Map<Principal, Map<VoteId, TransactionsRecord>>,
    token_interface: ITokenInterface,
    pay_for_new: PayForNew,
    joins: QuestionVoteJoins,
    queries: QuestionQueries,
    price_params: Ref<PriceParameters>,
    creator: Principal,
    creator_rewards_register: Map<Nat, MintResult>
  ) : Interests {
    Interests(
      Votes.Votes(
        vote_register,
        voters_history,
        VotePolicy(),
        ?PayToVote.PayToVote<Interest, Appeal>(
          PayForElement.build(
            transactions_register,
            token_interface,
            #PUT_INTEREST_BALLOT,
          ),
          func() : Nat { price_params.v.interest_vote_price_sats; },
          voterPayout
        )
      ),
      WMap.WMap2D(open_by, Map.phash, Map.nhash),
      pay_for_new,
      joins,
      queries,
      price_params,
      RewardForElement.RewardForElement(
        creator,
        creator_rewards_register,
        token_interface
      )
    );
  };

  public class Interests(
    _votes: Votes<Interest, Appeal>,
    _open_by: WMap2D<Principal, VoteId, Time>,
    _pay_for_new: PayForNew,
    _joins: QuestionVoteJoins,
    _queries: QuestionQueries,
    _price_params: Ref<PriceParameters>,
    _reward_for_element: RewardForElement
  ) {
    
    public func openVote(principal: Principal, date: Time, last_iteration: ?Nat, on_success: (VoteId) -> QuestionId) : async* Result<(QuestionId, VoteId), OpenVoteError> {
      // Get the price to open the vote
      let vote_price = if (Option.isNull(last_iteration)) { 
        _price_params.v.open_vote_price_sats; 
      } else { 
        _price_params.v.reopen_vote_price_sats; 
      };
      // The user has to pay to open up an interest vote
      // The PayForNew payin function requires a callback to create the vote, it will be called only if the payement succeeds
      let vote_id = switch(await* _pay_for_new.payin(principal, vote_price, func() : VoteId { _votes.newVote(date); })){
        case(#err(err)) { return #err(err); };
        case(#ok(id)) { id; };
      };
      // In order to retrieve who opened the vote, we need to store the vote id in the open_by map
      _open_by.set(principal, vote_id, date);
      // Add the vote to the hotness orderby query
      let question_id = on_success(vote_id);
      _queries.add(KeyConverter.toHotnessKey(question_id, _votes.getVote(vote_id).aggregate.hotness));
      // Return the question and vote ids
      #ok((question_id, vote_id));
    };

    public func closeVote(vote_id: Nat, date: Time, closure: InterestVoteClosure) : async* () {
      // Close the vote
      await* _votes.closeVote(vote_id, date);
      let vote = _votes.getVote(vote_id);
      // Remove the vote from the interest query
      let (question_id, iteration) = _joins.getQuestionIteration(vote_id);
      _queries.remove(KeyConverter.toHotnessKey(question_id, vote.aggregate.hotness));
      // Payout the author and the sub creator
      let price = if (iteration == 0) { 
        _price_params.v.open_vote_price_sats; 
      } else { 
        _price_params.v.reopen_vote_price_sats; 
      };
      // Get the author raw payout
      let author_payout = PayRules.attenuatePayout(
        PayRules.computeQuestionAuthorPayout(closure, vote.aggregate), 
        Map.size(vote.ballots),
        1.0 // nominal share is the full refund
      );
      // Get the creator raw reward
      let creator_reward = PayRules.deduceSubCreatorReward(author_payout);
      
      await* _pay_for_new.payout(vote_id, { author_payout with reward_tokens = PayRules.convertRewardToTokens(author_payout.reward, price); });
      switch(PayRules.convertRewardToTokens(creator_reward, price)){
        case(null){};
        case(?reward){
          await* _reward_for_element.reward(vote_id, reward);
        };
      };
    };

    public func canVote(vote_id: VoteId, principal: Principal) : Result<(), PutBallotError> {
      _votes.canVote(vote_id, principal);
    };

    public func putBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Interest) : async* Result<(), PutBallotError> {    
      
      let old_hotness = _votes.getVote(vote_id).aggregate.hotness;

      Result.mapOk<(), (), PutBallotError>(await* _votes.putBallot(principal, vote_id, date, interest), func(){
        let question_id = _joins.getQuestionIteration(vote_id).0;
        _queries.replace(
          ?KeyConverter.toHotnessKey(question_id, old_hotness),
          ?KeyConverter.toHotnessKey(question_id, _votes.getVote(vote_id).aggregate.hotness)
        );
      });
    };

    public func findVote(id: VoteId) : Result<Vote, GetVoteError> {
      _votes.findVote(id);
    };

    public func getVote(vote_id: VoteId) : Vote {
      _votes.getVote(vote_id);
    };

    public func findBallot(principal: Principal, id: VoteId) : Result<Ballot, FindBallotError> {
      _votes.findBallot(principal, id);
    };

    public func revealBallot(caller: Principal, voter: Principal, vote_id: VoteId) : Result<RevealableBallot, FindBallotError> {
      _votes.revealBallot(caller, voter, vote_id);
    };

    public func revealVote(vote_id: VoteId) : Result<Vote, RevealVoteError> {
      _votes.revealVote(vote_id);
    };

    public func findBallotTransactions(principal: Principal, id: VoteId) : ?TransactionsRecord {
      _votes.findBallotTransactions(principal, id);
    };

    public func getOpenedVotes(principal: Principal) : Map<VoteId, Time> {
      _open_by.getAll(principal);
    };

    public func findOpenedVoteTransactions(principal: Principal, id: VoteId) : ?TransactionsRecord {
      _pay_for_new.findTransactionsRecord(principal, id);
    };

    public func getVoterBallots(principal: Principal) : Map<VoteId, Ballot> {
      _votes.getVoterBallots(principal);
    };

    public func hasBallot(principal: Principal, vote_id: VoteId) : Bool {
      _votes.hasBallot(principal, vote_id);
    };

  };

  func voterPayout(interest: Interest, appeal: Appeal) : RawPayout {
    // @todo: the distribution shall not be computed every time the payout is calculated for a voter
    let distribution = PayRules.computeInterestDistribution(appeal);
    PayRules.computeInterestVotePayout(distribution, interest);
  };

  class VotePolicy() : IVotePolicy {

    public func isValidBallot(ballot: Ballot) : Result<(), PutBallotError> {
      // The interest is an enum, so it is always valid
      #ok;
    };

    public func canVote(vote: Vote, principal: Principal) : Result<(), PutBallotError> {
      // Verify the user did not vote already
      if (Option.isSome(Map.get(vote.ballots, Map.phash, principal))){
        return #err(#ChangeBallotNotAllowed);
      };
      #ok;
    };

    public func emptyAggregate(date: Time) : Appeal {
      let hot_timestamp = InterestRules.computeHotTimestamp(date, HOTNESS_TIME_UNIT_NS);
      let { score; hotness; } = InterestRules.computeScoreAndHotness(0, 0, hot_timestamp);
      {
        ups = 0;
        downs = 0; 
        score;
        negative_score_date = null;
        hot_timestamp;
        hotness;
      };
    };

    public func addToAggregate(appeal: Appeal, new_ballot: Ballot, old_ballot: ?Ballot) : Appeal {
      
      // One should not be able to replace their ballot
      Option.iterate(old_ballot, func(ballot: Ballot) {
        Debug.trap("Cannot replace interest ballot");
      });

      // Update the number of ups or downs depending on the ballot
      let ups   = if (new_ballot.answer == #UP)   { Nat.add(appeal.ups, 1);   } else { appeal.ups;   };
      let downs = if (new_ballot.answer == #DOWN) { Nat.add(appeal.downs, 1); } else { appeal.downs; };
    
      // Compute the scores
      let { score; hotness; } = InterestRules.computeScoreAndHotness(ups, downs, appeal.hot_timestamp);

      let negative_score_date = if (score >= 0.0) { 
        null; // More ups than downs, the date shall be null
      } else if (Option.isNull(appeal.negative_score_date)) {
        ?new_ballot.date; // The score just became negative, use the current date
      } else {
        appeal.negative_score_date; // Keep the date of the last time the score turned negative
      };

      // Return the modified appeal
      { appeal with ups; downs; score; hotness; negative_score_date; };
    };

    public func onStatusChanged(status: VoteStatus, aggregate: Appeal, date: Time) : Appeal {
      aggregate;
    };

    public func canRevealBallot(vote: Vote, caller: Principal, voter: Principal) : Bool {
      vote.status != #OPEN or caller == voter;
    };
  };
  
};