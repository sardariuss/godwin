import Types               "Types";
import Votes               "Votes";
import QuestionVoteJoins   "QuestionVoteJoins";
import PayToVote           "PayToVote";
import InterestRules       "InterestRules";
import PayRules            "../PayRules";
import PayForNew           "../token/PayForNew";
import PayTypes            "../token/Types";
import PayForElement       "../token/PayForElement";
import QuestionTypes       "../questions/Types";
import KeyConverter        "../questions/KeyConverter";

import UtilsTypes          "../../utils/Types";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Nat                 "mo:base/Nat";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";

module {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Time                   = Int;
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

  let HOTNESS_TIME_UNIT_NS = 86_400_000_000_000; // 24 hours in nanoseconds @todo: make this a parameter

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
          _queries.add(KeyConverter.toHotnessKey(question_id, _votes.getVote(vote_id).aggregate.hotness));
          #ok((question_id, vote_id));
        };
      };
    };

    public func closeVote(vote_id: Nat, date: Time) : async* () {
      // Close the vote
      await* _votes.closeVote(vote_id, date);
      let vote = _votes.getVote(vote_id);
      // Remove the vote from the interest query
      _queries.remove(KeyConverter.toHotnessKey(_joins.getQuestionIteration(vote_id).0, vote.aggregate.hotness));
      // Pay out the buyer
      let (refund_amount, reward_amount) = _pay_rules.computeOpenVotePayout(vote.aggregate, Map.size(vote.ballots));
      await* _pay_for_new.payout(vote_id, refund_amount, reward_amount);
    };

    public func putBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Interest) : async* Result<(), PutBallotError> {    
      
      let old_hotness = _votes.getVote(vote_id).aggregate.hotness;

      Result.mapOk<(), (), PutBallotError>(await* _votes.putBallot(principal, vote_id, {date; answer = interest;}), func(){
        let question_id = _joins.getQuestionIteration(vote_id).0;
        _queries.replace(
          ?KeyConverter.toHotnessKey(question_id, old_hotness),
          ?KeyConverter.toHotnessKey(question_id, _votes.getVote(vote_id).aggregate.hotness)
        );
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

    public func onPutBallot(appeal: Appeal, new_ballot: Ballot, old_ballot: ?Ballot) : Appeal {
      
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
  
};