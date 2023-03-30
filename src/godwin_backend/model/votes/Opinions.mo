import Types               "../Types";
import Votes               "Votes"; 
import BallotAggregator    "BallotAggregator";
import Polarization        "representation/Polarization";
import Cursor             "representation/Cursor";
import OpenVote            "interfaces/OpenVote";
import PutBallot           "interfaces/PutBallot";
import ReadVote            "interfaces/ReadVote";
import CloseVote           "interfaces/CloseVote";
import QuestionVoteHistory "../QuestionVoteHistory";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";

module {

  type Result<Ok, Err>     = Result.Result<Ok, Err>;
  type Map<K, V>           = Map.Map<K, V>;
  type Time                = Int;

  type Cursor              = Types.Cursor;
  type Polarization        = Types.Polarization;
  type BallotAggregator    = BallotAggregator.BallotAggregator<Cursor, Polarization>;
  type OpenVote            = OpenVote.OpenVote<Cursor, Polarization>;
  type PutBallot           = PutBallot.PutBallot<Cursor, Polarization>;
  type CloseVote           = CloseVote.CloseVote<Cursor, Polarization>;
  type ReadVote            = ReadVote.ReadVote<Cursor, Polarization>;
  type QuestionVoteHistory = QuestionVoteHistory.QuestionVoteHistory;
  
  public type VoteRegister = Votes.VoteRegister<Cursor, Polarization>;
  public type Vote         = Types.Vote<Cursor, Polarization>;
  public type Ballot       = Types.Ballot<Cursor>;

  type PutBallotError      = Types.PutBallotError;
  type CloseVoteError      = Types.CloseVoteError;
  type GetVoteError        = Types.GetVoteError;
  type GetBallotError      = Types.GetBallotError;
  type RevealVoteError     = Types.RevealVoteError;

  public func initVoteRegister() : VoteRegister {
    Votes.initRegister<Cursor, Polarization>();
  };

  public func build(
    votes: Votes.Votes<Cursor, Polarization>,
    history: QuestionVoteHistory
  ) : Opinions {
    let ballot_aggregator = BallotAggregator.BallotAggregator<Cursor, Polarization>(
      Cursor.isValid,
      Polarization.addCursor,
      Polarization.subCursor
    );
    Opinions(
      history,
      OpenVote.OpenVote<Cursor, Polarization>(votes),
      PutBallot.PutBallot<Cursor, Polarization>(votes, ballot_aggregator),
      CloseVote.CloseVote<Cursor, Polarization>(votes),
      ReadVote.ReadVote<Cursor, Polarization>(votes)
    );
  };

  public class Opinions(
    _history: QuestionVoteHistory,
    _open_vote_interface: OpenVote,
    _put_ballot_interface: PutBallot,
    _close_vote_interface: CloseVote,
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

    public func putBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      Result.chain(_history.findCurrentVote(question_id), func(vote_id: Nat) : Result<(), PutBallotError> {
        _put_ballot_interface.putBallot(principal, vote_id, {date; answer = cursor;});
      });
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