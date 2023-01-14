import Types "types";
import Categories "categories";
import Users "users";
import Utils "utils";
import Scheduler "scheduler";
import Decay "decay";
import Admin "admin";
import Question "questions/question";
import Questions "questions/questions";
import Queries "questions/queries";
import Cursor "representation/cursor";
import Polarization "representation/polarization";
import CategoryPolarizationTrie "representation/categoryPolarizationTrie";
import Votes "votes/votes";
import Interests "votes/interests";
import WrappedRef "ref/wrappedRef";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Time.Time;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Trie2D<K1, K2, V> = Trie.Trie2D<K1, K2, V>;
  type Trie3D<K1, K2, K3, V> = Trie.Trie3D<K1, K2, K3, V>;

  // For convenience: from types module
  type Parameters = Types.Parameters;
  type Question = Types.Question;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type User = Types.User;
  type SchedulerParams = Types.SchedulerParams;
  type Category = Types.Category;
  type CategoryCursorArray = Types.CategoryCursorArray;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type DecayParams = Types.DecayParams;
  type Status = Types.Status;
  type Duration = Types.Duration;
  type Polarization = Types.Polarization;
  type CreateQuestionStatus = Types.CreateQuestionStatus;
  type WrappedRef<T> = WrappedRef.WrappedRef<T>;
  type Timestamp<T> = Votes.Timestamp<T>;
  type InterestAggregate = Types.InterestAggregate;
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

  type Register = {
    var categories      : Categories.Categories;
    decay_params        : ?DecayParams;
    users_register      : Users.Register;
    questions_register  : Questions.Register;
    scheduler_register  : Scheduler.Register;
    queries_register    : Queries.Register;
    interest_votes      : {
      ballots             : WrappedRef<Trie3D<Principal, Nat32, Nat, Timestamp<Interest>>>;
      aggregates          : WrappedRef<Trie2D<Nat32, Nat, Timestamp<InterestAggregate>>>;
    };
    opinion_votes      : {
      ballots             : WrappedRef<Trie3D<Principal, Nat32, Nat, Timestamp<Cursor>>>;
      aggregates          : WrappedRef<Trie2D<Nat32, Nat, Timestamp<Polarization>>>;
    };
    categorization_votes: {
      ballots             : WrappedRef<Trie3D<Principal, Nat32, Nat, Timestamp<CategoryCursorTrie>>>;
      aggregates          : WrappedRef<Trie2D<Nat32, Nat, Timestamp<CategoryPolarizationTrie>>>;
    };
    admin               : Principal;
  };

  public func initRegister(admin: Principal, parameters: Parameters, now: Time) : Register {
    {
      var categories      = Categories.fromArray(parameters.categories);
      decay_params        = Decay.computeOptDecayParams(Time.now(), parameters.convictions_half_life);
      users_register      = Users.initRegister();
      questions_register  = Questions.initRegister();
      scheduler_register  = Scheduler.initRegister(parameters.scheduler, Time.now());
      queries_register    = Queries.initRegister();
      interest_votes      = {
        ballots             = WrappedRef.init(Trie.empty<Principal, Trie<Nat32, Trie<Nat, Timestamp<Interest>>>>());
        aggregates          = WrappedRef.init(Trie.empty<Nat32, Trie<Nat, Timestamp<InterestAggregate>>>());
      };
      opinion_votes      = {
        ballots             = WrappedRef.init(Trie.empty<Principal, Trie<Nat32, Trie<Nat, Timestamp<Cursor>>>>());
        aggregates          = WrappedRef.init(Trie.empty<Nat32, Trie<Nat, Timestamp<Polarization>>>());
      };
      categorization_votes = {
        ballots             = WrappedRef.init(Trie.empty<Principal, Trie<Nat32, Trie<Nat, Timestamp<CategoryCursorTrie>>>>());
        aggregates          = WrappedRef.init(Trie.empty<Nat32, Trie<Nat, Timestamp<CategoryPolarizationTrie>>>());
      };
      admin;
    };
  };

  public class Game(register_: Register) = {

    // @todo: put this in a factory?
    // Members
    let users_ = Users.Users(register_.users_register);
    let questions_ = Questions.Questions(register_.questions_register);
    let queries_ = Queries.Queries(register_.queries_register);
    let scheduler_ = Scheduler.Scheduler(register_.scheduler_register, questions_, users_, queries_, register_.decay_params);
    let interest_votes_ = Votes.Votes(register_.interest_votes.ballots, register_.interest_votes.aggregates, Interests.emptyAggregate, Interests.addToAggregate, Interests.removeFromAggregate);
    let polarization_votes_ = Votes.Votes(register_.opinion_votes.ballots, register_.opinion_votes.aggregates, Polarization.nil, Polarization.addCursor, Polarization.subCursor);
    // @todo: temp empty function, normally requires the categories
    func emptyCategoryPolarizationTrie() : CategoryPolarizationTrie {
      Trie.empty<Category, Polarization>();
    };
    let categorization_votes_ = Votes.Votes(register_.categorization_votes.ballots, register_.categorization_votes.aggregates, emptyCategoryPolarizationTrie, CategoryPolarizationTrie.addCategoryCursorTrie, CategoryPolarizationTrie.subCategoryCursorTrie);

    // Add observers to sync queries
    questions_.addObs(#QUESTION_ADDED, queries_.add);
    questions_.addObs(#QUESTION_REMOVED, queries_.remove);

    public func getDecayParams() : ?DecayParams {
      register_.decay_params;
    };

    public func getCategories() : [Category] {
      Categories.toArray(register_.categories);
    };

    public func addCategory(principal: Principal, category: Category) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(principal), func () {
        if (Categories.contains(register_.categories, category)) { #err(#CategoryAlreadyExists); }
        else { 
          register_.categories := Categories.add(register_.categories, category);
          // Also add the category to users' profile
          users_.addCategory(category);
          #ok;
        };
      });
    };

    public func removeCategory(principal: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(principal), func () {
        if (not Categories.contains(register_.categories, category)) { #err(#CategoryDoesntExist); }
        else { 
          register_.categories := Categories.remove(register_.categories, category); 
          // Also remove the category from users' profile
          users_.removeCategory(category);
          #ok;
        };
      });
    };

    public func getSchedulerParams() : SchedulerParams {
      scheduler_.getParams();
    };

    public func setSchedulerParam(principal: Principal, status: Status, duration: Duration) : Result<(), SetSchedulerParamError> {
      Result.mapOk<(), (), VerifyCredentialsError>(verifyCredentials(principal), func () {
        scheduler_.setParam(status, duration);
      });
    };

    public func getQuestion(question_id: Nat32) : Result<Question, GetQuestionError> {
      Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: Queries.OrderBy, direction: Queries.QueryDirection, limit: Nat, previous_id: ?Nat32) : Queries.QueryQuestionsResult {
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
        interest_votes_.newVote(question.id, 0, Time.now());
        question;
      });
    };

    public func reopenQuestion(principal: Principal, question_id: Nat32) : Result<(), InterestError> {
      Result.chain<User, (), InterestError>(getUser(principal), func(_) {
        Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<Question, (), InterestError>(Question.reopenQuestion(question), func(question) {
            questions_.replaceQuestion(question);
          });
        })
      });
    };

    public func setInterest(principal: Principal, question_id: Nat32, interest: Interest) : Result<(), InterestError> {
      Result.chain<User, (), InterestError>(getUser(principal), func(_) {
        Result.mapOk<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          interest_votes_.putBallot(principal, question_id, 0, { date = Time.now(); elem = interest });
          //Result.mapOk<Question, (), InterestError>(Question.putInterest(question, principal, interest), func(question) {
          //  questions_.replaceQuestion(question);
          //});
        })
      });
    };

    public func removeInterest(principal: Principal, question_id: Nat32) : Result<(), InterestError> {
      Result.chain<User, (), InterestError>(getUser(principal), func(_) {
        Result.mapOk<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          interest_votes_.removeBallot(principal, question_id, 0);
          //Result.mapOk<Question, (), InterestError>(Question.removeInterest(question, principal), func(question) {
            //questions_.replaceQuestion(question);
          //});
        })
      });
    };

    public func getInterest(principal: Principal, question_id: Nat32) : Result<?Timestamp<Interest>, InterestError> {
      Result.chain<User, ?Timestamp<Interest>, InterestError>(getUser(principal), func(_) {
        Result.mapOk<Question, ?Timestamp<Interest>, InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          interest_votes_.getBallot(principal, question_id, 0);
          //Result.mapOk<Question, (), InterestError>(Question.removeInterest(question, principal), func(question) {
            //questions_.replaceQuestion(question);
          //});
        })
      });
    };

    public func setOpinion(principal: Principal, question_id: Nat32, cursor: Cursor) : Result<(), OpinionError> {
      Result.chain<User, (), OpinionError>(getUser(principal), func(_) {
        Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(cursor) {
          Result.chain<Question, (), OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
            Result.mapOk<Question, (), OpinionError>(Question.putOpinion(question, principal, cursor), func(question) {
              questions_.replaceQuestion(question);
            });
          })
        })
      });
    };

    public func setCategorization(principal: Principal, question_id: Nat32, cursor_array: CategoryCursorArray) : Result<(), CategorizationError> {
      Result.chain<User, (), CategorizationError>(getUser(principal), func(_) {
        Result.chain<Question, (), CategorizationError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          let cursor_trie = Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal);
          Result.mapOk<Question, (), CategorizationError>(Question.putCategorization(question, principal, cursor_trie), func(question) {
            questions_.replaceQuestion(question);
          });
        })
      });
    };

    public func run() {
      let time_now = Time.now();
      ignore scheduler_.openOpinionVote(time_now);
      ignore scheduler_.openCategorizationVote(time_now, Categories.toArray(register_.categories));
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
      if (principal != register_.admin) { #err(#InsufficientCredentials); }
      else { #ok; };
    };

    func getUser(principal: Principal) : Result<User, GetUserError> {
      if (Principal.isAnonymous(principal)) { #err(#PrincipalIsAnonymous); }
      else { 
        #ok(users_.getOrCreateUser(principal, Categories.toArray(register_.categories)));
      };
    };

    // @todo: remove
    public func polarizationTrieToArray(trie: Types.CategoryPolarizationTrie) : Types.CategoryPolarizationArray {
      Utils.trieToArray(trie);
    };

  };

};
