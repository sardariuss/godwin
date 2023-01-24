import Types "Types";
import QuestionQueries2 "QuestionQueries"; // @todo
import State "State";
import Factory "Factory";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

shared({ caller }) actor class Godwin(parameters: Types.Parameters) = {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;

  // For convenience: from types module
  type Question = Types.Question;
  type User = Types.User;
  type Category = Types.Category;
  type Decay = Types.Decay;
  type Duration = Types.Duration;
  type QuestionStatus = Types.QuestionStatus;
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type GetQuestionError = Types.GetQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type ReopenQuestionError = Types.ReopenQuestionError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type GetUserError = Types.GetUserError;
  type Ballot<T> = Types.Ballot<T>;
  type TypedBallot = Types.TypedBallot;
  type PutBallotError = Types.PutBallotError;
  type RemoveBallotError = Types.RemoveBallotError;
  type GetBallotError = Types.GetBallotError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type Poll = Types.Poll;
  type TypedAnswer = Types.TypedAnswer;

  stable var state_ = State.initState(caller, Time.now(), parameters);

  let game_ = Factory.build(state_);

  public query func getDecay() : async ?Decay {
    game_.getDecay();
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

  public query func getPickRate(status: QuestionStatus) : async Duration {
    game_.getPickRate(status);
  };

  public shared({caller}) func setPickRate(status: QuestionStatus, rate: Duration) : async Result<(), SetPickRateError> {
    game_.setPickRate(caller, status, rate);
  };

  public query func getDuration(status: QuestionStatus) : async Duration {
    game_.getDuration(status);
  };

  public shared({caller}) func setDuration(status: QuestionStatus, duration: Duration) : async Result<(), SetDurationError> {
    game_.setDuration(caller, status, duration);
  };

  public query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    game_.getQuestion(question_id);
  };

  public query func getQuestions(order_by: QuestionQueries2.OrderBy, direction: QuestionQueries2.Direction, limit: Nat, previous_id: ?Nat) : async QuestionQueries2.QueryQuestionsResult {
    game_.getQuestions(order_by, direction, limit, previous_id);
  };

  public shared({caller}) func openQuestion(title: Text, text: Text) : async Result<Question, OpenQuestionError> {
    game_.openQuestion(caller, title, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: Nat) : async Result<(), ReopenQuestionError> {
    game_.reopenQuestion(caller, question_id, Time.now());
  };

  public shared({caller}) func putBallot(question_id: Nat, answer: TypedAnswer) : async Result<(), PutBallotError> {
    game_.putBallot(caller, question_id, answer, Time.now());
  };

  public shared({caller}) func removeBallot(question_id: Nat, vote: Poll) : async Result<(), RemoveBallotError> {
    game_.removeBallot(caller, question_id, vote);
  };

  public shared({caller}) func getBallot(question_id: Nat, iteration: Nat, vote: Poll) : async Result<?TypedBallot, GetBallotError> {
    game_.getBallot(caller, question_id, iteration, vote);
  };

  public shared func getUserBallot(principal: Principal, question_id: Nat, iteration: Nat, vote: Poll) : async Result<?TypedBallot, GetBallotError> {
    game_.getUserBallot(principal, question_id, iteration, vote);
  };

  public shared func run() {
    game_.run(Time.now());
  };

  public query func findUser(principal: Principal) : async ?User {
    game_.findUser(principal);
  };

  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    game_.setUserName(caller, name);
  };

  public query func polarizationTrieToArray(trie: Types.PolarizationMap) : async Types.PolarizationArray {
    game_.polarizationTrieToArray(trie);
  };

  // @todo
//  public shared({caller}) func createQuestions(inputs: [(Text, CreateQuestionStatus)]) : async Result<[Question], CreateQuestionError> {
//    game_.createQuestions(caller, inputs);
//  };

};
