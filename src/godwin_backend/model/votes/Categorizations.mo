import Types               "Types";
import Votes               "Votes";
import QuestionVoteJoins   "QuestionVoteJoins";
import PayToVote           "PayToVote";
import BallotAggregator    "BallotAggregator";
import PolarizationMap     "representation/PolarizationMap";
import CursorMap           "representation/CursorMap";
import SubaccountGenerator "../token/SubaccountGenerator";
import PayInterface        "../token/PayInterface";
import Categories          "../Categories";

import Utils               "../../utils/Utils";

import Map                 "mo:map/Map";
import Set                 "mo:map/Set";

import Result              "mo:base/Result";
import Buffer              "mo:base/Buffer";

module {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Time                   = Int;
  type Set<K>                 = Set.Set<K>;

  type Categories             = Categories.Categories;
  type BallotAggregator       = BallotAggregator.BallotAggregator<CursorMap, PolarizationMap>;
  type QuestionVoteJoins      = QuestionVoteJoins.QuestionVoteJoins;
  type PayToVote              = PayToVote.PayToVote<CursorMap, PolarizationMap>;
  type PayInterface           = PayInterface.PayInterface;
  
  type VoteId                 = Types.VoteId;
  type Vote                   = Types.Vote<CursorMap, PolarizationMap>;
  type CursorMap              = Types.CursorMap;
  type PolarizationMap        = Types.PolarizationMap;
  type Ballot                 = Types.Ballot<CursorMap>;
  type PutBallotError         = Types.PutBallotError;
  type CloseVoteError         = Types.CloseVoteError;
  type GetVoteError           = Types.GetVoteError;
  type FindBallotError         = Types.FindBallotError;
  type RevealVoteError        = Types.RevealVoteError;

  public type Register    = Votes.Register<CursorMap, PolarizationMap>;

  let PRICE_PUT_BALLOT = 1000; // @todo

  public func initRegister() : Register {
    Votes.initRegister<CursorMap, PolarizationMap>();
  };

  public func build(
    categories: Categories,
    votes: Votes.Votes<CursorMap, PolarizationMap>,
    joins: QuestionVoteJoins,
    pay_interface: PayInterface
  ) : Categorizations {
    let ballot_aggregator = BallotAggregator.BallotAggregator<CursorMap, PolarizationMap>(
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
    Categorizations(
      PayToVote.PayToVote(votes, ballot_aggregator, pay_interface, #PUT_CATEGORIZATION_BALLOT),
      joins
    );
  };

  public class Categorizations(
    _votes: PayToVote,
    _joins: QuestionVoteJoins
  ) {
    
    public func openVote(question_id: Nat, iteration: Nat) {
      let vote_id = _votes.newVote();
      _joins.addJoin(question_id, iteration, vote_id);
    };

    public func closeVote(vote_id: VoteId) : async*() {
      _votes.closeVote(vote_id);
      await* _votes.payout(vote_id);
    };

    public func getVote(id: VoteId) : Vote {
      _votes.getVote(id);
    };

    public func putBallot(principal: Principal, vote_id: VoteId, date: Time, cursor_map: CursorMap) : async* Result<(), PutBallotError> {
      await* _votes.putBallot(principal, vote_id, {date; answer = cursor_map;}, PRICE_PUT_BALLOT);
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

};