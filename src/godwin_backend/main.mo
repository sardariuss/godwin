import Types "model/Types";
import QuestionQueries "model/QuestionQueries"; // @todo
import State "model/State";
import Factory "model/Factory";
import Controller "model/controller/Controller";
//import Scenario "../../test/motoko/Scenario"; // @todo
import Duration "utils/Duration";
import StatusManager "model/StatusManager";

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
  type PrincipalError = Types.PrincipalError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type GetUserConvictionsError = Types.GetUserConvictionsError;
  type GetAggregateError = Types.GetAggregateError;
  type GetBallotError = Types.GetBallotError;
  type PutBallotError = Types.PutBallotError;
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
  type StatusInfo2 = Types.StatusInfo2;
  type GetVoteError = Types.GetVoteError;

  stable var state_ = State.initState(caller, Time.now(), parameters);

  let controller_ = Factory.build(state_);

  //let controller_ = Scenario.run(Time.now(), #HOURS(6), #MINUTES(5), 20);

  public query func getDecay() : async ?Decay {
    controller_.getDecay();
  };

  public query func getCategories() : async CategoryArray {
    controller_.getCategories();
  };

  public shared({caller}) func addCategory(category: Category, info: CategoryInfo) : async Result<(), AddCategoryError> {
    controller_.addCategory(caller, category, info);
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    controller_.removeCategory(caller, category);
  };

  public query func getInterestPickRate() : async Duration {
    controller_.getInterestPickRate();
  };

  public shared({caller}) func setInterestPickRate(rate: Duration) : async Result<(), SetPickRateError> {
    controller_.setInterestPickRate(caller, rate);
  };

  public query func getStatusDuration(status: Status) : async Duration {
    controller_.getStatusDuration(status);
  };

  public shared({caller}) func setStatusDuration(status: Status, duration: Duration) : async Result<(), SetDurationError> {
    controller_.setStatusDuration(caller, status, duration);
  };

  public query func searchQuestions(text: Text, limit: Nat) : async [Nat] {
    controller_.searchQuestions(text, limit);
  };

  public query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    controller_.getQuestion(question_id);
  };

  public query func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : async QuestionQueries.ScanLimitResult {
    controller_.getQuestions(order_by, direction, limit, previous_id);
  };

  public shared({caller}) func openQuestion(text: Text) : async Result<Question, OpenQuestionError> {
    await controller_.openQuestion(caller, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: Nat) : async Result<(), ReopenQuestionError> {
    await controller_.reopenQuestion(caller, question_id, Time.now());
  };

  public query({caller}) func getInterestBallot(question_id: Nat) : async Result<Ballot<Interest>, GetBallotError> {
    controller_.getInterestBallot(caller, question_id);
  };

  public shared({caller}) func putInterestBallot(question_id: Nat, interest: Interest) : async Result<(), PutBallotError> {
    await controller_.putInterestBallot(caller, question_id, Time.now(), interest);
  };

  public query({caller}) func getOpinionBallot(question_id: Nat) : async Result<Ballot<Cursor>, GetBallotError> {
    controller_.getOpinionBallot(caller, question_id);
  };

  public shared({caller}) func putOpinionBallot(question_id: Nat, cursor: Cursor) : async Result<(), PutBallotError> {
    controller_.putOpinionBallot(caller, question_id, Time.now(), cursor);
  };

  public query({caller}) func getCategorizationBallot(question_id: Nat) : async Result<Ballot<CursorArray>, GetBallotError> {
    controller_.getCategorizationBallot(caller, question_id);
  };

  public shared({caller}) func putCategorizationBallot(question_id: Nat, answer: CursorArray) : async Result<(), PutBallotError> {
    await controller_.putCategorizationBallot(caller, question_id, Time.now(), answer);
  };

  public query func getStatusHistory(question_id: Nat) : async ?[(Status, [Time])] {
    controller_.getStatusHistory(question_id);
  };

  public query func getInterestVote(question_id: Nat, iteration: Nat) : async Result<PublicVote<Interest, Appeal>, GetVoteError>{
    controller_.getInterestVote(question_id, iteration);
  };

  public query func getOpinionVote(question_id: Nat, iteration: Nat) : async Result<PublicVote<Cursor, Polarization>, GetVoteError>{
    controller_.getOpinionVote(question_id, iteration);
  };

  public query func getCategorizationVote(question_id: Nat, iteration: Nat) : async Result<PublicVote<CursorArray, PolarizationArray>, GetVoteError>{
    controller_.getCategorizationVote(question_id, iteration);
  };

  public query func getUserConvictions(principal: Principal) : async ?PolarizationArray {
    controller_.getUserConvictions(principal);
  };

  public query func getUserVotes(principal: Principal) : async ?[VoteId] {
    controller_.getUserVotes(principal);
  };

  public shared func run() {
    controller_.run(Time.now());
  };

};
