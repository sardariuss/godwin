import Types "Types";
import Users "Users";
import QuestionQueries "QuestionQueries";
import Scheduler "Scheduler";
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
  type RemoveBallotError = Types.RemoveBallotError;
  type GetBallotError = Types.GetBallotError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;

  public class Game(
    admin_: Principal,
    categories_: Categories.Categories,
    users_: Users.Users,
    questions_: Questions.Questions,
    queries_: QuestionQueries.QuestionQueries,
    scheduler_: Scheduler.Scheduler,
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

    public func getPickRate(status: Status) : Duration {
      Duration.fromTime(scheduler_.getPickRate(status));
    };

    public func setPickRate(caller: Principal, status: Status, rate: Duration) : Result<(), SetPickRateError> {
      Result.mapOk<(), (), SetPickRateError>(verifyCredentials(caller), func () {
        scheduler_.setPickRate(status, Duration.toTime(rate));
      });
    };

    public func getDuration(status: Status) : Duration {
      Duration.fromTime(scheduler_.getDuration(status));
    };

    public func setDuration(caller: Principal, status: Status, duration: Duration) : Result<(), SetDurationError> {
      Result.mapOk<(), (), SetDurationError>(verifyCredentials(caller), func () {
        scheduler_.setDuration(status, Duration.toTime(duration));
      });
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries.QueryQuestionsResult {
      queries_.queryItems(order_by, direction, limit, Option.map(previous_id, func(id: Nat) : Question { questions_.getQuestion(id); }));
    };

    public func openQuestion(caller: Principal, title: Text, text: Text, date: Time) : Result<Question, OpenQuestionError> {
      Result.mapOk<User, Question, OpenQuestionError>(getUser(caller), func(_) {
        let question = questions_.createQuestion(caller, date, title, text);
        polls_.openVote(question, #INTEREST);
        question;
      });
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : Result<(), ReopenQuestionError> {
      Result.chain<User, (), ReopenQuestionError>(getUser(caller), func(_) {
        Result.chain<Question, (), ReopenQuestionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), (), ReopenQuestionError>(Utils.toResult(StatusHelper.isCurrentStatus(question, #CLOSED), #InvalidStatus), func() {
            let question = questions_.updateStatus(question_id, #VOTING(#INTEREST), date);
            polls_.openVote(question, #INTEREST);
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

    public func removeBallot(caller: Principal, question_id: Nat, poll: Poll) : Result<(), RemoveBallotError> {
      Result.chain<User, (), RemoveBallotError>(getUser(caller), func(_) {
        Result.chain<Question, (), RemoveBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.chain<(), (), RemoveBallotError>(Utils.toResult(poll == #INTEREST, #NotAuthorized), func() {
            Result.mapOk<(), (), RemoveBallotError>(Utils.toResult(Polls.isCurrentPoll(question, poll), #InvalidStatus), func(_) {
              polls_.removeBallot(caller, question, poll);
            })
          })
        })
      });
    };

    public func getBallot(caller: Principal, question_id: Nat, iteration: Nat, vote: Poll) : Result<?TypedBallot, GetBallotError> {
      Result.chain<User, ?TypedBallot, GetBallotError>(getUser(caller), func(_) {
        Result.chain<Question, ?TypedBallot, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), ?TypedBallot, GetBallotError>(Utils.toResult(StatusHelper.isValidIteration(question, #VOTING(vote), iteration), #InvalidIteration), func() {
            polls_.getBallot(caller, question.id, iteration, vote);
          })
        })
      });
    };

    public func getUserBallot(principal: Principal, question_id: Nat, iteration: Nat, vote: Poll) : Result<?TypedBallot, GetBallotError> {
      Result.chain<User, ?TypedBallot, GetBallotError>(getUser(principal), func(_) {
        Result.chain<Question, ?TypedBallot, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), ?TypedBallot, GetBallotError>(Utils.toResult(StatusHelper.isHistoryIteration(question, #VOTING(vote), iteration), #InvalidIteration), func() {
            polls_.getBallot(principal, question.id, iteration, vote);
          })
        })
      });
    };

    public func run(date: Time) {
      scheduler_.run(date);
    };

    public func findUser(principal: Principal) : ?User {
      users_.findUser(principal);
    };

    public func setUserName(principal: Principal, name: Text) : Result<(), SetUserNameError> {
      Result.mapOk<User, (), SetUserNameError>(getUser(principal), func(_) {
        users_.setUserName(principal, name);
      });
    };

    func verifyCredentials(principal: Principal) : Result<(), VerifyCredentialsError> {
      Result.mapOk<(), (), VerifyCredentialsError>(Utils.toResult(principal == admin_, #InsufficientCredentials), (func(){}));
    };

    func getUser(principal: Principal) : Result<User, GetUserError> {
      Result.mapOk<(), User, GetUserError>(Utils.toResult(not Principal.isAnonymous(principal), #PrincipalIsAnonymous), func(){
        users_.getOrCreateUser(principal, Iter.toArray(categories_.keys()));
      });
    };

    // @todo: remove
    public func polarizationTrieToArray(trie: Types.PolarizationMap) : Types.PolarizationArray {
      Utils.trieToArray(trie);
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
