import Types               "Types";
import Votes               "Votes";
import VotePolicy          "VotePolicy";
import BallotInfos         "BallotInfos";
import QuestionVoteJoins   "QuestionVoteJoins";
import PayToVote           "PayToVote";
import BallotAggregator    "BallotAggregator";
import Polarization        "representation/Polarization";
import Cursor              "representation/Cursor";
import PayForNew           "../token/PayForNew";
import PayInterface        "../token/PayInterface";
import PayTypes            "../token/Types";
import QuestionTypes       "../questions/Types";
import QuestionQueries     "../questions/QuestionQueries";

import Set                 "mo:map/Set";
import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Float               "mo:base/Float";

module {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Time                   = Int;
  type Set<K>                 = Set.Set<K>;
  type Map<K, V>              = Map.Map<K, V>;
  
  type VoteId                 = Types.VoteId;
  type Cursor                 = Types.Cursor;
  type Polarization           = Types.Polarization;
  type Vote                   = Types.Vote<Cursor, Polarization>;
  type Ballot                 = Types.Ballot<Cursor>;
  type PutBallotError         = Types.PutBallotError;
  type FindBallotError        = Types.FindBallotError;
  type RevealVoteError        = Types.RevealVoteError;
  type OpenVoteError          = Types.OpenVoteError;
  type BallotTransactions     = Types.BallotTransactions;
  type Votes<T, A>            = Votes.Votes<T, A>;
  
  type QuestionVoteJoins      = QuestionVoteJoins.QuestionVoteJoins;
  type Question               = QuestionTypes.Question;
  type Key                    = QuestionTypes.Key;
  type QuestionQueries        = QuestionQueries.QuestionQueries;
  type PayInterface           = PayInterface.PayInterface;
  type PayForNew              = PayForNew.PayForNew;
  type PayoutError            = PayTypes.PayoutError;
  
  public type Register        = Votes.Register<Cursor, Polarization>;

  let { toInterestScore; } = QuestionQueries;

  let PRICE_OPENING_VOTE = 1000; // @todo
  let PRICE_PUT_BALLOT = 1000; // @todo

  public func initRegister() : Register {
    Votes.initRegister<Cursor, Polarization>();
  };

  public func build(
    vote_register: Votes.Register<Cursor, Polarization>,
    ballot_infos: Map<Principal, Map<VoteId, BallotTransactions>>,
    pay_interface: PayInterface,
    pay_for_new: PayForNew,
    joins: QuestionVoteJoins,
    queries: QuestionQueries
  ) : Interests {
    Interests(
      Votes.Votes(
        vote_register,
        VotePolicy.VotePolicy<Cursor, Polarization>(
          false, // _change_ballot_authorized
          Cursor.isValid,
          Polarization.addCursor,
          Polarization.subCursor,
          Polarization.nil()
        ),
        ?PayToVote.PayToVote<Cursor>(
          BallotInfos.BallotInfos(ballot_infos),
          pay_interface,
          #PUT_INTEREST_BALLOT,
          PRICE_PUT_BALLOT,
        )
      ),
      pay_for_new,
      joins,
      queries
    );
  };

  public class Interests(
    _votes: Votes<Cursor, Polarization>,
    _pay_for_new: PayForNew,
    _joins: QuestionVoteJoins,
    _queries: QuestionQueries
  ) {
    
    public func openVote(principal: Principal, on_success: () -> (Question, Nat)) : async* Result<Question, OpenVoteError> {
      let vote_id = switch(await* _pay_for_new.payNew(principal, PRICE_OPENING_VOTE, _votes.newVote)){
        case (#err(err)) { return #err(#PayinError(err)); };
        case (#ok(id)) { id; };
      };
      let (question, iteration) = on_success();
      // Add a join between the question and the vote
      _joins.addJoin(question.id, iteration, vote_id);
      // Update the associated key for the #INTEREST_SCORE order_by
      _queries.add(toInterestScore(question.id, computeScore(_votes.getVote(vote_id).aggregate)));
      #ok(question);
    };

    public func closeVote(vote_id: Nat) : async* () {
      // Close the vote
      await* _votes.closeVote(vote_id);
      // Remove the vote from the interest query
      _queries.remove(toInterestScore(
        _joins.getQuestionIteration(vote_id).0,
        computeScore(_votes.getVote(vote_id).aggregate))
      );
      // Pay out the buyer
      await* _pay_for_new.refund(vote_id, PRICE_OPENING_VOTE); // @todo: share;
    };

    public func putBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Cursor) : async* Result<(), PutBallotError> {    
      
      let old_appeal = _votes.getVote(vote_id).aggregate;

      Result.mapOk<(), (), PutBallotError>(await* _votes.putBallot(principal, vote_id, {date; answer = interest;}), func(){
        let new_appeal = _votes.getVote(vote_id).aggregate;
        let question_id = _joins.getQuestionIteration(vote_id).0;
        _queries.replace(?toInterestScore(question_id, computeScore(old_appeal)), ?toInterestScore(question_id, computeScore(new_appeal)));
      });
    };

    public func getBallot(principal: Principal, vote_id: VoteId) : Ballot {
      _votes.getBallot(principal, vote_id);
    };

    public func findBallot(principal: Principal, vote_id: VoteId) : Result<Ballot, FindBallotError> {
      _votes.findBallot(principal, vote_id);
    };

    public func revealVote(vote_id: VoteId) : Result<Vote, RevealVoteError> {
      _votes.revealVote(vote_id);
    };

    public func getVoterHistory(principal: Principal) : Set<VoteId> {
      _votes.getVoterHistory(principal);
    };

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