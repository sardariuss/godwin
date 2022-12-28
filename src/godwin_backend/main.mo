import Question "questions/question";
import Questions "questions/questions";
import Queries "questions/queries";
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
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

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
  type Iteration = Types.Iteration;

  /// Members
  stable var categories_ = Categories.fromArray(parameters.categories);
  stable var convictions_decay_ = parameters.convictions_decay;
  stable var users_ = Users.empty();
  stable var questions_ = Questions.empty();
  // The compiler requires this function to be defined before its passed to the scheduler 
  func onClosingQuestion(question: Question) {
    users_ := Users.updateConvictions(users_, Question.unwrapIteration(question), question.vote_history, convictions_decay_);
  };
  var scheduler_ = Scheduler.Scheduler({ params = parameters.scheduler; last_selection_date = Time.now(); }, onClosingQuestion);

  /// For upgrades
  stable var scheduler_shareable_ = scheduler_.share();

  public query func getSchedulerParams() : async SchedulerParams {
    scheduler_.share().params;
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
        users_ := Users.addCategory(users_, category);
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
        users_ := Users.removeCategory(users_, category);
        #ok;
      };
    });
  };

  public type SetSchedulerParamsError = {
    #InsufficientCredentials;
  };

  public shared({caller}) func setSchedulerParams(scheduler_params : SchedulerParams) : async Result<(), SetSchedulerParamsError> {
    Result.mapOk<(), (), VerifyCredentialsError>(verifyCredentials(caller), func () {
      scheduler_.setParams(scheduler_params);
    });
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public query func getQuestion(question_id: Nat32) : async Result<Question, GetQuestionError> {
    Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound);
  };

  public query func getQuestions(order_by: Queries.OrderBy, direction: Queries.QueryDirection, limit: Nat) : async [Question] {
    let query_result = Questions.queryQuestions(questions_, order_by, direction, limit);
    let buffer = Buffer.Buffer<Question>(query_result.ids.size());
    for (question_id in Array.vals(query_result.ids)){
      buffer.add(Questions.getQuestion(questions_, question_id));
    };
    buffer.toArray();
  };

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
  };

  public shared({caller}) func openQuestion(title: Text, text: Text) : async Result<Question, OpenQuestionError> {
    Result.mapOk<User, Question, OpenQuestionError>(getUser(caller), func(_) {
      let (questions, question) = Questions.createQuestion(questions_, caller, Time.now(), title, text);
      questions_ := questions;
      question;
    });
  };

  public shared({caller}) func reopenQuestion(question_id: Nat32) : async Result<(), InterestError> {
    Result.chain<User, (), InterestError>(getUser(caller), func(_) {
      Result.chain<Question, (), InterestError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
        Result.mapOk<Question, (), InterestError>(Question.reopenQuestion(question), func(question) {
          questions_ := Questions.replaceQuestion(questions_, question);
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
      Result.chain<Question, (), InterestError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
        Result.mapOk<Question, (), InterestError>(Question.putInterest(question, caller, interest), func(question) {
          questions_ := Questions.replaceQuestion(questions_, question);
        });
      })
    });
  };

  public shared({caller}) func removeInterest(question_id: Nat32) : async Result<(), InterestError> {
    Result.chain<User, (), InterestError>(getUser(caller), func(_) {
      Result.chain<Question, (), InterestError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
        Result.mapOk<Question, (), InterestError>(Question.removeInterest(question, caller), func(question) {
          questions_ := Questions.replaceQuestion(questions_, question);
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
        Result.chain<Question, (), OpinionError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
          Result.mapOk<Question, (), OpinionError>(Question.putOpinion(question, caller, cursor), func(question) {
            questions_ := Questions.replaceQuestion(questions_, question);
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
      Result.chain<Question, (), CategorizationError>(Result.fromOption(Questions.findQuestion(questions_, question_id), #QuestionNotFound), func(question) {
        let cursor_trie = Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal);
        Result.mapOk<Question, (), CategorizationError>(Question.putCategorization(question, caller, cursor_trie), func(question) {
          questions_ := Questions.replaceQuestion(questions_, question);
        });
      })
    });
  };

  public shared func run() {
    let time_now = Time.now();
    questions_ := scheduler_.openOpinionVote(questions_, time_now).0;
    questions_ := scheduler_.openCategorizationVote(questions_, time_now, Categories.toArray(categories_)).0;
    questions_ := scheduler_.closeQuestion(questions_, time_now).0;
    questions_ := scheduler_.rejectQuestions(questions_, time_now).0;
    questions_ := scheduler_.deleteQuestions(questions_, time_now).0;
  };

  public shared func findUser(principal: Principal) : async ?User {
    Users.findUser(users_, principal);
  };

  type SetUserNameError = {
    #PrincipalIsAnonymous;
  };

  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    Result.mapOk<User, (), SetUserNameError>(getUser(caller), func(_) {
      users_ := Users.setUserName(users_, caller, name);
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
      let (users, user) = Users.getOrCreateUser(users_, principal, Categories.toArray(categories_));
      users_ := users;
      #ok(user);
    };
  };

  system func preupgrade(){
    scheduler_shareable_ := scheduler_.share();
  };

  system func postupgrade(){
    scheduler_ := Scheduler.Scheduler(scheduler_shareable_, onClosingQuestion);
  };

};
