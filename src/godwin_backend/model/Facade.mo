import Types               "Types";
import QuestionTypes       "questions/Types";
import QuestionQueries     "questions/QuestionQueries";
import VoteTypes           "votes/Types";
import Controller          "controller/Controller";
import Categories          "Categories";

import Utils               "../utils/Utils";

import StableBuffer        "mo:stablebuffer/StableBuffer";
import Map                 "mo:map/Map";
import Set                 "mo:map/Set";

import Result              "mo:base/Result";
import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Iter                "mo:base/Iter";
import Buffer              "mo:base/Buffer";

module {

  // For convenience: from base module
  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Principal              = Principal.Principal;
  type Time                   = Int;
  type Buffer<T>              = Buffer.Buffer<T>;

  // For convenience: from other modules
  type Controller             = Controller.Controller;

  // For convenience: from types module
  type QuestionId                 = Types.QuestionId;
  type Duration                   = Types.Duration;
  type QuestionOrderBy            = Types.QuestionOrderBy;
  type Decay                      = Types.Decay; // @todo
  type CursorArray                = Types.CursorArray;
  type PolarizationArray          = Types.PolarizationArray;
  type CategoryInfo               = Types.CategoryInfo;
  type CategoryArray              = Types.CategoryArray;
  type InterestVote               = Types.InterestVote;
  type OpinionVote                = Types.OpinionVote;
  type CategorizationVote         = Types.CategorizationVote;
  type InterestBallot             = Types.InterestBallot;
  type OpinionBallot              = Types.OpinionBallot;
  type CategorizationBallot       = Types.CategorizationBallot;
  type ShareableVote<T, A>        = Types.Vote<T, A>;
  type Direction                  = Types.Direction;
  type ScanLimitResult<K>         = Types.ScanLimitResult<K>;
  type ShareableStatusHistory     = Types.StatusHistory;   
  type ShareableIterationHistory  = Types.IterationHistory;
  type FindQuestionIterationError = Types.FindQuestionIterationError;
  type VoteKind                   = Types.VoteKind;
  type TransactionsRecord         = Types.TransactionsRecord;
  type Question                   = QuestionTypes.Question;
  type Status                     = QuestionTypes.Status;
  type StatusHistoryMap           = QuestionTypes.StatusHistory;
  type StatusInfo                 = QuestionTypes.StatusInfo;
  type StatusHistory              = QuestionTypes.StatusHistory;
  type IterationHistory           = QuestionTypes.IterationHistory;
  type Category                   = VoteTypes.Category;
  type Ballot<T>                  = VoteTypes.Ballot<T>;
  type Vote<T, A>                 = VoteTypes.Vote<T, A>;
  type Cursor                     = VoteTypes.Cursor;
  type Polarization               = VoteTypes.Polarization;
  type CursorMap                  = VoteTypes.CursorMap;
  type PolarizationMap            = VoteTypes.PolarizationMap;
  type VoteId                     = VoteTypes.VoteId;
  // Errors
  type AddCategoryError           = Types.AddCategoryError;
  type RemoveCategoryError        = Types.RemoveCategoryError;
  type GetQuestionError           = Types.GetQuestionError;
  type ReopenQuestionError        = Types.ReopenQuestionError;
  type VerifyCredentialsError     = Types.VerifyCredentialsError;
  type SetPickRateError           = Types.SetPickRateError;
  type SetDurationError           = Types.SetDurationError;
  type FindBallotError            = Types.FindBallotError;
  type PutBallotError             = Types.PutBallotError;
  type GetVoteError               = Types.GetVoteError;
  type OpenVoteError              = Types.OpenVoteError;
  type RevealVoteError            = Types.RevealVoteError;
  type TransitionError            = Types.TransitionError;
  type OpenQuestionError          = Types.OpenQuestionError; // @todo
  type FindVoteError              = Types.FindVoteError;

  public class Facade(_controller: Controller) = {

    public func getName() : Text {
      _controller.getName();
    };

  // @todo: revive decay
//    public func getDecay() : ?Decay {
//      _controller.getDecay();
//    };

    public func getCategories() : CategoryArray {
      Iter.toArray(_controller.getCategories().entries());
    };

    public func addCategory(caller: Principal, category: Category, info: CategoryInfo) : Result<(), AddCategoryError> {
      _controller.addCategory(caller, category, info);
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      _controller.removeCategory(caller, category);
    };

    public func getInterestPickRate() : Duration {
      _controller.getInterestPickRate();
    };

    public func setInterestPickRate(caller: Principal, rate: Duration) : Result<(), SetPickRateError> {
      _controller.setInterestPickRate(caller, rate);
    };

    public func getStatusDuration(status: Status) : Duration {
      _controller.getStatusDuration(status);
    };

    public func setStatusDuration(caller: Principal, status: Status, duration: Duration) : Result<(), SetDurationError> {
      _controller.setStatusDuration(caller, status, duration);
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      _controller.searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      _controller.getQuestion(question_id);
    };

    public func getQuestions(order_by: QuestionOrderBy, direction: Direction, limit: Nat, previous_id: ?Nat) : ScanLimitResult<VoteId> {
      _controller.getQuestions(order_by, direction, limit, previous_id);
    };

    public func openQuestion(caller: Principal, text: Text, date: Time) : async* Result<Question, OpenQuestionError> {
      await* _controller.openQuestion(caller, text, date);
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async* Result<(), [(?Status, TransitionError)]> {
      await* _controller.reopenQuestion(caller, question_id, date);
    };

    public func getInterestBallot(caller: Principal, vote_id: VoteId) : Result<Ballot<Cursor>, FindBallotError> {
      _controller.getInterestBallot(caller, vote_id);
    };

    public func putInterestBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Cursor) : async* Result<InterestBallot, PutBallotError> {
      Result.mapOk<(), InterestBallot, PutBallotError>(await* _controller.putInterestBallot(principal, vote_id, date, interest), func() : InterestBallot {
        { date = date; answer = interest; }
      });
    };

    public func getOpinionBallot(caller: Principal, vote_id: VoteId) : Result<Ballot<Cursor>, FindBallotError> {
      _controller.getOpinionBallot(caller, vote_id);
    };

    public func putOpinionBallot(principal: Principal, vote_id: VoteId, date: Time, cursor: Cursor) : async* Result<OpinionBallot, PutBallotError> {
      Result.mapOk<(), OpinionBallot, PutBallotError>(await* _controller.putOpinionBallot(principal, vote_id, date, cursor), func() : OpinionBallot {
        { date = date; answer = cursor; }
      });
    };
      
    public func getCategorizationBallot(caller: Principal, vote_id: VoteId) : Result<CategorizationBallot, FindBallotError> {
      Result.mapOk(_controller.getCategorizationBallot(caller, vote_id), func(ballot: Ballot<CursorMap>) : CategorizationBallot {
        { date = ballot.date; answer = Utils.trieToArray(ballot.answer); };
      });
    };
      
    public func putCategorizationBallot(principal: Principal, vote_id: VoteId, date: Time, cursors: CursorArray) : async* Result<CategorizationBallot, PutBallotError> {
      Result.mapOk<(), CategorizationBallot, PutBallotError>(
        await* _controller.putCategorizationBallot(principal, vote_id, date, Utils.arrayToTrie(cursors, Categories.key, Categories.equal)), func() : CategorizationBallot {
          { date = date; answer = cursors; };
        });
    };

    public func getIterationHistory(question_id: Nat) : Result<ShareableIterationHistory, ReopenQuestionError> {
      Result.mapOk<IterationHistory, ShareableIterationHistory, ReopenQuestionError>(_controller.getIterationHistory(question_id), func(history: IterationHistory) : ShareableIterationHistory {
        toShareableIterationHistory(history);
      });
    };

    public func revealInterestVote(vote_id: VoteId) : Result<InterestVote, RevealVoteError> {
      Result.mapOk<Vote<Cursor, Polarization>, InterestVote, RevealVoteError>(_controller.revealInterestVote(vote_id), func(vote: Vote<Cursor, Polarization>) : InterestVote {
        toShareableVote(vote);
      });
    };

    public func revealOpinionVote(vote_id: VoteId) : Result<OpinionVote, RevealVoteError> {
      Result.mapOk<Vote<Cursor, Polarization>, OpinionVote, RevealVoteError>(_controller.revealOpinionVote(vote_id), func(vote: Vote<Cursor, Polarization>) : OpinionVote {
        toShareableVote(vote);
      });
    };

    public func revealCategorizationVote(vote_id: VoteId) : Result<CategorizationVote, RevealVoteError> {
      Result.mapOk<Vote<CursorMap, PolarizationMap>, CategorizationVote, RevealVoteError>(_controller.revealCategorizationVote(vote_id), func(vote: Vote<CursorMap, PolarizationMap>) : CategorizationVote {
        toShareableCategorizationVote(vote);
      });
    };

    public func findInterestVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _controller.findInterestVoteId(question_id, iteration);
    };

    public func findOpinionVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _controller.findOpinionVoteId(question_id, iteration);
    };

    public func findCategorizationVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _controller.findCategorizationVoteId(question_id, iteration);
    };

    public func revealInterestBallots(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : ScanLimitResult<(VoteId, ?InterestBallot, ?TransactionsRecord)> {
      _controller.revealInterestBallots(principal, direction, limit, previous_id);
    };

    public func revealOpinionBallots(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : ScanLimitResult<(VoteId, ?OpinionBallot, ?TransactionsRecord)> {
      _controller.revealOpinionBallots(principal, direction, limit, previous_id);
    };

    public func revealCategorizationBallots(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : ScanLimitResult<(VoteId, ?CategorizationBallot, ?TransactionsRecord)> {
      Utils.mapScanLimitResult<(VoteId, ?Ballot<CursorMap>, ?TransactionsRecord), (VoteId, ?CategorizationBallot, ?TransactionsRecord)>(
        _controller.revealCategorizationBallots(principal, direction, limit, previous_id),
        func((id, bal, tx): (VoteId, ?Ballot<CursorMap>, ?TransactionsRecord)) : (VoteId, ?CategorizationBallot, ?TransactionsRecord){
          (id, Option.map(bal, func(b: Ballot<CursorMap>) : CategorizationBallot {{ answer = Utils.trieToArray(b.answer); date = b.date; }}), tx);
      });
    };

    public func getQuestionIteration(vote_kind: VoteKind, vote_id: VoteId) : Result<(Question, Nat), FindQuestionIterationError> {
      _controller.getQuestionIteration(vote_kind, vote_id);
    };

    public func getQuestionsFromAuthor(principal: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<(QuestionId, ?Question, ?TransactionsRecord)> {
      _controller.getQuestionsFromAuthor(principal, direction, limit, previous_id);
    };

    public func getVoterConvictions(principal: Principal) : [(VoteId, (OpinionBallot, [(Category, Float)]))] {
      Utils.mapToArray(_controller.getVoterConvictions(principal));
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

  func toShareableIterationHistory(history: IterationHistory) : ShareableIterationHistory {
    let iterations = StableBuffer.init<ShareableStatusHistory>();
    for (iteration in StableBuffer.vals(history)){
      StableBuffer.add(iterations, StableBuffer.toArray(iteration));
    };
    StableBuffer.toArray(iterations);
  };

};