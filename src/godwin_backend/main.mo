import Question "questions/question";
import Questions "questions/questions";
import Iterations "votes/register";
import CategoryCursorTrie "representation/categoryCursorTrie";
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

// @todo: one need to call getOrCreateUser when voting or doing anything that takes the caller as input
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
  stable var categories_ = Categories.fromArray(parameters.categories);
  stable var users_ = Users.empty();
  var questions_ = Questions.empty();
  stable var iterations_ = Iterations.empty();
  var scheduler_ = Scheduler.Scheduler({ params = parameters.scheduler; last_selection_date = Time.now(); });

  // For upgrades
  stable var questions_shareable_ = questions_.share();
  stable var scheduler_shareable_ = scheduler_.share();

  public func getSchedulerParams() : async SchedulerParams {
    scheduler_.share().params;
  };

  public func getCategories() : async [Category] {
    Categories.toArray(categories_);
  };

  public type AddCategoryError = {
    #InsufficientCredentials;
    #CategoryAlreadyExists;
  };

  public shared({caller}) func addCategory(category: Category) : async Result<(), AddCategoryError> {
    Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func () {
      if (Categories.contains(categories_, category)) { #err(#CategoryAlreadyExists); }
      else { #ok(categories_ := Categories.add(categories_, category)); };
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
        users_ := Users.removeCategory(users_, category);
        #ok;
      };
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
        let cursor_trie = Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal);
        if (not CategoryCursorTrie.isValid(cursor_trie, categories_)) { return #err(#InvalidCategorization); };
        #ok(iterations_ := Iterations.putCategorization(iterations_, question.iterations.current, caller, Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal)));
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
      users_ := Users.updateConvictions(users_, questions_.getQuestion(it.question_id), Categories.toArray(categories_), iterations_);
    });
  };

  public type GetUserError = {
    #IsAnonymous;
  };

  public shared func findUser(principal: Principal) : async Result<User, GetUserError> {
    // @todo: do case if anonymous
    let (users, user) = Users.getOrCreateUser(users_, principal, Categories.toArray(categories_));
    users_ := users;
    #ok(user);
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials(caller: Principal) : Result<(), VerifyCredentialsError> {
    if (caller != admin_) { #err(#InsufficientCredentials); }
    else { #ok; };
  };

  system func preupgrade(){
    questions_shareable_ := questions_.share();
    scheduler_shareable_ := scheduler_.share();
  };

  system func postupgrade(){
    questions_ := Questions.Questions(questions_shareable_);
    scheduler_ := Scheduler.Scheduler(scheduler_shareable_);
  };

};
