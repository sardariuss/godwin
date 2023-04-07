import Types               "../Types";
import Utils               "../../utils/Utils";
import SubaccountGenerator "../token/SubaccountGenerator";
import Categories "../Categories";
import Votes               "Votes"; 
import BallotAggregator    "BallotAggregator";
import PolarizationMap              "representation/PolarizationMap";
import CursorMap            "representation/CursorMap";
import OpenVote            "interfaces/OpenVote";
import PutBallot           "interfaces/PutBallot";
import ReadVote            "interfaces/ReadVote";
import CloseVote           "interfaces/CloseVote";

import QuestionVoteHistory "../QuestionVoteHistory";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Buffer             "mo:base/Buffer";

module {

  type Result<Ok, Err>     = Result.Result<Ok, Err>;
  type Map<K, V>           = Map.Map<K, V>;
  type Time                = Int;

  type Categories             = Categories.Categories;
  type CursorMap              = Types.CursorMap;
  type PolarizationMap        = Types.PolarizationMap;
  type SubaccountGenerator    = SubaccountGenerator.SubaccountGenerator;
  type BallotAggregator       = BallotAggregator.BallotAggregator<CursorMap, PolarizationMap>;
  type OpenVote               = OpenVote.OpenVote<CursorMap, PolarizationMap>;
  type PutBallotPayin         = PutBallot.PutBallotPayin<CursorMap, PolarizationMap>;
  type CloseRedistributeVote        = CloseVote.CloseRedistributeVote<CursorMap, PolarizationMap>;
  type ReadVote               = ReadVote.ReadVote<CursorMap, PolarizationMap>;

  type QuestionVoteHistory = QuestionVoteHistory.QuestionVoteHistory;
  
  public type VoteRegister = Votes.VoteRegister<CursorMap, PolarizationMap>;
  public type Vote         = Types.Vote<CursorMap, PolarizationMap>;
  public type Ballot       = Types.Ballot<CursorMap>;

  type PutBallotError      = Types.PutBallotError;
  type CloseVoteError      = Types.CloseVoteError;
  type GetVoteError        = Types.GetVoteError;
  type GetBallotError      = Types.GetBallotError;
  type CursorArray         = Types.CursorArray;
  type PolarizationArray   = Types.PolarizationArray;
  type RevealVoteError     = Types.RevealVoteError;

  public type PublicVote = {
    id: Nat;
    status: Types.VoteStatus;
    ballots: [(Principal, Types.Ballot<CursorArray>)];
    aggregate: PolarizationArray;
  };

  public func toPublicVote(vote: Vote) : PublicVote {
    
    let ballots = Buffer.Buffer<(Principal, Types.Ballot<CursorArray>)>(Map.size(vote.ballots));
    for ((principal, ballot) in Map.entries(vote.ballots)) {
      ballots.add((principal, { date = ballot.date; answer = Utils.trieToArray(ballot.answer); }));
    };

    {
      id = vote.id;
      status = vote.status;
      ballots = Buffer.toArray(ballots);
      aggregate = Utils.trieToArray(vote.aggregate);
    };
  };

  public func initVoteRegister() : VoteRegister {
    Votes.initRegister<CursorMap, PolarizationMap>();
  };

  public func build(
    categories: Categories,
    votes: Votes.Votes<CursorMap, PolarizationMap>,
    history: QuestionVoteHistory,
    subaccounts: Map<Nat, Blob>,
    generator: SubaccountGenerator,
    payin: (Principal, Blob) -> async* Result<(), Text>,
    payout: (Vote, Blob) -> ()
  ) : Categorizations {
    let ballot_aggregator = BallotAggregator.BallotAggregator<CursorMap, PolarizationMap>(
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
    Categorizations(
      history,
      OpenVote.OpenVote<CursorMap, PolarizationMap>(votes),
      PutBallot.PutBallotPayin<CursorMap, PolarizationMap>(votes, ballot_aggregator, #PUT_CATEGORIZATION_BALLOT, payin),
      CloseVote.CloseRedistributeVote<CursorMap, PolarizationMap>(votes, #PUT_CATEGORIZATION_BALLOT, payout),
      ReadVote.ReadVote<CursorMap, PolarizationMap>(votes)
    );
  };

  public class Categorizations(
    _history: QuestionVoteHistory,
    _open_vote_interface: OpenVote,
    _put_ballot_interface: PutBallotPayin,
    _close_vote_interface: CloseRedistributeVote,
    _read_vote_interface: ReadVote
  ) {
    
    public func openVote(question_id: Nat) {
      let vote_id = _open_vote_interface.openVote();
      _history.addVote(question_id, vote_id);
    };

    public func getBallot(principal: Principal, question_id: Nat) : Result<Ballot, GetBallotError> {
      Result.chain(_history.findCurrentVote(question_id), func(vote_id: Nat) : Result<Ballot, GetBallotError> {
        _read_vote_interface.getBallot(principal, vote_id);
      });
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, cursor_map: CursorMap) : async* Result<(), PutBallotError> {
      switch(_history.findCurrentVote(question_id)) {
        case (#err(err)) { #err(err); };
        case (#ok(vote_id)) {
          await* _put_ballot_interface.putBallot(principal, vote_id, {date; answer = cursor_map;});
        };
      };
    };

    public func closeVote(question_id: Nat) : Result<Vote, CloseVoteError> {
      _close_vote_interface.closeVote(_history.closeCurrentVote(question_id));
    };

    public func revealVote(question_id: Nat, iteration: Nat) : Result<Vote, RevealVoteError> {
      Result.chain(_history.findHistoricalVote(question_id, iteration), func(vote_id: Nat) : Result<Vote, RevealVoteError> {
        _read_vote_interface.getVote(vote_id);
      });
    };
  
  };

};