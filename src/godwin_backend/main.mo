import Types "model/Types";
import QuestionQueries "model/QuestionQueries"; // @todo
import State "model/State";
import Factory "model/Factory";
import Scenario "../../test/motoko/Scenario"; // @todo

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

shared({ caller }) actor class Godwin(parameters: Types.Parameters) = {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Time.Time;

  // For convenience: from types module
  type Question = Types.Question;
  type User = Types.User;
  type Category = Types.Category;
  type Decay = Types.Decay;
  type Duration = Types.Duration;
  type Status = Types.Status;
  type PolarizationArray = Types.PolarizationArray;
  type Poll = Types.Poll;
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type GetQuestionError = Types.GetQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type ReopenQuestionError = Types.ReopenQuestionError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type GetUserError = Types.GetUserError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type GetUserConvictionsError = Types.GetUserConvictionsError;
  type GetAggregateError = Types.GetAggregateError;
  type GetBallotError = Types.GetBallotError;
  type RevealBallotError = Types.RevealBallotError;
  type PutBallotError = Types.PutBallotError;
  type PutFreshBallotError = Types.PutFreshBallotError;
  type Ballot<T> = Types.Ballot<T>;
  type Interest = Types.Interest;
  type Appeal = Types.Appeal;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type CursorArray = Types.CursorArray;
  type GetUserVotesError = Types.GetUserVotesError;

  //stable var state_ = State.initState(caller, Time.now(), parameters);

  //let game_ = Factory.build(state_);

  let game_ = Scenario.run(Time.now(), #HOURS(6), #MINUTES(5), 20);

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

  public query func getInterestPickRate() : async Duration {
    game_.getInterestPickRate();
  };

  public shared({caller}) func setInterestPickRate(rate: Duration) : async Result<(), SetPickRateError> {
    game_.setInterestPickRate(caller, rate);
  };

  public query func getStatusDuration(status: Status) : async Duration {
    game_.getStatusDuration(status);
  };

  public shared({caller}) func setStatusDuration(status: Status, duration: Duration) : async Result<(), SetDurationError> {
    game_.setStatusDuration(caller, status, duration);
  };

  public query func searchQuestions(text: Text, limit: Nat) : async [Nat] {
    game_.searchQuestions(text, limit);
  };

  public query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    game_.getQuestion(question_id);
  };

  public query func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : async QuestionQueries.ScanLimitResult {
    game_.getQuestions(order_by, direction, limit, previous_id);
  };

  public shared({caller}) func openQuestion(title: Text, text: Text) : async Result<Question, OpenQuestionError> {
    game_.openQuestion(caller, title, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: Nat) : async Result<(), ReopenQuestionError> {
    game_.reopenQuestion(caller, question_id, Time.now());
  };

  public query func getInterestAggregate(question_id: Nat, iteration: Nat) : async Result<Appeal, GetAggregateError> {
    game_.getInterestAggregate(question_id, iteration);
  };

  public query({caller}) func getInterestBallot(principal: Principal, question_id: Nat, iteration: Nat) : async Result<?Ballot<Interest>, GetBallotError> {
    game_.getInterestBallot(caller, principal, question_id, iteration);
  };

  public shared({caller}) func putInterestBallot(question_id: Nat, interest: Interest) : async Result<(), PutFreshBallotError> {
    game_.putInterestBallot(caller, question_id, Time.now(), interest);
  };

  public query func getOpinionAggregate(question_id: Nat, iteration: Nat) : async Result<Polarization, GetAggregateError> {
    game_.getOpinionAggregate(question_id, iteration);
  };

  public query({caller}) func getOpinionBallot(principal: Principal, question_id: Nat, iteration: Nat) : async Result<?Ballot<Cursor>, GetBallotError> {
    game_.getOpinionBallot(caller, principal, question_id, iteration);
  };

  public shared({caller}) func putOpinionBallot(question_id: Nat, cursor: Cursor) : async Result<(), PutBallotError> {
    game_.putOpinionBallot(caller, question_id, Time.now(), cursor);
  };

  public query func getCategorizationAggregate(question_id: Nat, iteration: Nat) : async Result<PolarizationArray, GetAggregateError> {
    game_.getCategorizationAggregate(question_id, iteration);
  };

  public query({caller}) func getCategorizationBallot(principal: Principal, question_id: Nat, iteration: Nat) : async Result<?Ballot<CursorArray>, GetBallotError> {
    game_.getCategorizationBallot(caller, principal, question_id, iteration);
  };

  public shared({caller}) func putCategorizationBallot(question_id: Nat, answer: CursorArray) : async Result<(), PutFreshBallotError> {
    game_.putCategorizationBallot(caller, question_id, Time.now(), answer);
  };

  public shared func run() {
    game_.run(Time.now());
  };

  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    game_.setUserName(caller, name);
  };

  public query func getUserConvictions(principal: Principal) : async Result<Types.PolarizationArray, GetUserConvictionsError> {
    game_.getUserConvictions(principal);
  };

  public query func getUserVotes(principal: Principal) : async Result<[(Nat, Nat)], GetUserVotesError> {
    game_.getUserVotes(principal);
  };

  // @todo
//  public shared({caller}) func createQuestions(inputs: [(Text, CreateStatus)]) : async Result<[Question], CreateQuestionError> {
//    game_.createQuestions(caller, inputs);
//  };

};
