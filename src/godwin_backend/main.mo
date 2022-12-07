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
    let time_now = Time.now();
    let question = questions_.createQuestion(caller, time_now, title, text, iterations_.index);
    iterations_ := Iterations.newIteration(iterations_, question.id, time_now).0;
    question;
  };

  public type InterestError = {
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public shared query func getInterest(question_id: Nat, principal: Principal) : async Result<?Interest, InterestError> {
    Result.mapOk<Question, ?Interest, InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
      Iterations.getInterest(iterations_, question.iterations.current, principal);
    });
  };

  public shared({caller}) func setInterest(question_id: Nat, interest: Interest) : async Result<(), InterestError> {
    Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
      if (Iterations.get(iterations_, question.iterations.current).voting_stage != #INTEREST) { return #err(#InvalidVotingStage); };
      #ok(iterations_ := Iterations.putInterest(iterations_, question.iterations.current, caller, interest));
    });
  };

  public shared({caller}) func removeInterest(question_id: Nat) : async Result<(), InterestError> {
    Result.chain<Question, (), InterestError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
      if (Iterations.get(iterations_, question.iterations.current).voting_stage != #INTEREST) { return #err(#InvalidVotingStage); };
      #ok(iterations_ := Iterations.removeInterest(iterations_, question.iterations.current, caller));
    });
  };

  public type OpinionError = {
    #InvalidOpinion;
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public shared query func getOpinion(question_id: Nat, principal: Principal) : async Result<?Cursor, OpinionError> {
    Result.mapOk<Question, ?Cursor, OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
      Iterations.getOpinion(iterations_, question.iterations.current, principal);
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, cursor: Cursor) : async Result<(), OpinionError> {
    Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(cursor) {
      Result.chain<Question, (), OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        if (Iterations.get(iterations_, question.iterations.current).voting_stage != #OPINION) { return #err(#InvalidVotingStage); };
        #ok(iterations_ := Iterations.putOpinion(iterations_, question.iterations.current, caller, cursor));
      })
    });
  };

  public type CategorizationError = {
    #InvalidVotingStage;
    #InsufficientCredentials;
    #InvalidCategorization;
    #QuestionNotFound;
  };

  public shared({caller}) func setCategorization(question_id: Nat, cursor_array: CategoryCursorArray) : async Result<(), CategorizationError> {
    Result.chain<(), (), CategorizationError>(verifyCredentials(caller), func () {
      Result.chain<Question, (), CategorizationError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        if (Iterations.get(iterations_, question.iterations.current).voting_stage != #CATEGORIZATION) { return #err(#InvalidVotingStage); };
        // @todo
        //Result.chain<Question, (), CategorizationError>(verify_result, func(question) {
          //let verified = Result.fromOption(old_categorizations_.verifyBallot(Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal)), #InvalidCategorization);
          //Result.mapOk<CategoryCursorTrie, (), CategorizationError>(verified, func(cursor_trie: CategoryCursorTrie) {
        #ok(iterations_ := Iterations.putCategorization(iterations_, question.iterations.current, caller, Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal)));
          //})
        //})
      })
    });
  };

  public shared func run() {
    let time_now = Time.now();
    iterations_ := scheduler_.selectQuestion(iterations_, time_now).0;
    iterations_ := scheduler_.archiveQuestion(iterations_, time_now).0;
    let (iterations, iteration) = scheduler_.closeCategorization(iterations_, time_now);
    iterations_ := iterations;
    Option.iterate(iteration, func(it: Iteration) {
      users_.updateConvictions(questions_.getQuestion(it.question_id), iterations_);
    });
  };

  public type GetUserError = {
    #IsAnonymous;
  };

  public shared func findUser(principal: Principal) : async Result<User, GetUserError> {
    Result.fromOption(users_.findUser(principal), #IsAnonymous);
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
    scheduler_shareable_ := scheduler_.share();
  };

  system func postupgrade(){
    categories_ := Categories.Categories(categories_shareable_);
    users_ := Users.Users(users_shareable_, categories_);
    questions_ := Questions.Questions(questions_shareable_);
    scheduler_ := Scheduler.Scheduler(scheduler_shareable_);
  };

};
