import Types               "../Types";
import Votes               "Votes";
import PayToVote           "PayToVote";
import BallotAggregator    "BallotAggregator";
import Polarization        "representation/Polarization";
import Cursor              "representation/Cursor";
import PayForNew           "../token/PayForNew";
import PayInterface        "../token/PayInterface";
import PayTypes            "../token/Types";
import QuestionVoteHistory "../QuestionVoteHistory";
import QuestionQueries     "../QuestionQueries";

import Result              "mo:base/Result";
import Float               "mo:base/Float";

module {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Time                   = Int;

  type VoteId                 = Types.VoteId;
  type Cursor                 = Types.Cursor;
  type Polarization           = Types.Polarization;
  type PutBallotError         = Types.PutBallotError;
  type GetBallotError         = Types.GetBallotError;
  type RevealVoteError        = Types.RevealVoteError;
  type OpenVoteError          = Types.OpenVoteError;
  
  type BallotAggregator       = BallotAggregator.BallotAggregator<Cursor, Polarization>;
  type QuestionVoteHistory    = QuestionVoteHistory.QuestionVoteHistory;
  type Question               = Types.Question;
  type QuestionQueries        = QuestionQueries.QuestionQueries;
  type PayInterface           = PayInterface.PayInterface;
  type PayForNew              = PayForNew.PayForNew;
  type PayoutError            = PayTypes.PayoutError;
  
  public type VoteRegister    = Votes.VoteRegister<Cursor, Polarization>;
  public type Vote            = Types.Vote<Cursor, Polarization>;
  public type Ballot          = Types.Ballot<Cursor>;

  type Key = QuestionQueries.Key;
  let { toInterestScore; } = QuestionQueries;

  let PRICE_OPENING_VOTE = 1000; // @todo
  let PRICE_PUT_BALLOT = 1000; // @todo

  public func initVoteRegister() : VoteRegister {
    Votes.initRegister<Cursor, Polarization>();
  };

  public func build(
    votes: Votes.Votes<Cursor, Polarization>,
    history: QuestionVoteHistory,
    queries: QuestionQueries,
    pay_interface: PayInterface,
    pay_for_new: PayForNew
  ) : Interests {
    let ballot_aggregator = BallotAggregator.BallotAggregator<Cursor, Polarization>(
      Cursor.isValid,
      Polarization.addCursor,
      Polarization.subCursor
    );
    Interests(
      PayToVote.PayToVote(votes, ballot_aggregator, pay_interface, #PUT_INTEREST_BALLOT),
      pay_for_new,
      history,
      queries
    );
  };

  public class Interests(
    _votes: PayToVote.PayToVote<Cursor, Polarization>,
    _pay_for_new: PayForNew,
    _history: QuestionVoteHistory,
    _queries: QuestionQueries
  ) {
    
    public func openVote(principal: Principal, on_success: () -> Question) : async* Result<Question, OpenVoteError> {
      let vote_id = switch(await* _pay_for_new.payNew(principal, PRICE_OPENING_VOTE, _votes.newVote)){
        case (#err(err)) { return #err(#PayInError(err)); };
        case (#ok(id)) { id; };
      };
      let question = on_success();
      // Add to the question's vote history
      _history.addVote(question.id, vote_id);
      // Update the associated key for the #INTEREST_SCORE order_by
      _queries.add(toInterestScore(question.id, computeScore(_votes.getVote(vote_id).aggregate)));
      #ok(question);
    };

    public func closeVote(question_id: Nat) : async* () {
      let vote_id = _history.closeCurrentVote(question_id);
      let vote = _votes.getVote(vote_id);
      _queries.remove(toInterestScore(question_id, computeScore(vote.aggregate)));
      // 1. Pay out the buyer
      await* _pay_for_new.refund(vote_id, 1.0); // @todo: share;
      // 2. Pay out the voters
      await* _votes.payout(vote_id);
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, interest: Cursor) : async* Result<(), PutBallotError> {
      let vote_id = switch(_history.findCurrentVote(question_id)) {
        case (#err(err)) { return #err(err); };
        case (#ok(id)) { id; };
      };
      
      let old_appeal = _votes.getVote(vote_id).aggregate;

      Result.mapOk<(), (), PutBallotError>(await* _votes.putBallot(principal, vote_id, {date; answer = interest;}, PRICE_PUT_BALLOT), func(){
        let new_appeal = _votes.getVote(vote_id).aggregate;
        _queries.replace(?toInterestScore(question_id, computeScore(old_appeal)), ?toInterestScore(question_id, computeScore(new_appeal)));
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

  // @todo
//    public func getFailedRefunds() : [(VoteId, PayoutError)] {
//      _pay_for_new.getFailedRefunds();
//    };

  };

  func computeScore(polarization: Polarization) : Float {
    let { left; right; } = polarization;
    let total = left + right;
    if (total == 0.0) { return 0.0; };
    let x = right / total;
    let growth_rate = 20.0;
    let mid_point = 0.5;
    // https://stackoverflow.com/a/3787645: this will underflow to 0 for large negative values of x,
    // but that may be OK depending on your context since the exact result is nearly zero in that case.
    let sigmoid = (2.0 / (1.0 + Float.exp(-1.0 * growth_rate * (x - mid_point)))) - 1.0;
    total * sigmoid;
  };

};