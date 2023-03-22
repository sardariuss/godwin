import Types               "../Types";
import SubaccountGenerator "../token/SubaccountGenerator";
import Votes               "Votes2"; 
import BallotAggregator    "BallotAggregator";
import Appeal              "representation/Appeal";
import OpenVote            "interfaces/OpenVote";
import PutBallot           "interfaces/PutBallot";
import ReadVote            "interfaces/ReadVote";
import CloseVote           "interfaces/CloseVote";
import QuestionVoteHistory "../QuestionVoteHistory";

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
  
  public type VoteRegister = Votes.VoteRegister<Interest, Appeal>;
  public type HistoryRegister = QuestionVoteHistory.Register;
  public type Vote         = Types.Vote<Interest, Appeal>;
  public type Ballot       = Types.Ballot<Interest>;

  public func initVoteRegister() : VoteRegister {
    Votes.initRegister<Interest, Appeal>();
  };

  public func build(
    register: VoteRegister,
    history: QuestionVoteHistory,
    subaccounts: Map<Nat, Blob>,
    generator: SubaccountGenerator,
    payin: (Principal, Blob) -> async Result<(), ()>,
    payout: (Vote, Blob) -> (),
    callbacks: [Votes.Callback<Appeal>]
  ) : Interests {
    let votes = Votes.Votes2<Interest, Appeal>(register, Appeal.init());
    for (callback in Array.vals(callbacks)) {
      votes.addObs(callback);
    };
    let ballot_aggregator = BallotAggregator.BallotAggregator<Interest, Appeal>(
      func(interest: Interest) : Bool { true; }, // enum type cannot be invalid
      Appeal.add,
      Appeal.remove
    );
    Interests(
      history,
      OpenVote.OpenVotePayin<Interest, Appeal>(votes, subaccounts, generator, payin),
      PutBallot.PutBallotPayin<Interest, Appeal>(votes, ballot_aggregator, subaccounts, payin),
      CloseVote.CloseVotePayout<Interest, Appeal>(votes, subaccounts, payout),
      ReadVote.ReadVote<Interest, Appeal>(votes)
    );
  };

  public class Interests(
    history_: QuestionVoteHistory,
    open_vote_interface_: OpenVotePayin,
    put_ballot_interface_: PutBallotPayin,
    close_vote_interface_: CloseVotePayout,
    read_vote_interface_: ReadVote
  ) {
    
    public func openVote(principal: Principal, on_success: () -> Question) : async Result<Question, ()> {
      Result.mapOk(await open_vote_interface_.openVote(principal), func(vote_id: Nat) : Question {
        let question = on_success();
        history_.addVote(question.id, vote_id);
        question;
      });
    };

    public func getBallot(principal: Principal, question_id: Nat) : Result<Ballot, GetBallotError> {
      switch(history_.getCurrentVote(question_id)) {
        case (null) { #err(#VoteNotFound); }; // @todo
        case (?vote_id) {
          read_vote_interface_.getBallot(principal, vote_id);
        };
      };
    };

    public func putBallot(principal: Principal, question_id: Nat, date: Time, interest: Interest) : async Result<(), PutBallotError> {
      switch(history_.getCurrentVote(question_id)) {
        case (null) { #err(#VoteClosed); }; // @todo
        case (?vote_id) {
          await put_ballot_interface_.putBallot(principal, vote_id, {date; answer = interest;});
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