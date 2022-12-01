import Question "questions/question";
import Questions "questions/questions";
import Interests "votes/interests";
import Opinions "votes/opinions";
import Categorizations "votes/categorizations";
import Cursor "representation/cursor";
import Types "types";
import Categories "categories";
import Users "users";
import User "user";
import Utils "utils";
import Scheduler "scheduler";

import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";
import Nat "mo:base/Nat";

shared({ caller = admin_ }) actor class Godwin(parameters: Types.Parameters) = {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type User = Types.User;
  type SchedulerParams = Types.SchedulerParams;
  type Category = Types.Category;
  type CategoryCursorArray = Types.CategoryCursorArray;
  type CategoryCursorTrie = Types.CategoryCursorTrie;

  // Members
  var categories_ = Categories.Categories(parameters.categories);
  var users_ = Users.empty(categories_);
  var questions_ = Questions.empty(categories_);
  var scheduler_ = Scheduler.Scheduler({ params = parameters.scheduler; last_selection_date = Time.now(); });

  // For upgrades
  stable var categories_shareable_ = categories_.share();
  stable var users_shareable_ = users_.share();
  stable var questions_shareable_ = questions_.share();
  stable var scheduler_shareable_ = scheduler_.share();

  public func getSchedulerParams() : async SchedulerParams {
    scheduler_.share().params;
  };

  public func getCategories() : async [Category] {
    categories_.share();
  };

  public type AddCategoryError = {
    #InsufficientCredentials;
    #CategoryAlreadyExists;
  };

  public shared({caller}) func addCategory(category: Category) : async Result<(), AddCategoryError> {
    Result.chain<User, (), AddCategoryError>(verifyCredentials(caller), func (admin: User) {
      if (categories_.contains(category)) { #err(#CategoryAlreadyExists); }
      else { #ok(categories_.add(category)); };
    });
  };

  public type RemoveCategoryError = {
    #InsufficientCredentials;
    #CategoryDoesntExist;
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    Result.chain<User, (), RemoveCategoryError>(verifyCredentials(caller), func (admin: User) {
      if (not categories_.contains(category)) { #err(#CategoryDoesntExist); }
      else { #ok(categories_.remove(category)); };
    });
  };

  public shared({caller}) func setSchedulerParams(scheduler_params : SchedulerParams) : async Result<(), VerifyCredentialsError> {
    Result.mapOk<User, (), VerifyCredentialsError>(verifyCredentials(caller), func (admin: User) {
      scheduler_.setParams(scheduler_params);
    });
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public shared query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    questions_.createQuestion(caller, Time.now(), title, text);
  };

  public type InterestError = {
    #QuestionNotFound;
    #IsAnonymous;
  };

  public shared({caller}) func setInterest(question_id: Nat, interest: Interest) : async Result<(), InterestError> {
    Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(_) {
      Result.mapOk<User, (), InterestError>(Result.fromOption(users_.findUser(caller), #IsAnonymous), func(_) {
        Interests.put(users_, caller, questions_, question_id, interest);
      });
    });
  };

  public shared({caller}) func removeInterest(question_id: Nat) : async Result<(), InterestError> {
    Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(_) {
      Result.mapOk<User, (), InterestError>(Result.fromOption(users_.findUser(caller), #IsAnonymous), func(_) {
        Interests.remove(users_, caller, questions_, question_id);
      });
    });
  };

  public type OpinionError = {
    #IsAnonymous;
    #InvalidOpinion;
    #QuestionNotFound;
    #WrongSelectionStage;
  };

  public shared query func getOpinion(principal: Principal, question_id: Nat) : async Result<?Cursor, OpinionError> {
    Result.chain<User, ?Cursor, OpinionError>(Result.fromOption(users_.findUser(principal), #IsAnonymous), func(user) {
      Result.mapOk<Question, ?Cursor, OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(_) {
        User.getOpinion(user, question_id);
      })
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, cursor: Cursor) : async Result<(), OpinionError> {
    Result.chain<User, (), OpinionError>(Result.fromOption(users_.findUser(caller), #IsAnonymous), func(_) {
      Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(opinion) {
        Result.chain<Question, (), OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          let verify_result = Result.fromOption(Question.verifyCurrentSelectionStage(question, [#SELECTED]), #WrongSelectionStage);
          Result.mapOk<Question, (), OpinionError>(verify_result, func(_) {
            Opinions.put(users_, caller, questions_, question_id, opinion);
          })
        })
      })
    });
  };

  public type CategorizationError = {
    #InsufficientCredentials;
    #InvalidCategorization;
    #QuestionNotFound;
    #WrongCategorizationStage;
  };

  public shared({caller}) func setCategorization(question_id: Nat, cursor_array: CategoryCursorArray) : async Result<(), CategorizationError> {
    Result.chain<User, (), CategorizationError>(verifyCredentials(caller), func (_: User) {
      Result.chain<Question, (), CategorizationError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        let verify_result = Result.fromOption(Question.verifyCategorizationStage(question, [#ONGOING]), #WrongCategorizationStage);
        Result.chain<Question, (), CategorizationError>(verify_result, func(_) {
          let verified = Result.fromOption(users_.verifyCategorization(Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal)), #InvalidCategorization);
          Result.mapOk<CategoryCursorTrie, (), CategorizationError>(verified, func(cursor_trie: CategoryCursorTrie) {
            Categorizations.put(users_, caller, questions_, question_id, cursor_trie);
          })
        })
      })
    });
  };

  // @todo: call in a heartbeat
  public shared func run() {
    let time_now = Time.now();
    ignore scheduler_.selectQuestion(questions_, time_now);
    ignore scheduler_.archiveQuestion(questions_, time_now);
    ignore scheduler_.closeCategorization(questions_, users_, time_now);
  };

  public type GetUserError = {
    #IsAnonymous;
  };

  public shared func findUser(principal: Principal) : async Result<User, GetUserError> {
    Result.fromOption(users_.findUser(principal), #IsAnonymous);
  };

  public shared func updateConvictions(principal: Principal) : async Result<User, GetUserError> {
    Result.mapOk<User, User, GetUserError>(Result.fromOption(users_.findUser(principal), #IsAnonymous), func(_){
      users_.updateConvictions(principal, questions_);
    });
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials(caller: Principal) : Result<User, VerifyCredentialsError> {
    if (caller != admin_) { #err(#InsufficientCredentials); }
    else { #ok(users_.getUser(caller)); };
  };

  system func preupgrade(){
    categories_shareable_ := categories_.share();
    users_shareable_ := users_.share();
    questions_shareable_ := questions_.share();
    scheduler_shareable_ := scheduler_.share();
  };

  system func postupgrade(){
    categories_ := Categories.Categories(categories_shareable_);
    users_ := Users.Users(users_shareable_, categories_);
    questions_ := Questions.Questions(questions_shareable_, categories_);
    scheduler_ := Scheduler.Scheduler(scheduler_shareable_);
  };

};
