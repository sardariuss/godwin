import Types               "Types";
import Votes               "Votes";
import VotesHistory        "VotesHistory";
import PayToVote           "PayToVote";
import BallotAggregator    "BallotAggregator";
import PolarizationMap     "representation/PolarizationMap";
import CursorMap           "representation/CursorMap";
import SubaccountGenerator "../token/SubaccountGenerator";
import PayInterface        "../token/PayInterface";
import Categories          "../Categories";

import Utils               "../../utils/Utils";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Buffer              "mo:base/Buffer";

module {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Time                   = Int;

  type Categories             = Categories.Categories;
  type BallotAggregator       = BallotAggregator.BallotAggregator<CursorMap, PolarizationMap>;
  type VotesHistory    = VotesHistory.VotesHistory;
  type PayToVote              = PayToVote.PayToVote<CursorMap, PolarizationMap>;
  type PayInterface           = PayInterface.PayInterface;
  type CursorMap              = Types.CursorMap;
  type PolarizationMap        = Types.PolarizationMap;
  type Vote                   = Types.Vote<CursorMap, PolarizationMap>;
  type Ballot                 = Types.Ballot<CursorMap>;
  type PutBallotError         = Types.PutBallotError;
  type CloseVoteError         = Types.CloseVoteError;
  type GetVoteError           = Types.GetVoteError;
  type GetBallotError         = Types.GetBallotError;
  type RevealVoteError        = Types.RevealVoteError;

  public type Register    = Votes.Register<CursorMap, PolarizationMap>;

  let PRICE_PUT_BALLOT = 1000; // @todo

  public func initRegister() : Register {
    Votes.initRegister<CursorMap, PolarizationMap>();
  };

  public func build(
    categories: Categories,
    votes: Votes.Votes<CursorMap, PolarizationMap>,
    history: VotesHistory,
    pay_interface: PayInterface
  ) : Categorizations {
    let ballot_aggregator = BallotAggregator.BallotAggregator<CursorMap, PolarizationMap>(
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
    Categorizations(
      PayToVote.PayToVote(votes, ballot_aggregator, pay_interface, #PUT_CATEGORIZATION_BALLOT),
      history
    );
  };

  public class Categorizations(
    _votes: PayToVote,
    _history: VotesHistory
  ) {
    
    public func openVote(question_id: Nat) {
      let vote_id = _votes.newVote();
      _history.addVote(question_id, vote_id);
    };

    public func closeVote(question_id: Nat) : async*() {
      let vote_id = _history.closeCurrentVote(question_id);
      await* _votes.payout(vote_id);
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, cursor_map: CursorMap) : async* Result<(), PutBallotError> {
      let vote_id = switch(_history.findCurrentVote(question_id)) {
        case (#err(err)) { return #err(err); };
        case (#ok(id)) { id; };
      };
      await* _votes.putBallot(principal, vote_id, {date; answer = cursor_map;}, PRICE_PUT_BALLOT);
    };

    public func getBallot(principal: Principal, question_id: Nat) : Result<Ballot, GetBallotError> {
      Result.chain(_history.findCurrentVote(question_id), func(vote_id: Nat) : Result<Ballot, GetBallotError> {
        _votes.getBallot(principal, vote_id);
      });
    };

    public func revealVote(question_id: Nat, iteration: Nat) : Result<Vote, RevealVoteError> {
      Result.mapOk(_history.findHistoricalVote(question_id, iteration), func(vote_id: Nat) : Vote {
        _votes.getVote(vote_id);
      });
    };
  
  };

};