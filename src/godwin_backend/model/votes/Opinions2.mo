import Types               "../Types";
import Votes               "Votes2"; 
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
    register: VoteRegister,
    history: QuestionVoteHistory
  ) : Opinions {
    let votes = Votes.Votes2<Cursor, Polarization>(register, Polarization.nil());
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
    open_vote_interface_: OpenVote,
    put_ballot_interface_: PutBallot,
    close_vote_interface_: CloseVote,
    read_vote_interface_: ReadVote
  ) {
    
    public func openVote(question_id: Nat) {
      let vote_id = open_vote_interface_.openVote();
      history_.addVote(question_id, vote_id);
    };

    public func getBallot(principal: Principal, question_id: Nat) : Result<Ballot, GetBallotError> {
      switch(history_.getCurrentVote(question_id)) {
        case (null) { #err(#VoteNotFound); }; // @todo
        case (?vote_id) {
          read_vote_interface_.getBallot(principal, vote_id);
        };
      };
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      switch(history_.getCurrentVote(question_id)) {
        case (null) { #err(#VoteClosed); }; // @todo
        case (?vote_id) {
          put_ballot_interface_.putBallot(principal, vote_id, {date; answer = cursor;});
        };
      };
    };

     public func closeVote(question_id: Nat) : Result<(), CloseVoteError> {
      switch(history_.getCurrentVote(question_id)) {
        case (null) { #err(#AlreadyClosed); }; // @todo
        case (?vote_id) {
          close_vote_interface_.closeVote(vote_id);
        };
      };
    };

    public func revealVote(question_id: Nat, iteration: Nat) : Result<Vote, GetVoteError> {
      switch(history_.getHistoricalVote(question_id, iteration)) {
        case (null) { #err(#VoteNotFound); };
        case (?vote_id) {
          read_vote_interface_.revealVote(vote_id);
        };
      };
    };
    
  };

};