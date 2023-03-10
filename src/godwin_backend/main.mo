import Types "model/Types";
import QuestionQueries "model/QuestionQueries"; // @todo
import State "model/State";
import Factory "model/Factory";
import Scenario "../../test/motoko/Scenario"; // @todo
import Duration "utils/Duration";

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
  type Category = Types.Category;
  type Decay = Types.Decay;
  type Duration = Duration.Duration;
  type Status = Types.Status;
  type PolarizationArray = Types.PolarizationArray;
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
  type PublicVote<T, A> = Types.PublicVote<T, A>;
  type Interest = Types.Interest;
  type Appeal = Types.Appeal;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type CursorArray = Types.CursorArray;
  type GetUserVotesError = Types.GetUserVotesError;
  type CategoryInfo = Types.CategoryInfo;
  type CategoryArray = Types.CategoryArray;
  type UserHistory = Types.UserHistory;
  type VoteId = Types.VoteId;

  //stable var state_ = State.initState(caller, Time.now(), parameters);

  //let game_ = Factory.build(state_);

  let game_ = Scenario.run(Time.now(), #HOURS(6), #MINUTES(5), 20);

  public query func getDecay() : async ?Decay {
    game_.getDecay();
  };

  public query func getCategories() : async CategoryArray {
    game_.getCategories();
  };

  public shared({caller}) func addCategory(category: Category, info: CategoryInfo) : async Result<(), AddCategoryError> {
    game_.addCategory(caller, category, info);
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

  public shared({caller}) func openQuestion(text: Text) : async Result<Question, OpenQuestionError> {
    await game_.openQuestion(getMaster(), caller, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: Nat) : async Result<(), ReopenQuestionError> {
    await game_.reopenQuestion(getMaster(), caller, question_id, Time.now());
  };

  public query({caller}) func getInterestBallot(question_id: Nat) : async Result<?Ballot<Interest>, GetBallotError> {
    game_.getInterestBallot(caller, question_id);
  };

  public shared({caller}) func putInterestBallot(question_id: Nat, interest: Interest) : async Result<(), PutFreshBallotError> {
    game_.putInterestBallot(caller, question_id, Time.now(), interest);
  };

  public query({caller}) func getOpinionBallot(question_id: Nat) : async Result<?Ballot<Cursor>, GetBallotError> {
    game_.getOpinionBallot(caller, question_id);
  };

  public shared({caller}) func putOpinionBallot(question_id: Nat, cursor: Cursor) : async Result<(), PutBallotError> {
    game_.putOpinionBallot(caller, question_id, Time.now(), cursor);
  };

  public query({caller}) func getCategorizationBallot(question_id: Nat) : async Result<?Ballot<CursorArray>, GetBallotError> {
    game_.getCategorizationBallot(caller, question_id);
  };

  public shared({caller}) func putCategorizationBallot(question_id: Nat, answer: CursorArray) : async Result<(), PutFreshBallotError> {
    game_.putCategorizationBallot(caller, question_id, Time.now(), answer);
  };

  public query func getStatusHistory(question_id: Nat) : async ?[(Status, [Time])] {
    game_.getStatusHistory(question_id);
  };

  public query func getInterestVote(question_id: Nat, iteration: Nat) : async ?PublicVote<Interest, Appeal> {
    game_.getInterestVote(question_id, iteration);
  };

  public query func getOpinionVote(question_id: Nat, iteration: Nat) : async ?PublicVote<Cursor, Polarization> {
    game_.getOpinionVote(question_id, iteration);
  };

  public query func getCategorizationVote(question_id: Nat, iteration: Nat) : async ?PublicVote<CursorArray, PolarizationArray> {
    game_.getCategorizationVote(question_id, iteration);
  };

  public query func getUserConvictions(principal: Principal) : async ?PolarizationArray {
    game_.getUserConvictions(principal);
  };

  public query func getUserVotes(principal: Principal) : async ?[VoteId] {
    game_.getUserVotes(principal);
  };

  public shared func run() {
    game_.run(Time.now());
  };

  func getMaster() : Types.Master {
    actor(Principal.toText(parameters.master)); // @todo: store the master principal as member ?
  };

};
