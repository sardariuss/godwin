import Types               "../Types";
import SubaccountGenerator "../token/SubaccountGenerator";
import Votes               "Votes"; 
import BallotAggregator    "BallotAggregator";
import Appeal              "representation/Appeal";
import OpenVote            "interfaces/OpenVote";
import PutBallot           "interfaces/PutBallot";
import ReadVote            "interfaces/ReadVote";
import CloseVote           "interfaces/CloseVote";
import QuestionVoteHistory "../QuestionVoteHistory";
import QuestionQueries     "../QuestionQueries";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Array               "mo:base/Array";

module {

  type Result<Ok, Err>     = Result.Result<Ok, Err>;
  type Map<K, V>           = Map.Map<K, V>;
  type Time                = Int;

  type Interest            = Types.Interest;
  type PutBallotError      = Types.PutBallotError;
  type CloseVoteError      = Types.CloseVoteError;
  type GetVoteError        = Types.GetVoteError;
  type GetBallotError = Types.GetBallotError;
  type Appeal              = Types.Appeal;
  type SubaccountGenerator = SubaccountGenerator.SubaccountGenerator;
  type BallotAggregator    = BallotAggregator.BallotAggregator<Interest, Appeal>;
  type OpenVotePayin       = OpenVote.OpenVotePayin<Interest, Appeal>;
  type PutBallotPayin      = PutBallot.PutBallotPayin<Interest, Appeal>;
  type CloseVotePayout     = CloseVote.CloseVotePayout<Interest, Appeal>;
  type ReadVote            = ReadVote.ReadVote<Interest, Appeal>;
  type QuestionVoteHistory = QuestionVoteHistory.QuestionVoteHistory;
  type Question            = Types.Question;
  type QuestionQueries     = QuestionQueries.QuestionQueries;
  type OpenVoteError       = Types.OpenVoteError;
  type RevealVoteError     = Types.RevealVoteError;
  
  public type VoteRegister = Votes.VoteRegister<Interest, Appeal>;
  public type HistoryRegister = QuestionVoteHistory.Register;
  public type Vote         = Types.Vote<Interest, Appeal>;
  public type Ballot       = Types.Ballot<Interest>;

  type Key = QuestionQueries.Key;
  let { toAppealScore; } = QuestionQueries;

  public func initVoteRegister() : VoteRegister {
    Votes.initRegister<Interest, Appeal>();
  };

  public func build(
    votes: Votes.Votes<Interest, Appeal>,
    history: QuestionVoteHistory,
    queries: QuestionQueries,
    subaccounts: Map<Nat, Blob>,
    generator: SubaccountGenerator,
    payin: (Principal, Blob) -> async* Result<(), ()>,
    payout: (Vote, Blob) -> ()
  ) : Interests {
    let ballot_aggregator = BallotAggregator.BallotAggregator<Interest, Appeal>(
      func(interest: Interest) : Bool { true; }, // enum type cannot be invalid
      Appeal.add,
      Appeal.remove
    );
    Interests(
      votes,
      history,
      queries,
      OpenVote.OpenVotePayin<Interest, Appeal>(votes, subaccounts, generator, payin),
      PutBallot.PutBallotPayin<Interest, Appeal>(votes, ballot_aggregator, subaccounts, payin),
      CloseVote.CloseVotePayout<Interest, Appeal>(votes, subaccounts, payout),
      ReadVote.ReadVote<Interest, Appeal>(votes)
    );
  };

  public class Interests(
    votes_: Votes.Votes<Interest, Appeal>,
    _history: QuestionVoteHistory,
    queries_: QuestionQueries,
    _open_vote_interface: OpenVotePayin,
    _put_ballot_interface: PutBallotPayin,
    _close_vote_interface: CloseVotePayout,
    _read_vote_interface: ReadVote
  ) {
    
    public func openVote(principal: Principal, on_success: () -> Question) : async* Result<Question, OpenVoteError> {
      Result.mapOk(await* _open_vote_interface.openVote(principal), func(vote_id: Nat) : Question {
        let question = on_success();
        _history.addVote(question.id, vote_id);
        // Update the associated key for the #INTEREST_SCORE order_by
        queries_.add(toAppealScore(question.id, votes_.getVote(vote_id).aggregate));
        question;
      });
    };

    public func getBallot(principal: Principal, question_id: Nat) : Result<Ballot, GetBallotError> {
      Result.chain(_history.findCurrentVote(question_id), func(vote_id: Nat) : Result<Ballot, GetBallotError> {
        _read_vote_interface.getBallot(principal, vote_id);
      });
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, interest: Interest) : async* Result<(), PutBallotError> {
      let vote_id = switch(_history.findCurrentVote(question_id)) {
        case (#err(err)) { return #err(err); };
        case (#ok(id)) { id; };
      };
      
      let old_appeal = votes_.getVote(vote_id).aggregate;

      Result.mapOk<(), (), PutBallotError>(await* _put_ballot_interface.putBallot(principal, vote_id, {date; answer = interest;}), func(){
        let new_appeal = votes_.getVote(vote_id).aggregate;
        queries_.replace(
          ?toAppealScore(question_id, old_appeal),
          ?toAppealScore(question_id, new_appeal)
        );
      });
    };

    public func closeVote(question_id: Nat) : Result<Vote, CloseVoteError> {
      switch(_close_vote_interface.closeVote(_history.closeCurrentVote(question_id))){
        case (#err(err)) { #err(err); };
        case (#ok(vote)) {
          queries_.remove(toAppealScore(question_id, vote.aggregate));
          #ok(vote);
        };
      };
    };

    public func revealVote(question_id: Nat, iteration: Nat) : Result<Vote, RevealVoteError> {
      Result.chain(_history.findHistoricalVote(question_id, iteration), func(vote_id: Nat) : Result<Vote, RevealVoteError> {
        _read_vote_interface.getVote(vote_id);
      });
    };

  };

};