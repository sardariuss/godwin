import Types "types";
import Game "game";
import Queries "questions/queries"; // @todo

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

shared({ caller }) actor class Godwin(parameters: Types.Parameters) = {

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
  type CreateQuestionStatus = Types.CreateQuestionStatus;
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

  stable var game_register_ = Game.initRegister(caller, parameters, Time.now());

  let game_ = Game.Game(game_register_);

  public query func getDecayParams() : async ?DecayParams {
    game_.getDecayParams();
  };

  public query func getCategories() : async [Category] {
    game_.getCategories();
  };

  public shared({caller}) func addCategory(category: Category) : async Result<(), AddCategoryError> {
    game_.addCategory(caller, category);
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    game_.removeCategory(caller, category);
  };

  public query func getSchedulerParams() : async SchedulerParams {
    game_.getSchedulerParams();
  };

  public shared({caller}) func setSchedulerParam(status: Status, duration: Duration) : async Result<(), SetSchedulerParamError> {
    game_.setSchedulerParam(caller, status, duration);
  };

  public query func getQuestion(question_id: Nat32) : async Result<Question, GetQuestionError> {
    game_.getQuestion(question_id);
  };

  public query func getQuestions(order_by: Queries.OrderBy, direction: Queries.QueryDirection, limit: Nat, previous_id: ?Nat32) : async Queries.QueryQuestionsResult {
    game_.getQuestions(order_by, direction, limit, previous_id);
  };

  public shared({caller}) func createQuestions(inputs: [(Text, CreateQuestionStatus)]) : async Result<[Question], CreateQuestionError> {
    game_.createQuestions(caller, inputs);
  };

  public shared({caller}) func openQuestion(title: Text, text: Text) : async Result<Question, OpenQuestionError> {
    game_.openQuestion(caller, title, text);
  };

  public shared({caller}) func reopenQuestion(question_id: Nat32) : async Result<(), InterestError> {
    game_.reopenQuestion(caller, question_id);
  };

  public shared({caller}) func setInterest(question_id: Nat32, interest: Interest) : async Result<(), InterestError> {
    game_.setInterest(caller, question_id, interest);
  };

  public shared({caller}) func removeInterest(question_id: Nat32) : async Result<(), InterestError> {
    game_.removeInterest(caller, question_id);
  };

  public shared({caller}) func setOpinion(question_id: Nat32, cursor: Cursor) : async Result<(), OpinionError> {
    game_.setOpinion(caller, question_id, cursor);
  };

  public shared({caller}) func setCategorization(question_id: Nat32, cursor_array: CategoryCursorArray) : async Result<(), CategorizationError> {
    game_.setCategorization(caller, question_id, cursor_array);
  };

  public shared func run() {
    game_.run();
  };

  public query func findUser(principal: Principal) : async ?User {
    game_.findUser(principal);
  };

  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    game_.setUserName(caller, name);
  };

  public query func polarizationTrieToArray(trie: Types.CategoryPolarizationTrie) : async Types.CategoryPolarizationArray {
    game_.polarizationTrieToArray(trie);
  };

};
