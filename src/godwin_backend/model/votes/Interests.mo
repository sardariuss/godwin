import Types               "../Types";
import SubaccountGenerator "../token/SubaccountGenerator";
import PayForNew           "../token/PayForNew";
import PayInterface        "../token/PayInterface";
import Votes               "Votes";
import PayToVote           "PayToVote";
import BallotAggregator    "BallotAggregator";
import Appeal              "representation/Appeal";
import QuestionVoteHistory "../QuestionVoteHistory";
import QuestionQueries     "../QuestionQueries";
import WRef                "../../utils/wrappers/WRef";
import Ref                 "../../utils/Ref";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Array               "mo:base/Array";

module {

  type Result<Ok, Err>     = Result.Result<Ok, Err>;
  type Map<K, V>           = Map.Map<K, V>;
  type Time                = Int;
  type Ref<T>              = Ref.Ref<T>;
  type WRef<T>             = WRef.WRef<T>;

  type Interest            = Types.Interest;
  type Appeal              = Types.Appeal;
  type PutBallotError      = Types.PutBallotError;
  type GetBallotError      = Types.GetBallotError;
  type RevealVoteError     = Types.RevealVoteError;
  type OpenVoteError       = Types.OpenVoteError;
  
  type BallotAggregator    = BallotAggregator.BallotAggregator<Interest, Appeal>;
  type QuestionVoteHistory = QuestionVoteHistory.QuestionVoteHistory;
  type Question            = Types.Question;
  type QuestionQueries     = QuestionQueries.QuestionQueries;
  type PayInterface        = PayInterface.PayInterface;
  type PayForNew           = PayForNew.PayForNew;
  
  public type VoteRegister = Votes.VoteRegister<Interest, Appeal>;
  public type HistoryRegister = QuestionVoteHistory.Register;
  public type Vote         = Types.Vote<Interest, Appeal>;
  public type Ballot       = Types.Ballot<Interest>;

  type Key = QuestionQueries.Key;
  let { toAppealScore; } = QuestionQueries;

  let PRICE_OPENING_VOTE = 1000; // @todo
  let PRICE_PUT_BALLOT = 1000; // @todo

  public func initVoteRegister() : VoteRegister {
    Votes.initRegister<Interest, Appeal>();
  };

  public func build(
    votes: Votes.Votes<Interest, Appeal>,
    history: QuestionVoteHistory,
    queries: QuestionQueries,
    pay_interface: PayInterface,
    pay_for_new: PayForNew
  ) : Interests {
    let ballot_aggregator = BallotAggregator.BallotAggregator<Interest, Appeal>(
      func(interest: Interest) : Bool { true; }, // enum type cannot be invalid
      Appeal.add,
      Appeal.remove
    );
    Interests(
      PayToVote.PayToVote(votes, ballot_aggregator, pay_interface, #PUT_INTEREST_BALLOT),
      pay_for_new,
      history,
      queries
    );
  };

  public class Interests(
    _votes: PayToVote.PayToVote<Interest, Appeal>,
    _pay_for_new: PayForNew,
    _history: QuestionVoteHistory,
    _queries: QuestionQueries
  ) {
    
    public func openVote(principal: Principal, on_success: () -> Question) : async* Result<Question, OpenVoteError> {
      let vote_id = switch(await* _pay_for_new.payNew(principal, PRICE_OPENING_VOTE, _votes.newVote)){
        case (#err(err)) { return #err(#PayinError(err)); };
        case (#ok(id)) { id; };
      };
      let question = on_success();
      // Add to the question's vote history
      _history.addVote(question.id, vote_id);
      // Update the associated key for the #INTEREST_SCORE order_by
      _queries.add(toAppealScore(question.id, _votes.getVote(vote_id).aggregate));
      #ok(question);
    };

    public func closeVote(question_id: Nat) : async* () {
      let vote_id = _history.closeCurrentVote(question_id);
      let vote = _votes.getVote(vote_id);
      _queries.remove(toAppealScore(question_id, vote.aggregate));
      // 1. Pay out the buyer
      await* _pay_for_new.refund(vote_id, 1.0); // @todo: share;
      // 2. Pay out the voters
      await* _votes.payout(vote_id);
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, interest: Interest) : async* Result<(), PutBallotError> {
      let vote_id = switch(_history.findCurrentVote(question_id)) {
        case (#err(err)) { return #err(err); };
        case (#ok(id)) { id; };
      };
      
      let old_appeal = _votes.getVote(vote_id).aggregate;

      Result.mapOk<(), (), PutBallotError>(await* _votes.putBallot(principal, vote_id, {date; answer = interest;}, PRICE_PUT_BALLOT), func(){
        let new_appeal = _votes.getVote(vote_id).aggregate;
        _queries.replace(?toAppealScore(question_id, old_appeal), ?toAppealScore(question_id, new_appeal));
      });
    };

    public func getBallot(principal: Principal, question_id: Nat) : Result<Ballot, GetBallotError> {
      let vote_id = switch(_history.findCurrentVote(question_id)) {
        case (#err(err)) { return #err(err); };
        case (#ok(id)) { id; };
      };
      _votes.getBallot(principal, vote_id);
    };

    public func revealVote(question_id: Nat, iteration: Nat) : Result<Vote, RevealVoteError> {
      Result.mapOk(_history.findHistoricalVote(question_id, iteration), func(vote_id: Nat) : Vote {
        _votes.getVote(vote_id);
      });
    };

  };

};