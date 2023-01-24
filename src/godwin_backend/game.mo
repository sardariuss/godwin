import Types "types";
import Users "users";
import Utils "utils";
import Scheduler "scheduler";
import Questions "questions/questions";
import QuestionQueries2 "QuestionQueries2";
import Votes "votes/votes";
import Manager "votes/manager";
import Categories "Categories";
import StatusInfoHelper "StatusInfoHelper";

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
  type QuestionStatus = Types.QuestionStatus;
  type IndexedStatus = Types.IndexedStatus;
  type VoteType = Types.VoteType;
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
    queries_: QuestionQueries2.QuestionQueries,
    scheduler_: Scheduler.Scheduler,
    manager_: Manager.Manager
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

    public func getPickRate(status: QuestionStatus) : Duration {
      Utils.fromTime(scheduler_.getPickRate(status));
    };

    public func setPickRate(caller: Principal, status: QuestionStatus, rate: Duration) : Result<(), SetPickRateError> {
      Result.mapOk<(), (), SetPickRateError>(verifyCredentials(caller), func () {
        scheduler_.setPickRate(status, Utils.toTime(rate));
      });
    };

    public func getDuration(status: QuestionStatus) : Duration {
      Utils.fromTime(scheduler_.getDuration(status));
    };

    public func setDuration(caller: Principal, status: QuestionStatus, duration: Duration) : Result<(), SetDurationError> {
      Result.mapOk<(), (), SetDurationError>(verifyCredentials(caller), func () {
        scheduler_.setDuration(status, Utils.toTime(duration));
      });
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: QuestionQueries2.OrderBy, direction: QuestionQueries2.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries2.QueryQuestionsResult {
      queries_.queryItems(order_by, direction, limit, Option.map(previous_id, func(id: Nat) : Question { questions_.getQuestion(id); }));
    };

    public func openQuestion(caller: Principal, title: Text, text: Text, date: Time) : Result<Question, OpenQuestionError> {
      Result.mapOk<User, Question, OpenQuestionError>(getUser(caller), func(_) {
        let question = questions_.createQuestion(caller, date, title, text);
        manager_.openVote(question, #CANDIDATE);
        question;
      });
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : Result<(), ReopenQuestionError> {
      Result.chain<User, (), ReopenQuestionError>(getUser(caller), func(_) {
        Result.chain<Question, (), ReopenQuestionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), (), ReopenQuestionError>(Utils.toResult(StatusInfoHelper.isCurrentStatus(question, #CLOSED), #InvalidStatus), func() {
            let question = questions_.updateStatus(question_id, #VOTING(#CANDIDATE), date);
            manager_.openVote(question, #CANDIDATE);
          })
        })
      });
    };

    public func putBallot(caller: Principal, question_id: Nat, answer: TypedAnswer, date: Time) : Result<(), PutBallotError> {
      Result.chain<User, (), PutBallotError>(getUser(caller), func(_) {
        Result.chain<Question, (), PutBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<IndexedStatus, (), PutBallotError>(Result.fromOption(Manager.getVoteStatus(question, Manager.getVoteType(answer)), #InvalidStatus), func(_) {
            manager_.putBallot(caller, question, answer, date);
          })
        })
      });
    };

    public func removeBallot(caller: Principal, question_id: Nat, vote: VoteType) : Result<(), RemoveBallotError> {
      Result.chain<User, (), RemoveBallotError>(getUser(caller), func(_) {
        Result.chain<Question, (), RemoveBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.chain<(), (), RemoveBallotError>(Utils.toResult(vote == #CANDIDATE, #NotAuthorized), func() {
            Result.mapOk<IndexedStatus, (), RemoveBallotError>(Result.fromOption(Manager.getVoteStatus(question, vote), #InvalidStatus), func(_) {
              manager_.removeBallot(caller, question, vote);
            })
          })
        })
      });
    };

    public func getBallot(caller: Principal, question_id: Nat, iteration: Nat, vote: VoteType) : Result<?TypedBallot, GetBallotError> {
      Result.chain<User, ?TypedBallot, GetBallotError>(getUser(caller), func(_) {
        Result.chain<Question, ?TypedBallot, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), ?TypedBallot, GetBallotError>(Utils.toResult(StatusInfoHelper.isValidIteration(question, #VOTING(vote), iteration), #InvalidIteration), func() {
            manager_.getBallot(caller, question.id, iteration, vote);
          })
        })
      });
    };

    public func getUserBallot(principal: Principal, question_id: Nat, iteration: Nat, vote: VoteType) : Result<?TypedBallot, GetBallotError> {
      Result.chain<User, ?TypedBallot, GetBallotError>(getUser(principal), func(_) {
        Result.chain<Question, ?TypedBallot, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<(), ?TypedBallot, GetBallotError>(Utils.toResult(StatusInfoHelper.isHistoryIteration(question, #VOTING(vote), iteration), #InvalidIteration), func() {
            manager_.getBallot(principal, question.id, iteration, vote);
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
    public func polarizationTrieToArray(trie: Types.CategoryPolarizationTrie) : Types.CategoryPolarizationArray {
      Utils.trieToArray(trie);
    };

    // @todo
//    public func createQuestions(principal: Principal, inputs: [(Text, CreateQuestionStatus)]) : Result<[Question], CreateQuestionError> {
//      Result.chain<(), [Question], CreateQuestionError>(verifyCredentials(principal), func () {
//        Result.mapOk<User, [Question], CreateQuestionError>(getUser(principal), func(_) {
//          Admin.createQuestions(questions_, principal, inputs);
//        })
//      });
//    };

  };

};
