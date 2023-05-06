import Types               "Types";
import QuestionTypes       "questions/Types";
import QuestionQueries     "questions/QuestionQueries";
import VoteTypes           "votes/Types";
import Controller          "controller/Controller";
import Categories          "Categories";

import Duration            "../utils/Duration";
import Utils               "../utils/Utils";

import Map                 "mo:map/Map";

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
  type Duration               = Duration.Duration;
  type Controller             = Controller.Controller;

  // For convenience: from types module
  type Decay                  = Types.Decay; // @todo
  type CursorArray            = Types.CursorArray;
  type PolarizationArray      = Types.PolarizationArray;
  type StatusHistoryArray     = Types.StatusHistory;
  type CategoryInfo           = Types.CategoryInfo;
  type CategoryArray          = Types.CategoryArray;
  type InterestVote           = Types.InterestVote;
  type OpinionVote            = Types.OpinionVote;
  type CategorizationVote     = Types.CategorizationVote;
  type InterestBallot         = Types.InterestBallot;
  type OpinionBallot          = Types.OpinionBallot;
  type CategorizationBallot   = Types.CategorizationBallot;
  type ShareableVote<T, A>    = Types.Vote<T, A>;
  type Question               = QuestionTypes.Question;
  type Status                 = QuestionTypes.Status;
  type StatusHistoryMap       = QuestionTypes.StatusHistory;
  type StatusInfo             = QuestionTypes.StatusInfo;
  type Category               = VoteTypes.Category;
  type Ballot<T>              = VoteTypes.Ballot<T>;
  type Vote<T, A>             = VoteTypes.Vote<T, A>;
  type Cursor                 = VoteTypes.Cursor;
  type Polarization           = VoteTypes.Polarization;
  type CursorMap              = VoteTypes.CursorMap;
  type PolarizationMap        = VoteTypes.PolarizationMap;
  type VoteId                 = VoteTypes.VoteId;
  // Errors
  type AddCategoryError       = Types.AddCategoryError;
  type RemoveCategoryError    = Types.RemoveCategoryError;
  type GetQuestionError       = Types.GetQuestionError;
  type ReopenQuestionError    = Types.ReopenQuestionError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type SetPickRateError       = Types.SetPickRateError;
  type SetDurationError       = Types.SetDurationError;
  type GetBallotError         = Types.GetBallotError;
  type PutBallotError         = Types.PutBallotError;
  type GetVoteError           = Types.GetVoteError;
  type OpenVoteError          = Types.OpenVoteError;
  type RevealVoteError        = Types.RevealVoteError;
  type TransitionError        = Types.TransitionError;
  type OpenQuestionError      = Types.OpenQuestionError; // @todo

  public class Facade(_controller: Controller) = {

    public func getName() : Text {
      _controller.getName();
    };

    public func getDecay() : ?Decay {
      _controller.getDecay();
    };

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

    public func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries.ScanLimitResult {
      _controller.getQuestions(order_by, direction, limit, previous_id);
    };

    public func openQuestion(caller: Principal, text: Text, date: Time) : async* Result<Question, OpenQuestionError> {
      await* _controller.openQuestion(caller, text, date);
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async* Result<(), [(?Status, TransitionError)]> {
      await* _controller.reopenQuestion(caller, question_id, date);
    };

    public func getInterestBallot(caller: Principal, question_id: Nat) : Result<Ballot<Cursor>, GetBallotError> {
      _controller.getInterestBallot(caller, question_id);
    };

    public func putInterestBallot(principal: Principal, question_id: Nat, date: Time, interest: Cursor) : async* Result<InterestBallot, PutBallotError> {
      Result.mapOk<(), InterestBallot, PutBallotError>(await* _controller.putInterestBallot(principal, question_id, date, interest), func() : InterestBallot {
        { date = date; answer = interest; }
      });
    };

    public func getOpinionBallot(caller: Principal, question_id: Nat) : Result<Ballot<Cursor>, GetBallotError> {
      _controller.getOpinionBallot(caller, question_id);
    };

    public func putOpinionBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<OpinionBallot, PutBallotError> {
      Result.mapOk<(), OpinionBallot, PutBallotError>(_controller.putOpinionBallot(principal, question_id, date, cursor), func() : OpinionBallot {
        { date = date; answer = cursor; }
      });
    };
      
    public func getCategorizationBallot(caller: Principal, question_id: Nat) : Result<CategorizationBallot, GetBallotError> {
      Result.mapOk(_controller.getCategorizationBallot(caller, question_id), func(ballot: Ballot<CursorMap>) : CategorizationBallot {
        { date = ballot.date; answer = Utils.trieToArray(ballot.answer); };
      });
    };
      
    public func putCategorizationBallot(principal: Principal, question_id: Nat, date: Time, cursors: CursorArray) : async* Result<CategorizationBallot, PutBallotError> {
      Result.mapOk<(), CategorizationBallot, PutBallotError>(
        await* _controller.putCategorizationBallot(principal, question_id, date, Utils.arrayToTrie(cursors, Categories.key, Categories.equal)), func() : CategorizationBallot {
          { date = date; answer = cursors; };
        });
    };

    public func getStatusInfo(question_id: Nat) : Result<StatusInfo, ReopenQuestionError> {
      _controller.getStatusInfo(question_id);
    };

    public func getStatusHistory(question_id: Nat) : Result<StatusHistoryArray, ReopenQuestionError> {
      Result.mapOk<StatusHistoryMap, StatusHistoryArray, ReopenQuestionError>(_controller.getStatusHistory(question_id), func(history: StatusHistoryMap) : StatusHistoryArray {
        Utils.mapToArray(history);
      });
    };

    public func revealInterestVote(question_id: Nat, iteration: Nat) : Result<InterestVote, RevealVoteError> {
      Result.mapOk<Vote<Cursor, Polarization>, InterestVote, RevealVoteError>(_controller.revealInterestVote(question_id, iteration), func(vote: Vote<Cursor, Polarization>) : InterestVote {
        toShareableVote(vote);
      });
    };

    public func revealOpinionVote(question_id: Nat, iteration: Nat) : Result<OpinionVote, RevealVoteError> {
      Result.mapOk<Vote<Cursor, Polarization>, OpinionVote, RevealVoteError>(_controller.revealOpinionVote(question_id, iteration), func(vote: Vote<Cursor, Polarization>) : OpinionVote {
        toShareableVote(vote);
      });
    };

    public func revealCategorizationVote(question_id: Nat, iteration: Nat) : Result<CategorizationVote, RevealVoteError> {
      Result.mapOk<Vote<CursorMap, PolarizationMap>, CategorizationVote, RevealVoteError>(_controller.revealCategorizationVote(question_id, iteration), func(vote: Vote<CursorMap, PolarizationMap>) : CategorizationVote {
        toShareableCategorizationVote(vote);
      });
    };

    public func getUserConvictions(principal: Principal) : ?PolarizationArray {
      Option.map(_controller.getUserConvictions(principal), func(convictions: PolarizationMap) : PolarizationArray {
        Utils.trieToArray(convictions);
      });
    };

    public func getUserOpinions(principal: Principal) : ?[(VoteId, PolarizationArray, Ballot<Cursor>)] {
      _controller.getUserOpinions(principal);
    };

    public func run(time: Time) : async* () {
      await* _controller.run(time);
    };

  };

  public func toShareableVote<T, A>(vote: Vote<T, A>) : ShareableVote<T, A> {
    {
      id = vote.id;
      ballots = Utils.mapToArray(vote.ballots);
      aggregate = vote.aggregate;
    }
  };

  public func toShareableCategorizationVote(vote: Vote<CursorMap, PolarizationMap>) : CategorizationVote {
    
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