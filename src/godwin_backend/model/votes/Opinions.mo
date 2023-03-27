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

  type Cursor            = Types.Cursor;
  type Polarization              = Types.Polarization;
  type BallotAggregator    = BallotAggregator.BallotAggregator<Cursor, Polarization>;
  type OpenVote       = OpenVote.OpenVote<Cursor, Polarization>;
  type PutBallot      = PutBallot.PutBallot<Cursor, Polarization>;
  type CloseVote     = CloseVote.CloseVote<Cursor, Polarization>;
  type ReadVote            = ReadVote.ReadVote<Cursor, Polarization>;

  type QuestionVoteHistory = QuestionVoteHistory.QuestionVoteHistory;
  
  public type VoteRegister = Votes.VoteRegister<Cursor, Polarization>;
  public type Vote         = Types.Vote<Cursor, Polarization>;
  public type Ballot       = Types.Ballot<Cursor>;

  type PutBallotError      = Types.PutBallotError;
  type CloseVoteError      = Types.CloseVoteError;
  type GetVoteError        = Types.GetVoteError;
  type GetBallotError = Types.GetBallotError;

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
    history_: QuestionVoteHistory,
    _open_vote_interface: OpenVote,
    _put_ballot_interface: PutBallot,
    _close_vote_interface: CloseVote,
    _read_vote_interface: ReadVote
  ) {
    
    public func openVote(question_id: Nat) {
      let vote_id = _open_vote_interface.openVote();
      history_.addVote(question_id, vote_id);
    };

    public func getBallot(principal: Principal, question_id: Nat) : Result<Ballot, GetBallotError> {
      switch(history_.findCurrentVote(question_id)) {
        case (null) { #err(#VoteNotFound); }; // @todo
        case (?vote_id) {
          _read_vote_interface.getBallot(principal, vote_id);
        };
      };
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      switch(history_.findCurrentVote(question_id)) {
        case (null) { #err(#VoteClosed); }; // @todo
        case (?vote_id) {
          _put_ballot_interface.putBallot(principal, vote_id, {date; answer = cursor;});
        };
      };
    };

     public func closeVote(question_id: Nat) : Result<Vote, CloseVoteError> {
      _close_vote_interface.closeVote(history_.closeCurrentVote(question_id));
    };

    public func revealVote(question_id: Nat, iteration: Nat) : Result<Vote, GetVoteError> {
      switch(history_.findHistoricalVote(question_id, iteration)) {
        case (null) { #err(#VoteNotFound); };
        case (?vote_id) {
          _read_vote_interface.revealVote(vote_id);
        };
      };
    };

  };

};