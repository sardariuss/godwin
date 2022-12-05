import Question "questions/question";
import Questions "questions/questions";
import Opinions "votes/opinions";
import Iterations "votes/register";
import Categorizations "votes/categorizations";
import Cursor "representation/cursor";
import Types "types";
import Categories "categories";
import Users "users";
import Utils "utils";
import Scheduler "scheduler";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";
import TrieSet "mo:base/TrieSet";

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
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type Iteration = Types.Iteration;

  // Members
  var categories_ = Categories.Categories(parameters.categories);
  var users_ = Users.empty(categories_);
  var questions_ = Questions.empty();
  stable var iterations_ = Iterations.empty();
  var old_opinions_ = Opinions.empty();
  var old_categorizations_ = Categorizations.empty(categories_);
  var scheduler_ = Scheduler.Scheduler({ params = parameters.scheduler; last_selection_date = Time.now(); });

  // For upgrades
  stable var categories_shareable_ = categories_.share();
  stable var users_shareable_ = users_.share();
  stable var questions_shareable_ = questions_.share();
  stable var old_opinions_shareable_ = old_opinions_.share();
  stable var old_categorizations_shareable_ = old_categorizations_.share();
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
    Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func () {
      if (categories_.contains(category)) { #err(#CategoryAlreadyExists); }
      else { #ok(categories_.add(category)); };
    });
  };

  public type RemoveCategoryError = {
    #InsufficientCredentials;
    #CategoryDoesntExist;
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
      if (not categories_.contains(category)) { #err(#CategoryDoesntExist); }
      else { #ok(categories_.remove(category)); };
    });
  };

  public shared({caller}) func setSchedulerParams(scheduler_params : SchedulerParams) : async Result<(), VerifyCredentialsError> {
    Result.mapOk<(), (), VerifyCredentialsError>(verifyCredentials(caller), func () {
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
    #VoteNotFound;
  };

  public shared query func getInterest(iteration_id: Nat, principal: Principal) : async Result<?Interest, InterestError> {
    Result.mapOk<Iteration, ?Interest, InterestError>(Result.fromOption(Iterations.findIteration(iterations_, iteration_id), #VoteNotFound), func(iteration) {
      Iterations.getInterest(iterations_, iteration_id, principal);
    });
  };

  public shared({caller}) func setInterest(iteration_id: Nat, interest: Interest) : async Result<(), InterestError> {
    Result.mapOk<Iteration, (), InterestError>(Result.fromOption(Iterations.findIteration(iterations_, iteration_id), #VoteNotFound), func(iteration) {
      iterations_ := Iterations.putInterest(iterations_, iteration_id, caller, interest);
    });
  };

  public shared({caller}) func removeInterest(iteration_id: Nat) : async Result<(), InterestError> {
    Result.mapOk<Iteration, (), InterestError>(Result.fromOption(Iterations.findIteration(iterations_, iteration_id), #VoteNotFound), func(iteration) {
      iterations_ := Iterations.removeInterest(iterations_, iteration_id, caller);
    });
  };

  public type OpinionError = {
    #InvalidOpinion;
    #VoteNotFound;
    #WrongSelectionStage;
  };

  public shared query func getOpinion(iteration_id: Nat, principal: Principal) : async Result<?Cursor, OpinionError> {
    Result.mapOk<Iteration, ?Cursor, OpinionError>(Result.fromOption(Iterations.findIteration(iterations_, iteration_id), #VoteNotFound), func(iteration) {
      Iterations.getOpinion(iterations_, iteration_id, principal);
    });
  };

  public shared({caller}) func setOpinion(iteration_id: Nat, cursor: Cursor) : async Result<(), OpinionError> {
    Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(cursor) {
      Result.mapOk<Iteration, (), OpinionError>(Result.fromOption(Iterations.findIteration(iterations_, iteration_id), #VoteNotFound), func(iteration) {
        iterations_ := Iterations.putOpinion(iterations_, iteration_id, caller, cursor);
        //let verify_result = Result.fromOption(Question.verifyCurrentSelectionStage(question, [#SELECTED]), #WrongSelectionStage);
        //Result.mapOk<Question, (), OpinionError>(verify_result, func(question) {
          //
        //})
      })
    });
  };

  public type CategorizationError = {
    #InsufficientCredentials;
    #InvalidCategorization;
    #VoteNotFound;
    #WrongCategorizationStage;
  };

  public shared({caller}) func setCategorization(iteration_id: Nat, cursor_array: CategoryCursorArray) : async Result<(), CategorizationError> {
    Result.chain<(), (), CategorizationError>(verifyCredentials(caller), func () {
      Result.chain<Iteration, (), CategorizationError>(Result.fromOption(Iterations.findIteration(iterations_, iteration_id), #VoteNotFound), func(iteration) {
        //let verify_result = Result.fromOption(Question.verifyCategorizationStage(question, [#ONGOING]), #WrongCategorizationStage);
        //Result.chain<Question, (), CategorizationError>(verify_result, func(question) {
          let verified = Result.fromOption(old_categorizations_.verifyBallot(Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal)), #InvalidCategorization);
          Result.mapOk<CategoryCursorTrie, (), CategorizationError>(verified, func(cursor_trie: CategoryCursorTrie) {
            iterations_ := Iterations.putCategorization(iterations_, iteration_id, caller, cursor_trie);
          })
        //})
      })
    });
  };

  // @todo: call in a heartbeat
  public shared func run() {
    let time_now = Time.now();
    ignore scheduler_.selectQuestion(questions_, time_now);
    ignore scheduler_.archiveQuestion(questions_, time_now);
    ignore scheduler_.closeCategorization(questions_, users_, old_opinions_, old_categorizations_, time_now);
  };

  public type GetUserError = {
    #IsAnonymous;
  };

  public shared func findUser(principal: Principal) : async Result<User, GetUserError> {
    Result.fromOption(users_.findUser(principal), #IsAnonymous);
  };

  public shared func updateConvictions(principal: Principal) : async Result<User, GetUserError> {
    Result.mapOk<User, User, GetUserError>(Result.fromOption(users_.findUser(principal), #IsAnonymous), func(_){
      users_.updateConvictions(principal, questions_, old_opinions_);
    });
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials(caller: Principal) : Result<(), VerifyCredentialsError> {
    if (caller != admin_) { #err(#InsufficientCredentials); }
    else { #ok; };
  };

  system func preupgrade(){
    categories_shareable_ := categories_.share();
    users_shareable_ := users_.share();
    questions_shareable_ := questions_.share();
    old_opinions_shareable_ := old_opinions_.share();
    old_categorizations_shareable_ := old_categorizations_.share();
    scheduler_shareable_ := scheduler_.share();
  };

  system func postupgrade(){
    categories_ := Categories.Categories(categories_shareable_);
    users_ := Users.Users(users_shareable_, categories_);
    questions_ := Questions.Questions(questions_shareable_);
    old_opinions_ := Opinions.Opinions(old_opinions_shareable_);
    old_categorizations_ := Categorizations.Categorizations(old_categorizations_shareable_, categories_);
    scheduler_ := Scheduler.Scheduler(scheduler_shareable_);
  };

};
