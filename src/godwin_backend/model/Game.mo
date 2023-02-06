import Types "Types";
import Users "Users";
import QuestionQueries "QuestionQueries";
import Controller "controller/Controller";
import Model "controller/Model";
import Questions "Questions";
import Votes "votes/Votes";
import Polls "votes/Polls";
import Categories "Categories";
import StatusHelper "StatusHelper";
import Duration "Duration";
import Utils "../utils/Utils";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Int;

  // For convenience: from types module
  type Question = Types.Question;
  type User = Types.User;
  type Category = Types.Category;
  type Decay = Types.Decay;
  type Duration = Types.Duration;
  type Status = Types.Status;
  type IndexedStatus = Types.IndexedStatus;
  type Poll = Types.Poll;
  type TypedBallot = Types.TypedBallot;
  type TypedAnswer = Types.TypedAnswer;
  type PolarizationArray = Types.PolarizationArray;
  // Errors
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type GetQuestionError = Types.GetQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type ReopenQuestionError = Types.ReopenQuestionError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type GetUserError = Types.GetUserError;
  type PutBallotError = Types.PutBallotError;
  type GetBallotError = Types.GetBallotError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type TypedAggregate = Types.TypedAggregate;
  type GetUserConvictionsError = Types.GetUserConvictionsError;
  type RevealBallotError = Types.RevealBallotError;

  public class Game(
    admin_: Principal,
    categories_: Categories.Categories,
    users_: Users.Users,
    questions_: Questions.Questions,
    queries_: QuestionQueries.QuestionQueries,
    model_: Model.Model,
    controller_: Controller.Controller,
    polls_: Polls.Polls
  ) = {

    public func getDecay() : ?Decay {
      users_.getDecay();
    };

    public func getCategories() : [Category] {
      Iter.toArray(categories_.keys());
    };

    public func addCategory(caller: Principal, category: Category) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func() {
        Result.mapOk<(), (), AddCategoryError>(Utils.toResult(not categories_.has(category), #CategoryAlreadyExists), func() {
          categories_.add(category);
          // Also add the category to users' profile // @todo: use an obs instead?
          users_.addCategory(category);
        })
      });
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
        Result.mapOk<(), (), RemoveCategoryError>(Utils.toResult(categories_.has(category), #CategoryDoesntExist), func() {
          categories_.add(category);
          // Also remove the category from users' profile // @todo: use an obs instead?
          users_.removeCategory(category);
        })
      });
    };

    public func getInterestPickRate() : Duration {
      model_.getInterestPickRate();
    };

    public func setInterestPickRate(caller: Principal, rate: Duration) : Result<(), SetPickRateError> {
      Result.mapOk<(), (), SetPickRateError>(verifyCredentials(caller), func () {
        model_.setInterestPickRate(rate);
      });
    };

    public func getStatusDuration(status: Status) : Duration {
      model_.getStatusDuration(status);
    };

    public func setStatusDuration(caller: Principal, status: Status, duration: Duration) : Result<(), SetDurationError> {
      Result.mapOk<(), (), SetDurationError>(verifyCredentials(caller), func () {
        model_.setStatusDuration(status, duration);
      });
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      questions_.searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries.QueryQuestionsResult {
      queries_.queryItems(order_by, direction, limit, Option.map(previous_id, func(id: Nat) : Question { questions_.getQuestion(id); }));
    };

    public func openQuestion(caller: Principal, title: Text, text: Text, date: Time) : Result<Question, OpenQuestionError> {
      Result.mapOk<User, Question, OpenQuestionError>(getUser(caller), func(_) {
        controller_.openQuestion(caller, date, title, text);
      });
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : Result<(), ReopenQuestionError> {
      Result.chain<User, (), ReopenQuestionError>(getUser(caller), func(_) {
        Result.chain<Question, (), ReopenQuestionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), (), ReopenQuestionError>(Utils.toResult(StatusHelper.isCurrentStatus(question, #CLOSED), #InvalidStatus), func() {
            controller_.reopenQuestion(question, date);
          })
        })
      });
    };

    public func putBallot(caller: Principal, question_id: Nat, answer: TypedAnswer, date: Time) : Result<(), PutBallotError> {
      Result.chain<User, (), PutBallotError>(getUser(caller), func(_) {
        Result.chain<Question, (), PutBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), (), PutBallotError>(Utils.toResult(Polls.matchCurrentPoll(question, answer), #InvalidStatus), func(_) {
            polls_.putBallot(caller, question, answer, date);
          })
        })
      });
    };

    // Reveal the ballot for the current vote, put a default neutral ballot if no ballot has been given yet
    // @todo: if the questions is revealed itself, this method has no benefit. The getQuestion and getQuestions 
    // methods shall reveal the ballot of the questions. But this might bring performance issues (update method isntead of query).
    public func revealBallot(caller: Principal, question_id: Nat, date: Time) : Result<TypedBallot, RevealBallotError> {
      Result.chain<User, TypedBallot, RevealBallotError>(getUser(caller), func(_) {
        Result.chain<Question, TypedBallot, RevealBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<Poll, TypedBallot, RevealBallotError>(Result.fromOption(StatusHelper.getCurrentPoll(question), #VotingClosed), func(poll) {
            polls_.revealBallot(caller, question.id, StatusHelper.getIteration(question, #VOTING(poll)), poll, date);
          })
        })
      });
    };

    public func getBallot(principal: Principal, question_id: Nat, iteration: Nat, poll: Poll) : Result<?TypedBallot, GetBallotError> {
      Result.chain<User, ?TypedBallot, GetBallotError>(getUser(principal), func(_) {
        Result.chain<Question, ?TypedBallot, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), ?TypedBallot, GetBallotError>(Utils.toResult(StatusHelper.isHistoryIteration(question, #VOTING(poll), iteration), #InvalidIteration), func() {
            polls_.getBallot(principal, question.id, iteration, poll);
          })
        })
      });
    };

    // Get the aggregate of any vote, except the current one
    public func getAggregate(question_id: Nat, iteration: Nat, poll: Poll) : Result<TypedAggregate, GetBallotError> {
      Result.chain<Question, TypedAggregate, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        Result.mapOk<(), TypedAggregate, GetBallotError>(Utils.toResult(StatusHelper.isHistoryIteration(question, #VOTING(poll), iteration), #InvalidIteration), func() {
          polls_.getAggregate(question.id, iteration, poll);
        })
      });
    };

    public func run(date: Time) {
      controller_.run(date, Option.map(queries_.entries(#INTEREST_SCORE, #FWD).next(), func(question: Question) : Nat { question.id; }));
    };

    public func setUserName(principal: Principal, name: Text) : Result<(), SetUserNameError> {
      Result.mapOk<User, (), SetUserNameError>(getUser(principal), func(_) {
        users_.setUserName(principal, name);
      });
    };

    public func getUserConvictions(principal: Principal) : Result<PolarizationArray, GetUserConvictionsError> {
      Result.mapOk<User, Types.PolarizationArray, GetUserConvictionsError>(getUser(principal), func(user) {
        Utils.trieToArray(user.convictions);
      });
    };

    func verifyCredentials(principal: Principal) : Result<(), VerifyCredentialsError> {
      Result.mapOk<(), (), VerifyCredentialsError>(Utils.toResult(principal == admin_, #InsufficientCredentials), (func(){}));
    };

    func getUser(principal: Principal) : Result<User, GetUserError> {
      Result.mapOk<(), User, GetUserError>(Utils.toResult(not Principal.isAnonymous(principal), #PrincipalIsAnonymous), func(){
        users_.getOrCreateUser(principal, categories_);
      });
    };

    // @todo
//    public func createQuestions(principal: Principal, inputs: [(Text, CreateStatus)]) : Result<[Question], CreateQuestionError> {
//      Result.chain<(), [Question], CreateQuestionError>(verifyCredentials(principal), func () {
//        Result.mapOk<User, [Question], CreateQuestionError>(getUser(principal), func(_) {
//          Admin.createQuestions(questions_, principal, inputs);
//        })
//      });
//    };

  };

};
