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
import WRef                "../../utils/wrappers/WRef";
import Ref                 "../../utils/Ref";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Array               "mo:base/Array";

module {

  type Result<Ok, Err>     = Result.Result<Ok, Err>;
  type Map<K, V>           = Map.Map<K, V>;
  type Time                = Int;
  type Ref<T>              = Ref.Ref<T>;
  type WRef<T>             = WRef.WRef<T>;

  type Interest            = Types.Interest;
  type PutBallotError      = Types.PutBallotError;
  type CloseVoteError      = Types.CloseVoteError;
  type GetVoteError        = Types.GetVoteError;
  type GetBallotError = Types.GetBallotError;
  type Appeal              = Types.Appeal;
  type SubaccountGenerator = SubaccountGenerator.SubaccountGenerator;
  type BallotAggregator    = BallotAggregator.BallotAggregator<Interest, Appeal>;
  type OpenPayableVote       = OpenVote.OpenPayableVote<Interest, Appeal>;
  type PutBallotPayin      = PutBallot.PutBallotPayin<Interest, Appeal>;
  type ClosePayableVote     = CloseVote.ClosePayableVote<Interest, Appeal>;
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
    subaccount_index: Ref<Nat>,
    payin: (Principal, Blob) -> async* Result<(), Text>,
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
      OpenVote.OpenPayableVote<Interest, Appeal>(votes, subaccounts, WRef.WRef(subaccount_index), payin),
      PutBallot.PutBallotPayin<Interest, Appeal>(votes, ballot_aggregator, #PUT_INTEREST_BALLOT, payin),
      CloseVote.ClosePayableVote<Interest, Appeal>(votes, subaccounts, #PUT_INTEREST_BALLOT, payout),
      ReadVote.ReadVote<Interest, Appeal>(votes)
    );
  };

  public class Interests(
    _votes: Votes.Votes<Interest, Appeal>,
    _history: QuestionVoteHistory,
    _queries: QuestionQueries,
    _open_vote_interface: OpenPayableVote,
    _put_ballot_interface: PutBallotPayin,
    _close_vote_interface: ClosePayableVote,
    _read_vote_interface: ReadVote
  ) {
    
    public func openVote(principal: Principal, on_success: () -> Question) : async* Result<Question, OpenVoteError> {
      Result.mapOk(await* _open_vote_interface.openVote(principal), func(vote_id: Nat) : Question {
        let question = on_success();
        _history.addVote(question.id, vote_id);
        // Update the associated key for the #INTEREST_SCORE order_by
        _queries.add(toAppealScore(question.id, _votes.getVote(vote_id).aggregate));
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
      
      let old_appeal = _votes.getVote(vote_id).aggregate;

      Result.mapOk<(), (), PutBallotError>(await* _put_ballot_interface.putBallot(principal, vote_id, {date; answer = interest;}), func(){
        let new_appeal = _votes.getVote(vote_id).aggregate;
        _queries.replace(
          ?toAppealScore(question_id, old_appeal),
          ?toAppealScore(question_id, new_appeal)
        );
      });
    };

    public func closeVote(question_id: Nat) : Result<Vote, CloseVoteError> {
      switch(_close_vote_interface.closeVote(_history.closeCurrentVote(question_id))){
        case (#err(err)) { #err(err); };
        case (#ok(vote)) {
          _queries.remove(toAppealScore(question_id, vote.aggregate));
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