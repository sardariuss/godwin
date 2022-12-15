import Question "questions/question";
import Questions "questions/questions";
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
import Option "mo:base/Option";

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

  // Members
  stable var categories_ = Categories.fromArray(parameters.categories);
  stable var users_ = Users.empty();
  stable var questions_ = Questions.empty();
  var scheduler_ = Scheduler.Scheduler({ params = parameters.scheduler; last_selection_date = Time.now(); });

  // For upgrades
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
    Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound);
  };

  public shared({caller}) func openQuestion(title: Text, text: Text) : async Question {
    let (questions, question) = Questions.createQuestion(questions_, caller, Time.now(), title, text);
    questions_ := questions;
    question;
  };

  public shared({caller}) func reopenQuestion(question_id: Nat) : async Result<(), InterestError> {
    Result.chain<Question, (), InterestError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
      Result.mapOk<Question, (), InterestError>(Question.reopenQuestion(question), func(question) {
        questions_ := Questions.replaceQuestion(questions_, question);
      });
    });
  };

  public type InterestError = {
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public shared({caller}) func setInterest(question_id: Nat, interest: Interest) : async Result<(), InterestError> {
    Result.chain<Question, (), InterestError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
      Result.mapOk<Question, (), InterestError>(Question.putInterest(question, caller, interest), func(question) {
        questions_ := Questions.replaceQuestion(questions_, question);
      });
    });
  };

  public shared({caller}) func removeInterest(question_id: Nat) : async Result<(), InterestError> {
    Result.chain<Question, (), InterestError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
      Result.mapOk<Question, (), InterestError>(Question.removeInterest(question, caller), func(question) {
        questions_ := Questions.replaceQuestion(questions_, question);
      });
    });
  };

  public type OpinionError = {
    #InvalidOpinion;
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public shared({caller}) func setOpinion(question_id: Nat, cursor: Cursor) : async Result<(), OpinionError> {
    Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(cursor) {
      Result.chain<Question, (), OpinionError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
        Result.mapOk<Question, (), OpinionError>(Question.putOpinion(question, caller, cursor), func(question) {
          questions_ := Questions.replaceQuestion(questions_, question);
        });
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
      Result.chain<Question, (), CategorizationError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
        let cursor_trie = Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal);
        if (not CategoryCursorTrie.isValid(cursor_trie, categories_)) { return #err(#InvalidCategorization); };
        Result.mapOk<Question, (), CategorizationError>(Question.putCategorization(question, caller, cursor_trie), func(question) {
          questions_ := Questions.replaceQuestion(questions_, question);
        });
      })
    });
  };

  public shared func run() {
    let time_now = Time.now();
    questions_ := scheduler_.rejectQuestions(questions_, time_now).0;
    questions_ := scheduler_.openOpinionVote(questions_, time_now).0;
    questions_ := scheduler_.openCategorizationVote(questions_, time_now).0;
    let (questions, users, _) = scheduler_.closeQuestion(questions_, time_now, users_, Categories.toArray(categories_));
    questions_ := questions;
    users_ := users;
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
    scheduler_shareable_ := scheduler_.share();
  };

  system func postupgrade(){
    scheduler_ := Scheduler.Scheduler(scheduler_shareable_);
  };

};
