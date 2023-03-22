import Types               "../Types";
import SubaccountGenerator "../token/SubaccountGenerator";
import Categories "../Categories";
import Votes               "Votes2"; 
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

module {

  type Result<Ok, Err>     = Result.Result<Ok, Err>;
  type Map<K, V>           = Map.Map<K, V>;
  type Time                = Int;

  type Categories = Categories.Categories;
  type CursorMap            = Types.CursorMap;
  type PolarizationMap              = Types.PolarizationMap;
  type SubaccountGenerator = SubaccountGenerator.SubaccountGenerator;
  type BallotAggregator    = BallotAggregator.BallotAggregator<CursorMap, PolarizationMap>;
  type OpenVoteWithSubaccount       = OpenVote.OpenVoteWithSubaccount<CursorMap, PolarizationMap>;
  type PutBallotPayin      = PutBallot.PutBallotPayin<CursorMap, PolarizationMap>;
  type CloseVotePayout     = CloseVote.CloseVotePayout<CursorMap, PolarizationMap>;
  type ReadVote            = ReadVote.ReadVote<CursorMap, PolarizationMap>;

  type QuestionVoteHistory = QuestionVoteHistory.QuestionVoteHistory;
  
  public type VoteRegister = Votes.VoteRegister<CursorMap, PolarizationMap>;
  public type Vote         = Types.Vote<CursorMap, PolarizationMap>;
  public type Ballot       = Types.Ballot<CursorMap>;

  type PutBallotError      = Types.PutBallotError;
  type CloseVoteError      = Types.CloseVoteError;
  type GetVoteError        = Types.GetVoteError;
  type GetBallotError = Types.GetBallotError;

  public func initVoteRegister() : VoteRegister {
    Votes.initRegister<CursorMap, PolarizationMap>();
  };

  public func build(
    categories: Categories,
    register: VoteRegister,
    history: QuestionVoteHistory,
    subaccounts: Map<Nat, Blob>,
    generator: SubaccountGenerator,
    payin: (Principal, Blob) -> async Result<(), ()>,
    payout: (Vote, Blob) -> ()
  ) : Categorizations {
    let votes = Votes.Votes2<CursorMap, PolarizationMap>(register, PolarizationMap.nil(categories));
    let ballot_aggregator = BallotAggregator.BallotAggregator<CursorMap, PolarizationMap>(
      func(cursor_map: CursorMap) : Bool { CursorMap.isValid(cursor_map, categories); },
      PolarizationMap.addCursorMap,
      PolarizationMap.subCursorMap
    );
    Categorizations(
      history,
      OpenVote.OpenVoteWithSubaccount<CursorMap, PolarizationMap>(votes, subaccounts, generator),
      PutBallot.PutBallotPayin<CursorMap, PolarizationMap>(votes, ballot_aggregator, subaccounts, payin),
      CloseVote.CloseVotePayout<CursorMap, PolarizationMap>(votes, subaccounts, payout),
      ReadVote.ReadVote<CursorMap, PolarizationMap>(votes)
    );
  };

  public class Categorizations(
    history_: QuestionVoteHistory,
    open_vote_interface_: OpenVoteWithSubaccount,
    put_ballot_interface_: PutBallotPayin,
    close_vote_interface_: CloseVotePayout,
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

    public func putBallot(principal: Principal, question_id: Nat, date: Time, cursor_map: CursorMap) : async Result<(), PutBallotError> {
      switch(history_.getCurrentVote(question_id)) {
        case (null) { #err(#VoteClosed); }; // @todo
        case (?vote_id) {
          await put_ballot_interface_.putBallot(principal, vote_id, {date; answer = cursor_map;});
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