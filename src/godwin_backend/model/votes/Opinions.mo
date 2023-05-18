import Types               "Types";
import Votes               "Votes";
import QuestionVoteJoins   "QuestionVoteJoins";
import BallotAggregator    "BallotAggregator";
import Polarization        "representation/Polarization";
import Cursor              "representation/Cursor";

import Set                 "mo:map/Set";
import Map                 "mo:map/Map";

import Result              "mo:base/Result";

module {

  type Result<Ok, Err>     = Result.Result<Ok, Err>;
  type Time                = Int;
  type Set<K>              = Set.Set<K>;
  type Map<K, V>           = Map.Map<K, V>;

  type VoteId              = Types.VoteId;
  type Cursor              = Types.Cursor;
  type Polarization        = Types.Polarization;  
  type PutBallotError      = Types.PutBallotError;
  type CloseVoteError      = Types.CloseVoteError;
  type GetVoteError        = Types.GetVoteError;
  type FindBallotError      = Types.FindBallotError;
  type RevealVoteError     = Types.RevealVoteError;
  type Ballot              = Types.Ballot<Cursor>;
  type Vote                = Types.Vote<Cursor, Polarization>;
  type UpdateAggregate     = Types.UpdateAggregate<Cursor, Polarization>;

  type QuestionVoteJoins   = QuestionVoteJoins.QuestionVoteJoins;

  public type Register     = Votes.Register<Cursor, Polarization>;

  public func initRegister() : Register {
    Votes.initRegister<Cursor, Polarization>();
  };

  public func build(
    votes: Votes.Votes<Cursor, Polarization>,
    joins: QuestionVoteJoins
  ) : Opinions {
    Opinions(
      votes,
      BallotAggregator.makeUpdateAggregate<Cursor, Polarization>(Polarization.addCursor, Polarization.subCursor),
      joins);
  };

  public class Opinions(
    _votes: Votes.Votes<Cursor, Polarization>,
    _update_aggregate: UpdateAggregate, // @todo: shall the aggregator be part of the votes module?
    _joins: QuestionVoteJoins
  ) {
    
    public func openVote(question_id: Nat, iteration: Nat) {
      let vote_id = _votes.newVote();
      _joins.addJoin(question_id, iteration, vote_id);
    };

    public func closeVote(vote_id: VoteId) {
      _votes.closeVote(vote_id);
    };

    public func putBallot(principal: Principal, vote_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      _votes.putBallot(principal, vote_id, {date; answer = cursor;}, _update_aggregate);
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

    public func getVoterBallots(principal: Principal, vote_ids: Set<VoteId>) : Map<VoteId, Ballot> {
      _votes.getVoterBallots(principal, vote_ids);
    };

    public func getVoterHistory(principal: Principal) : Set<VoteId> {
      _votes.getVoterHistory(principal);
    };

  };

};