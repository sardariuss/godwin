import Types               "Types";
import Votes               "Votes";
import VotePolicy          "VotePolicy";
import QuestionVoteJoins   "QuestionVoteJoins";
import PayToVote           "PayToVote";
import Appeal              "representation/Appeal";
import Interest            "representation/Interest";
import PayForNew           "../token/PayForNew";
import PayTypes            "../token/Types";
import PayForElement       "../token/PayForElement";
import QuestionTypes       "../questions/Types";
import QuestionQueries     "../questions/QuestionQueries";

import UtilsTypes          "../../utils/Types";

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
  type Vote                   = Types.Vote<Interest, Appeal>;
  type Ballot                 = Types.Ballot<Interest>;
  type PutBallotError         = Types.PutBallotError;
  type FindBallotError        = Types.FindBallotError;
  type RevealVoteError        = Types.RevealVoteError;
  type OpenVoteError          = Types.OpenVoteError;
  type Interest               = Types.Interest;
  type Appeal                 = Types.Appeal;
  type BallotPayout           = Types.BallotPayout;
  type Votes<T, A>            = Votes.Votes<T, A>;
  
  type QuestionVoteJoins      = QuestionVoteJoins.QuestionVoteJoins;
  type Question               = QuestionTypes.Question;
  type Key                    = QuestionTypes.Key;
  type QuestionQueries        = QuestionQueries.QuestionQueries;
  type IPayInterface          = PayTypes.IPayInterface;
  type PayForNew              = PayForNew.PayForNew;
  type TransactionsRecord     = PayTypes.TransactionsRecord;

  type ScanLimitResult<K>     = UtilsTypes.ScanLimitResult<K>;
  type Direction              = UtilsTypes.Direction;
  
  public type Register        = Votes.Register<Interest, Appeal>;

  let { toInterestScore; } = QuestionQueries;

  let PRICE_OPENING_VOTE = 1000; // @todo
  let PRICE_PUT_BALLOT = 1000; // @todo

  public func initRegister() : Register {
    Votes.initRegister<Interest, Appeal>();
  };

  public func build(
    vote_register: Votes.Register<Interest, Appeal>,
    transactions_register: Map<Principal, Map<VoteId, TransactionsRecord>>,
    pay_interface: IPayInterface,
    pay_for_new: PayForNew,
    joins: QuestionVoteJoins,
    queries: QuestionQueries
  ) : Interests {
    Interests(
      Votes.Votes(
        vote_register,
        VotePolicy.VotePolicy<Interest, Appeal>(
          #BALLOT_CHANGE_FORBIDDEN,
          Interest.isValid,
          Appeal.addInterest,
          Appeal.subInterest,
          Appeal.nil()
        ),
        ?PayToVote.PayToVote<Interest, Appeal>(
          PayForElement.build(
            transactions_register,
            pay_interface,
            #PUT_INTEREST_BALLOT,
          ),
          PRICE_PUT_BALLOT,
          computePayout
        )
      ),
      pay_for_new,
      joins,
      queries
    );
  };

  public class Interests(
    _votes: Votes<Interest, Appeal>,
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
      _queries.add(toInterestScore(question.id, _votes.getVote(vote_id).aggregate.score));
      #ok(question);
    };

    public func closeVote(vote_id: Nat) : async* () {
      // Close the vote
      await* _votes.closeVote(vote_id);
      // Remove the vote from the interest query
      _queries.remove(toInterestScore(_joins.getQuestionIteration(vote_id).0, _votes.getVote(vote_id).aggregate.score));
      // Pay out the buyer
      await* _pay_for_new.refund(vote_id, PRICE_OPENING_VOTE); // @todo: share;
    };

    public func putBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Interest) : async* Result<(), PutBallotError> {    
      
      let old_appeal = _votes.getVote(vote_id).aggregate.score;

      Result.mapOk<(), (), PutBallotError>(await* _votes.putBallot(principal, vote_id, {date; answer = interest;}), func(){
        let new_appeal = _votes.getVote(vote_id).aggregate.score;
        let question_id = _joins.getQuestionIteration(vote_id).0;
        _queries.replace(?toInterestScore(question_id, old_appeal), ?toInterestScore(question_id, new_appeal));
      });
    };

    public func findBallot(principal: Principal, vote_id: VoteId) : Result<Ballot, FindBallotError> {
      _votes.findBallot(principal, vote_id);
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

    public func revealBallots(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : ScanLimitResult<(VoteId, ?Ballot, ?TransactionsRecord)> {
      _votes.revealBallots(principal, direction, limit, previous_id);
    };

  };

  // @todo
  func computePayout(answer: Interest, appeal: Appeal) : BallotPayout {
    {
      refund_share = 1.0;
      reward_tokens = 0;
    };
  };

};