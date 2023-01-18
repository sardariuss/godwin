import Types "types";
import Users "users";
import Utils "utils";
import Scheduler "scheduler";
import Admin "admin";
import Question "questions/question";
import Questions "questions/questions";
import Queries "questions/queries";
import Cursor "representation/cursor";
import Votes "votes/votes";
import WSet "wrappers/WSet";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Time.Time;

  type WSet<K> = WSet.WSet<K>;

  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type User = Types.User;
  type Category = Types.Category;
  type CategoryCursorArray = Types.CategoryCursorArray;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Decay = Types.Decay;
  type Status = Types.Status;
  type Duration = Types.Duration;
  type Polarization = Types.Polarization;
  type CreateQuestionStatus = Types.CreateQuestionStatus;
  type Timestamp<T> = Types.Timestamp<T>;
  type InterestAggregate = Types.InterestAggregate;
  // Errors
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type SetSchedulerParamError = Types.SetSchedulerParamError;
  type GetQuestionError = Types.GetQuestionError;
  type CreateQuestionError = Types.CreateQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type InterestError = Types.InterestError;
  type OpinionError = Types.OpinionError;
  type CategorizationError = Types.CategorizationError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type GetUserError = Types.GetUserError;

  public class Game(
    admin_: Principal,
    categories_: WSet<Category>,
    users_: Users.Users,
    questions_: Questions.Questions,
    queries_: Queries.Queries,
    scheduler_: Scheduler.Scheduler,
    interest_votes_: Votes.Votes<Interest, InterestAggregate>,
    opinion_votes_: Votes.Votes<Cursor, Polarization>,
    categorization_votes_: Votes.Votes<CategoryCursorTrie, CategoryPolarizationTrie>,
  ) = {

    public func getDecay() : ?Decay {
      users_.getDecay();
    };

    public func getCategories() : [Category] {
      Iter.toArray(categories_.keys());
    };

    public func addCategory(principal: Principal, category: Category) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(principal), func() {
        Result.mapOk<(), (), AddCategoryError>(Utils.toResult(not categories_.has(category), #CategoryAlreadyExists), func() {
          categories_.add(category);
          // Also add the category to users' profile // @todo: use an obs instead?
          users_.addCategory(category);
        })
      });
    };

    public func removeCategory(principal: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(principal), func () {
        Result.mapOk<(), (), RemoveCategoryError>(Utils.toResult(categories_.has(category), #CategoryDoesntExist), func() {
          categories_.add(category);
          // Also remove the category from users' profile // @todo: use an obs instead?
          users_.removeCategory(category);
        })
      });
    };

    public func getSelectionRate() : Duration {
      scheduler_.getSelectionRate();
    };

    public func setSelectionRate(principal: Principal, duration: Duration) : Result<(), SetSchedulerParamError> {
      Result.mapOk<(), (), VerifyCredentialsError>(verifyCredentials(principal), func () {
        scheduler_.setSelectionRate(duration);
      });
    };

    public func getStatusDuration(status: Status) : ?Duration {
      scheduler_.getStatusDuration(status);
    };

    public func setStatusDuration(principal: Principal, status: Status, duration: Duration) : Result<(), SetSchedulerParamError> {
      Result.mapOk<(), (), VerifyCredentialsError>(verifyCredentials(principal), func () {
        scheduler_.setStatusDuration(status, duration);
      });
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: Queries.OrderBy, direction: Queries.QueryDirection, limit: Nat, previous_id: ?Nat) : Queries.QueryQuestionsResult {
      questions_.queryQuestions(queries_, order_by, direction, limit, previous_id);
    };

    public func createQuestions(principal: Principal, inputs: [(Text, CreateQuestionStatus)]) : Result<[Question], CreateQuestionError> {
      Result.chain<(), [Question], CreateQuestionError>(verifyCredentials(principal), func () {
        Result.mapOk<User, [Question], CreateQuestionError>(getUser(principal), func(_) {
          Admin.createQuestions(questions_, principal, inputs);
        })
      });
    };

    public func openQuestion(principal: Principal, title: Text, text: Text) : Result<Question, OpenQuestionError> {
      Result.mapOk<User, Question, OpenQuestionError>(getUser(principal), func(_) {
        let question = questions_.createQuestion(principal, Time.now(), title, text);
        interest_votes_.newAggregate(question.id, 0, Time.now());
        question;
      });
    };

    public func reopenQuestion(principal: Principal, question_id: Nat) : Result<(), InterestError> {
      Result.chain<User, (), InterestError>(getUser(principal), func(_) {
        Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<Question, (), InterestError>(Question.reopenQuestion(question), func(question) {
            questions_.replaceQuestion(question);
          });
        })
      });
    };

    public func setInterest(principal: Principal, question_id: Nat, interest: Interest) : Result<(), InterestError> {
      Result.chain<User, (), InterestError>(getUser(principal), func(_) {
        Result.mapOk<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          // @todo: verify question status, get the current iteration
          interest_votes_.putBallot(principal, question_id, 0, Time.now(), interest);
        })
      });
    };

    public func removeInterest(principal: Principal, question_id: Nat) : Result<(), InterestError> {
      Result.chain<User, (), InterestError>(getUser(principal), func(_) {
        Result.mapOk<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          // @todo: verify question status, get the current iteration
          interest_votes_.removeBallot(principal, question_id, 0);
        })
      });
    };

    public func getInterest(principal: Principal, question_id: Nat, iteration: Nat) : Result<?Timestamp<Interest>, InterestError> {
      Result.chain<User, ?Timestamp<Interest>, InterestError>(getUser(principal), func(_) {
        Result.mapOk<Question, ?Timestamp<Interest>, InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          interest_votes_.getBallot(principal, question_id, iteration);
        })
      });
    };

    public func setOpinion(principal: Principal, question_id: Nat, cursor: Cursor) : Result<(), OpinionError> {
      Result.chain<User, (), OpinionError>(getUser(principal), func(_) {
        Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(cursor) {
          Result.mapOk<Question, (), OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
            // @todo: verify question status, get the current iteration
            opinion_votes_.putBallot(principal, question_id, 0, Time.now(), cursor);
          })
        })
      });
    };

    public func getOpinion(principal: Principal, question_id: Nat, iteration: Nat) : Result<?Timestamp<Cursor>, OpinionError> {
      Result.chain<User, ?Timestamp<Cursor>, OpinionError>(getUser(principal), func(_) {
        Result.mapOk<Question, ?Timestamp<Cursor>, OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          opinion_votes_.getBallot(principal, question_id, iteration);
        })
      });
    };

    public func setCategorization(principal: Principal, question_id: Nat, cursor_array: CategoryCursorArray) : Result<(), CategorizationError> {
      Result.chain<User, (), CategorizationError>(getUser(principal), func(_) {
        Result.mapOk<Question, (), CategorizationError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          // @todo: verify question status, get the current iteration
          categorization_votes_.putBallot(principal, question_id, 0, Time.now(), Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal));
        })
      });
    };

    public func getCategorization(principal: Principal, question_id: Nat, iteration: Nat) : Result<?Timestamp<CategoryCursorTrie>, CategorizationError> {
      Result.chain<User, ?Timestamp<CategoryCursorTrie>, CategorizationError>(getUser(principal), func(_) {
        Result.mapOk<Question, ?Timestamp<CategoryCursorTrie>, CategorizationError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          categorization_votes_.getBallot(principal, question_id, iteration);
        })
      });
    };

    public func run() {
      let time_now = Time.now();
      ignore scheduler_.openOpinionVote(time_now);
      ignore scheduler_.openCategorizationVote(time_now, Iter.toArray(categories_.keys()));
      ignore scheduler_.closeQuestion(time_now);
      ignore scheduler_.rejectQuestions(time_now);
      ignore scheduler_.deleteQuestions(time_now);
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

  };

};
