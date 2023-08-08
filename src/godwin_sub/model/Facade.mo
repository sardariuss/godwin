import Types               "Types";
import VoteTypes           "votes/Types";
import Controller          "controller/Controller";
import Categories          "Categories";

import Utils               "../utils/Utils";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Iter                "mo:base/Iter";
import Buffer              "mo:base/Buffer";

module {

  // For convenience: from base module
  type Result<Ok, Err>              = Result.Result<Ok, Err>;
  type Principal                    = Principal.Principal;
  type Time                         = Int;
  type Buffer<T>                    = Buffer.Buffer<T>;

  // For convenience: from other modules
  type Controller                   = Controller.Controller;

  // For convenience: from types module
  type QuestionId                   = Types.QuestionId;
  type QuestionOrderBy              = Types.QuestionOrderBy;
  type Interest                     = Types.Interest;
  type Appeal                       = Types.Appeal;
  type CursorArray                  = Types.CursorArray;
  type InterestVote                 = Types.InterestVote;
  type OpinionVote                  = Types.OpinionVote;
  type StatusData                   = Types.StatusData;
  type CategorizationVote           = Types.CategorizationVote;
  type InterestBallot               = Types.InterestBallot;
  type OpinionAnswer                = Types.OpinionAnswer;
  type OpinionBallot                = Types.OpinionBallot;
  type OpinionAggregate             = Types.OpinionAggregate;
  type CategorizationBallot         = Types.CategorizationBallot;
  type ShareableVote<T, A>          = Types.Vote<T, A>;
  type RevealableInterestBallot       = Types.RevealableInterestBallot;
  type RevealableOpinionBallot        = Types.RevealableOpinionBallot;
  type RevealableCategorizationBallot = Types.RevealableCategorizationBallot;
  type Direction                    = Types.Direction;
  type ScanLimitResult<K>           = Types.ScanLimitResult<K>;
  type FindQuestionIterationError   = Types.FindQuestionIterationError;
  type VoteKind                     = Types.VoteKind;
  type TransactionsRecord           = Types.TransactionsRecord;
  type SchedulerParameters          = Types.SchedulerParameters;
  type BallotConvictionInput        = Types.BallotConvictionInput;
  type QueryQuestionItem            = Types.QueryQuestionItem;
  type QueryVoteItem                = Types.QueryVoteItem;
  type StatusHistory                = Types.StatusHistory;
  type Question                     = Types.Question;
  type Status                       = Types.Status;
  type BasePriceParameters          = Types.BasePriceParameters;
  type SelectionParameters          = Types.SelectionParameters;
  type SubInfo                      = Types.SubInfo;
  type VoteKindBallot               = Types.VoteKindBallot;
  type Category                     = VoteTypes.Category;
  type Ballot<T>                    = VoteTypes.Ballot<T>;
  type Vote<T, A>                   = VoteTypes.Vote<T, A>;
  type RevealableBallot<T>          = VoteTypes.RevealableBallot<T>;
  type Cursor                       = VoteTypes.Cursor;
  type Polarization                 = VoteTypes.Polarization;
  type CursorMap                    = VoteTypes.CursorMap;
  type PolarizationMap              = VoteTypes.PolarizationMap;
  type VoteId                       = VoteTypes.VoteId;

  // Errors
  type GetQuestionError             = Types.GetQuestionError;
  type ReopenQuestionError          = Types.ReopenQuestionError;
  type AccessControlError           = Types.AccessControlError;
  type SetSchedulerParametersError  = Types.SetSchedulerParametersError;
  type FindBallotError              = Types.FindBallotError;
  type PutBallotError               = Types.PutBallotError;
  type GetVoteError                 = Types.GetVoteError;
  type OpenVoteError                = Types.OpenVoteError;
  type RevealVoteError              = Types.RevealVoteError;
  type OpenQuestionError            = Types.OpenQuestionError;
  type FindVoteError                = Types.FindVoteError;

  public class Facade(_controller: Controller) = {

    public func getSubInfo() : SubInfo {
      _controller.getSubInfo();
    };

    public func setSchedulerParameters(caller: Principal, params: SchedulerParameters) : Result<(), SetSchedulerParametersError> {
      _controller.setSchedulerParameters(caller, params);
    };

    public func setSelectionParameters(caller: Principal, params: SelectionParameters) : Result<(), AccessControlError> {
      _controller.setSelectionParameters(caller, params);
    };

    public func setBasePriceParameters(caller: Principal, params: BasePriceParameters) : Result<(), AccessControlError> {
      _controller.setBasePriceParameters(caller, params);
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      _controller.searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      _controller.getQuestion(question_id);
    };

    public func queryQuestions(order_by: QuestionOrderBy, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<QueryQuestionItem> {
      _controller.queryQuestions(order_by, direction, limit, previous_id);
    };

    public func openQuestion(caller: Principal, text: Text, date: Time) : async* Result<QuestionId, OpenQuestionError> {
      await* _controller.openQuestion(caller, text, date);
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async* Result<(), [(?Status, Text)]> {
      await* _controller.reopenQuestion(caller, question_id, date);
    };

    public func getInterestBallot(caller: Principal, vote_id: VoteId) : Result<RevealableInterestBallot, FindBallotError> {
      _controller.getInterestBallot(caller, vote_id);
    };

    public func putInterestBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Interest) : async* Result<(), PutBallotError> {
      await* _controller.putInterestBallot(principal, vote_id, date, interest);
    };

    public func getOpinionBallot(caller: Principal, vote_id: VoteId) : Result<RevealableOpinionBallot, FindBallotError> {
      _controller.getOpinionBallot(caller, vote_id);
    };

    public func putOpinionBallot(principal: Principal, vote_id: VoteId, date: Time, cursor: Cursor) : async* Result<(), PutBallotError> {
      await* _controller.putOpinionBallot(principal, vote_id, date, cursor);
    };
      
    public func getCategorizationBallot(caller: Principal, vote_id: VoteId) : Result<RevealableCategorizationBallot, FindBallotError> {
      Result.mapOk(_controller.getCategorizationBallot(caller, vote_id), func({vote_id; date; answer; can_change; }: RevealableBallot<CursorMap>) : RevealableCategorizationBallot {
        { 
          vote_id;
          date;
          can_change;
          answer = switch(answer){
            case(#HIDDEN)        { #HIDDEN;                           };
            case(#REVEALED(ans)) { #REVEALED(Utils.trieToArray(ans)); };
          };
        };
      });
    };
      
    public func putCategorizationBallot(principal: Principal, vote_id: VoteId, date: Time, cursors: CursorArray) : async* Result<(), PutBallotError> {
      await* _controller.putCategorizationBallot(principal, vote_id, date, Utils.arrayToTrie(cursors, Categories.key, Categories.equal));
    };

    public func getStatusHistory(question_id: Nat) : Result<[StatusData], ReopenQuestionError> {
      _controller.getStatusHistory(question_id);
    };

    public func revealInterestVote(vote_id: VoteId) : Result<InterestVote, RevealVoteError> {
      Result.mapOk(_controller.revealInterestVote(vote_id), func(vote: Vote<Interest, Appeal>) : InterestVote {
        toShareableVote(vote);
      });
    };

    public func revealOpinionVote(vote_id: VoteId) : Result<OpinionVote, RevealVoteError> {
      Result.mapOk(_controller.revealOpinionVote(vote_id), func(vote: Vote<OpinionAnswer, OpinionAggregate>) : OpinionVote {
        toShareableVote(vote);
      });
    };

    public func revealCategorizationVote(vote_id: VoteId) : Result<CategorizationVote, RevealVoteError> {
      Result.mapOk(_controller.revealCategorizationVote(vote_id), func(vote: Vote<CursorMap, PolarizationMap>) : CategorizationVote {
        toShareableCategorizationVote(vote);
      });
    };

    public func getQuestionIteration(vote_kind: VoteKind, vote_id: VoteId) : Result<(QuestionId, Nat, ?Question), FindQuestionIterationError> {
      _controller.getQuestionIteration(vote_kind, vote_id);
    };

    public func queryQuestionsFromAuthor(principal: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<(QuestionId, ?Question, ?TransactionsRecord)> {
      _controller.queryQuestionsFromAuthor(principal, direction, limit, previous_id);
    };

    public func queryFreshVotes(principal: Principal, vote_kind: VoteKind, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<QueryVoteItem> {
      _controller.queryFreshVotes(principal, vote_kind, direction, limit, previous_id);
    };

    public func queryVoterBallots(vote_kind: VoteKind, caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<QueryVoteItem> {
      _controller.queryVoterBallots(vote_kind, caller, voter, direction, limit, previous_id);
    };

    public func queryVoterQuestionBallots(question_id: QuestionId, vote_kind: VoteKind, caller: Principal, voter: Principal) : [(Nat, ?VoteKindBallot)] {
      Map.toArray(_controller.queryVoterQuestionBallots(question_id, vote_kind, caller, voter));
    };

    public func getVoterConvictions(now: Time, principal: Principal) : [(VoteId, BallotConvictionInput)] {
      Utils.mapToArray(_controller.getVoterConvictions(now, principal));
    };

    public func run(time: Time) : async* () {
      await* _controller.run(time);
    };

  };

  func toShareableVote<T, A>(vote: Vote<T, A>) : ShareableVote<T, A> {
    {
      id = vote.id;
      ballots = Utils.mapToArray(vote.ballots);
      aggregate = vote.aggregate;
    }
  };

  func toShareableCategorizationVote(vote: Vote<CursorMap, PolarizationMap>) : CategorizationVote {
    
    let ballots = Buffer.Buffer<(Principal, Ballot<CursorArray>)>(Map.size(vote.ballots));
    for ((principal, ballot) in Map.entries(vote.ballots)) {
      ballots.add((principal, { date = ballot.date; answer = Utils.trieToArray<Category, Cursor>(ballot.answer); }));
    };

    {
      id = vote.id;
      ballots = Buffer.toArray(ballots);
      aggregate = Utils.trieToArray(vote.aggregate);
    };
  };

};