import Types               "Types";
import Votes               "Votes";
import VotesHistory        "VotesHistory";
import BallotAggregator    "BallotAggregator";
import Polarization        "representation/Polarization";
import Cursor              "representation/Cursor";

import Result              "mo:base/Result";

module {

  type Result<Ok, Err>     = Result.Result<Ok, Err>;
  type Time                = Int;

  type Cursor              = Types.Cursor;
  type Polarization        = Types.Polarization;  
  type PutBallotError      = Types.PutBallotError;
  type CloseVoteError      = Types.CloseVoteError;
  type GetVoteError        = Types.GetVoteError;
  type GetBallotError      = Types.GetBallotError;
  type RevealVoteError     = Types.RevealVoteError;
  type Ballot              = Types.Ballot<Cursor>;
  type Vote                = Types.Vote<Cursor, Polarization>;

  type BallotAggregator    = BallotAggregator.BallotAggregator<Cursor, Polarization>;
  type VotesHistory = VotesHistory.VotesHistory;

  public type Register     = Votes.Register<Cursor, Polarization>;

  public func initRegister() : Register {
    Votes.initRegister<Cursor, Polarization>();
  };

  public func build(
    votes: Votes.Votes<Cursor, Polarization>,
    history: VotesHistory
  ) : Opinions {
    Opinions(
      votes,
      BallotAggregator.BallotAggregator<Cursor, Polarization>(
        Cursor.isValid,
        Polarization.addCursor,
        Polarization.subCursor
      ),
      history);
  };

  public class Opinions(
    _votes: Votes.Votes<Cursor, Polarization>,
    _aggregator: BallotAggregator, // @todo: shall the aggregator be part of the votes module?
    _history: VotesHistory
  ) {
    
    public func openVote(question_id: Nat) {
      let vote_id = _votes.newVote();
      _history.addVote(question_id, vote_id);
    };

    public func closeVote(question_id: Nat) {
      ignore _history.closeCurrentVote(question_id);
    };

    public func getBallot(principal: Principal, question_id: Nat) : Result<Ballot, GetBallotError> {
      Result.chain(_history.findCurrentVote(question_id), func(vote_id: Nat) : Result<Ballot, GetBallotError> {
        _votes.getBallot(principal, vote_id);
      });
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      Result.chain(_history.findCurrentVote(question_id), func(vote_id: Nat) : Result<(), PutBallotError> {
        let vote = _votes.getVote(vote_id);
        switch(_aggregator.putBallot(vote, principal, {date; answer = cursor;})){
          case(#ok(_)) { #ok; };
          case(#err(err)) { #err(err); };
        };
      });
    };

    public func revealVote(question_id: Nat, iteration: Nat) : Result<Vote, RevealVoteError> {
      Result.mapOk(_history.findHistoricalVote(question_id, iteration), func(vote_id: Nat) : Vote {
        _votes.getVote(vote_id);
      });
    };

  };

};