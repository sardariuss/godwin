import Types "Types";
import Users "Users";
import QuestionQueries "QuestionQueries";
import Controller "controller/Controller";
import Model "controller/Model";
import Questions "Questions";
import Votes "votes/Votes";
import Poll "votes/Poll";
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
  type Ballot<T> = Types.Ballot<T>;
  type Interest = Types.Interest;
  type Appeal = Types.Appeal;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type InterestPoll = Poll.Poll<Interest, Appeal>;
  type OpinionPoll = Poll.Poll<Cursor, Polarization>;
  type CategorizationPoll = Poll.Poll<CursorMap, PolarizationMap>;
  // Errors
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type GetQuestionError = Types.GetQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type ReopenQuestionError = Types.ReopenQuestionError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type GetUserError = Types.GetUserError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type TypedAggregate = Types.TypedAggregate;
  type GetUserConvictionsError = Types.GetUserConvictionsError;
  type GetAggregateError = Types.GetAggregateError;
  type GetBallotError = Types.GetBallotError;
  type RevealBallotError = Types.RevealBallotError;
  type PutBallotError = Types.PutBallotError;
  type PutFreshBallotError = Types.PutFreshBallotError;

  public class Game(
    admin_: Principal,
    categories_: Categories.Categories,
    users_: Users.Users,
    questions_: Questions.Questions,
    queries_: QuestionQueries.QuestionQueries,
    model_: Model.Model,
    controller_: Controller.Controller,
    interest_poll_: InterestPoll,
    opinion_poll_: OpinionPoll,
    categorization_poll_: CategorizationPoll
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

    public func getInterestAggregate(question_id: Nat, iteration: Nat) : Result<Appeal, GetAggregateError> {
      interest_poll_.getAggregate(question_id, iteration);
    };

    public func getInterestBallot(principal: Principal, question_id: Nat, iteration: Nat) : Result<?Ballot<Interest>, GetBallotError> {
      interest_poll_.getBallot(principal, question_id, iteration);
    };

    public func putInterestBallot(principal: Principal, question_id: Nat, iteration: Nat, date: Time, interest: Interest) : Result<(), PutFreshBallotError> {
      interest_poll_.putFreshBallot(principal, question_id, iteration, date, interest);
    };

    public func getOpinionAggregate(question_id: Nat, iteration: Nat) : Result<Polarization, GetAggregateError> {
      opinion_poll_.getAggregate(question_id, iteration);
    };

    public func getOpinionBallot(principal: Principal, question_id: Nat, iteration: Nat) : Result<?Ballot<Cursor>, GetBallotError> {
      opinion_poll_.getBallot(principal, question_id, iteration);
    };

    public func revealOpinionBallot(principal: Principal, question_id: Nat, iteration: Nat, date: Time) : Result<Ballot<Cursor>, RevealBallotError> {
      opinion_poll_.revealBallot(principal, question_id, iteration, date);
    };

    public func putOpinionBallot(principal: Principal, question_id: Nat, iteration: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      opinion_poll_.putBallot(principal, question_id, iteration, date, cursor);
    };

    public func getCategorizationAggregate(question_id: Nat, iteration: Nat) : Result<PolarizationMap, GetAggregateError> {
      categorization_poll_.getAggregate(question_id, iteration);
    };
      
    public func getCategorizationBallot(principal: Principal, question_id: Nat, iteration: Nat) : Result<?Ballot<CursorMap>, GetBallotError> {
      categorization_poll_.getBallot(principal, question_id, iteration);
    };
      
    public func putCategorizationBallot(principal: Principal, question_id: Nat, iteration: Nat, date: Time, answer: CursorMap) : Result<(), PutFreshBallotError> {
      categorization_poll_.putFreshBallot(principal, question_id, iteration, date, answer);
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
