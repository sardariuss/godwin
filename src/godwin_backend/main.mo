import Types "model/Types";
import QuestionQueries "model/QuestionQueries"; // @todo
import State "model/State";
import Factory "model/Factory";

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
  type Status = Types.Status;
  type PolarizationArray = Types.PolarizationArray;
  type Poll = Types.Poll;
  type TypedAnswer = Types.TypedAnswer;
  type TypedAggregate = Types.TypedAggregate;
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type GetQuestionError = Types.GetQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type ReopenQuestionError = Types.ReopenQuestionError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type GetUserError = Types.GetUserError;
  type TypedBallot = Types.TypedBallot;
  type PutBallotError = Types.PutBallotError;
  type GetBallotError = Types.GetBallotError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type GetUserConvictionsError = Types.GetUserConvictionsError;

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

  public query func getPickRate() : async Duration {
    game_.getPickRate();
  };

  public shared({caller}) func setPickRate(rate: Duration) : async Result<(), SetPickRateError> {
    game_.setPickRate(caller, rate);
  };

  public query func getDuration(status: Status) : async Duration {
    game_.getDuration(status);
  };

  public shared({caller}) func setDuration(status: Status, duration: Duration) : async Result<(), SetDurationError> {
    game_.setDuration(caller, status, duration);
  };

  public query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    game_.getQuestion(question_id);
  };

  public query func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : async QuestionQueries.QueryQuestionsResult {
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

  public shared({caller}) func revealBallot(question_id: Nat) : async Result<TypedBallot, GetBallotError> {
    game_.revealBallot(caller, question_id, Time.now());
  };

  public query func getBallot(principal: Principal, question_id: Nat, iteration: Nat, poll: Poll) : async Result<?TypedBallot, GetBallotError> {
    game_.getBallot(principal, question_id, iteration, poll);
  };

  public query func getAggregate(question_id: Nat, iteration: Nat, poll: Poll) : async Result<TypedAggregate, GetBallotError> {
    game_.getAggregate(question_id, iteration, poll);
  };

  public shared func run() {
    game_.run(Time.now());
  };

  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    game_.setUserName(caller, name);
  };

  public shared({caller}) func getUserConvictions() : async Result<Types.PolarizationArray, GetUserConvictionsError> {
    game_.getUserConvictions(caller);
  };

  // @todo
//  public shared({caller}) func createQuestions(inputs: [(Text, CreateStatus)]) : async Result<[Question], CreateQuestionError> {
//    game_.createQuestions(caller, inputs);
//  };

};
