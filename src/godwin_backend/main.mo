import Question "questions/question";
import Questions "questions/questions";
import Queries "questions/queries";
import Cursor "representation/cursor";
import Types "types";
import Categories "categories";
import Users "users";
import Utils "utils";
import Scheduler "scheduler";
import Decay "decay";
import Admin "admin";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Option "mo:base/Option";

shared({ caller = admin_ }) actor class Godwin(parameters: Types.Parameters) = {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type User = Types.User;
  type SchedulerParams = Types.SchedulerParams;
  type Category = Types.Category;
  type CategoryCursorArray = Types.CategoryCursorArray;
  type DecayParams = Types.DecayParams;
  type Status = Types.Status;
  type Duration = Types.Duration;

  /// Stable types
  stable var categories_ = Categories.fromArray(parameters.categories);
  stable var decay_params_ = Decay.computeOptDecayParams(Time.now(), parameters.convictions_half_life);
  stable var users_register_ = Users.initRegister();
  stable var questions_register_ = Questions.initRegister();
  stable var scheduler_register_ = Scheduler.initRegister(parameters.scheduler, Time.now());

  /// Members
  let users_ = Users.Users(users_register_);
  let questions_ = Questions.Questions(questions_register_);
  let scheduler_ = Scheduler.Scheduler(scheduler_register_, questions_, users_, decay_params_);

  public query func getSchedulerParams() : async SchedulerParams {
    scheduler_.getParams();
  };

  // Required to normalize the convictions in the front-end
  public query func getDecayParams() : async ?DecayParams {
    decay_params_;
  };

  public query func getCategories() : async [Category] {
    Categories.toArray(categories_);
  };

  public type AddCategoryError = {
    #InsufficientCredentials;
    #CategoryAlreadyExists;
  };

  public shared({caller}) func addCategory(category: Category) : async Result<(), AddCategoryError> {
    Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func () {
      if (Categories.contains(categories_, category)) { #err(#CategoryAlreadyExists); }
      else { 
        categories_ := Categories.add(categories_, category);
        // Also add the category to users' profile
        users_.addCategory(category);
        #ok;
      };
    });
  };

  public type RemoveCategoryError = {
    #InsufficientCredentials;
    #CategoryDoesntExist;
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
      if (not Categories.contains(categories_, category)) { #err(#CategoryDoesntExist); }
      else { 
        categories_ := Categories.remove(categories_, category); 
        // Also remove the category from users' profile
        users_.removeCategory(category);
        #ok;
      };
    });
  };

  public type SetSchedulerParamError = {
    #InsufficientCredentials;
  };

  public shared({caller}) func setSchedulerParam(status: Status, duration: Duration) : async Result<(), SetSchedulerParamError> {
    Result.mapOk<(), (), VerifyCredentialsError>(verifyCredentials(caller), func () {
      scheduler_.setParam(status, duration);
    });
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public query func getQuestion(question_id: Nat32) : async Result<Question, GetQuestionError> {
    Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
  };

  public query func getQuestions(order_by: Queries.OrderBy, direction: Queries.QueryDirection, limit: Nat, previous_id: ?Nat32) : async Queries.QueryQuestionsResult {
    questions_.queryQuestions(order_by, direction, limit, previous_id);
  };

  public type CreateQuestionError = {
    #PrincipalIsAnonymous;
    #InsufficientCredentials;
  };

  public shared({caller}) func createQuestions(inputs: [(Text, Admin.CreateQuestionStatus)]) : async Result<[Question], CreateQuestionError> {
    Result.chain<(), [Question], CreateQuestionError>(verifyCredentials(caller), func () {
      Result.mapOk<User, [Question], CreateQuestionError>(getUser(caller), func(_) {
        Admin.createQuestions(questions_, caller, inputs);
      })
    });
  };

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
  };

  public shared({caller}) func openQuestion(title: Text, text: Text) : async Result<Question, OpenQuestionError> {
    Result.mapOk<User, Question, OpenQuestionError>(getUser(caller), func(_) {
      questions_.createQuestion(caller, Time.now(), title, text);
    });
  };

  public shared({caller}) func reopenQuestion(question_id: Nat32) : async Result<(), InterestError> {
    Result.chain<User, (), InterestError>(getUser(caller), func(_) {
      Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        Result.mapOk<Question, (), InterestError>(Question.reopenQuestion(question), func(question) {
          questions_.replaceQuestion(question);
        });
      })
    });
  };

  public type InterestError = {
    #PrincipalIsAnonymous;
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public shared({caller}) func setInterest(question_id: Nat32, interest: Interest) : async Result<(), InterestError> {
    Result.chain<User, (), InterestError>(getUser(caller), func(_) {
      Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        Result.mapOk<Question, (), InterestError>(Question.putInterest(question, caller, interest), func(question) {
          questions_.replaceQuestion(question);
        });
      })
    });
  };

  public shared({caller}) func removeInterest(question_id: Nat32) : async Result<(), InterestError> {
    Result.chain<User, (), InterestError>(getUser(caller), func(_) {
      Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        Result.mapOk<Question, (), InterestError>(Question.removeInterest(question, caller), func(question) {
          questions_.replaceQuestion(question);
        });
      })
    });
  };

  public type OpinionError = {
    #PrincipalIsAnonymous;
    #InvalidOpinion;
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public shared({caller}) func setOpinion(question_id: Nat32, cursor: Cursor) : async Result<(), OpinionError> {
    Result.chain<User, (), OpinionError>(getUser(caller), func(_) {
      Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(cursor) {
        Result.chain<Question, (), OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.mapOk<Question, (), OpinionError>(Question.putOpinion(question, caller, cursor), func(question) {
            questions_.replaceQuestion(question);
          });
        })
      })
    });
  };

  public type CategorizationError = {
    #PrincipalIsAnonymous;
    #InvalidVotingStage;
    #InvalidCategorization;
    #QuestionNotFound;
  };

  public shared({caller}) func setCategorization(question_id: Nat32, cursor_array: CategoryCursorArray) : async Result<(), CategorizationError> {
    Result.chain<User, (), CategorizationError>(getUser(caller), func(_) {
      Result.chain<Question, (), CategorizationError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        let cursor_trie = Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal);
        Result.mapOk<Question, (), CategorizationError>(Question.putCategorization(question, caller, cursor_trie), func(question) {
          questions_.replaceQuestion(question);
        });
      })
    });
  };

  public shared func run() {
    let time_now = Time.now();
    ignore scheduler_.openOpinionVote(time_now);
    ignore scheduler_.openCategorizationVote(time_now, Categories.toArray(categories_));
    ignore scheduler_.closeQuestion(time_now);
    ignore scheduler_.rejectQuestions(time_now);
    ignore scheduler_.deleteQuestions(time_now);
  };

  public query func findUser(principal: Principal) : async ?User {
    users_.findUser(principal);
  };

  type SetUserNameError = {
    #PrincipalIsAnonymous;
  };

  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    Result.mapOk<User, (), SetUserNameError>(getUser(caller), func(_) {
      users_.setUserName(caller, name);
    });
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials(caller: Principal) : Result<(), VerifyCredentialsError> {
    if (caller != admin_) { #err(#InsufficientCredentials); }
    else { #ok; };
  };

  public type GetUserError = {
    #PrincipalIsAnonymous;
  };

  func getUser(principal: Principal) : Result<User, GetUserError> {
    if (Principal.isAnonymous(principal)) { #err(#PrincipalIsAnonymous); }
    else { 
      #ok(users_.getOrCreateUser(principal, Categories.toArray(categories_)));
    };
  };

  // @todo: remove
  public query func polarizationTrieToArray(trie: Types.CategoryPolarizationTrie) : async Types.CategoryPolarizationArray {
    Utils.trieToArray(trie);
  };

};
