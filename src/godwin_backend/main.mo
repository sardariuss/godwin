import Types "model/Types";
import QuestionQueries "model/questions/QuestionQueries"; // @todo
import State "model/State";
import Factory "model/Factory";
import Controller "model/controller/Controller";
import Scenario "../../test/motoko/Scenario"; // @todo
import Duration "utils/Duration";
import StatusManager "model/questions/StatusManager";

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
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type PrincipalError = Types.PrincipalError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type GetUserConvictionsError = Types.GetUserConvictionsError;
  type GetBallotError = Types.GetBallotError;
  type PutBallotError = Types.PutBallotError;
  type InterestBallot = Types.InterestBallot;
  type OpinionBallot = Types.OpinionBallot;
  type CategorizationBallot = Types.CategorizationBallot;
  type PublicVote<T, A> = Types.PublicVote<T, A>;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type CursorArray = Types.CursorArray;
  type GetUserVotesError = Types.GetUserVotesError;
  type CategoryInfo = Types.CategoryInfo;
  type CategoryArray = Types.CategoryArray;
  type RevealVoteError = Types.RevealVoteError;
  type StatusInfo = Types.StatusInfo;
  type TransitionError = Types.TransitionError;
  type QuestionId = Types.QuestionId;

  let _start_date = Time.now() - Duration.toTime(#HOURS(6));  // @temp

  stable var _state = State.initState(caller, _start_date, parameters);

  let _controller = Factory.build(_state);

  public shared func runScenario() : async () {
    await* Scenario.run(_controller, _start_date, Time.now(), #MINUTES(5));
  };

  public query func getName() : async Text {
    _controller.getName();
  };

  public query func getDecay() : async ?Decay {
    _controller.getDecay();
  };

  public query func getCategories() : async CategoryArray {
    _controller.getCategories();
  };

  public shared({caller}) func addCategory(category: Category, info: CategoryInfo) : async Result<(), AddCategoryError> {
    _controller.addCategory(caller, category, info);
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    _controller.removeCategory(caller, category);
  };

  public query func getInterestPickRate() : async Duration {
    _controller.getInterestPickRate();
  };

  public shared({caller}) func setInterestPickRate(rate: Duration) : async Result<(), SetPickRateError> {
    _controller.setInterestPickRate(caller, rate);
  };

  public query func getStatusDuration(status: Status) : async Duration {
    _controller.getStatusDuration(status);
  };

  public shared({caller}) func setStatusDuration(status: Status, duration: Duration) : async Result<(), SetDurationError> {
    _controller.setStatusDuration(caller, status, duration);
  };

  public query func searchQuestions(text: Text, limit: Nat) : async [Nat] {
    _controller.searchQuestions(text, limit);
  };

  public query func getQuestion(question_id: QuestionId) : async Result<Question, GetQuestionError> {
    _controller.getQuestion(question_id);
  };

  public query func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : async QuestionQueries.ScanLimitResult {
    _controller.getQuestions(order_by, direction, limit, previous_id);
  };

  public shared({caller}) func openQuestion(text: Text) : async Result<Question, OpenQuestionError> {
    await* _controller.openQuestion(caller, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: QuestionId) : async Result<(), [(?Status, TransitionError)]> {
    await* _controller.reopenQuestion(caller, question_id, Time.now());
  };

  public query({caller}) func getInterestBallot(question_id: QuestionId) : async Result<InterestBallot, GetBallotError> {
    _controller.getInterestBallot(caller, question_id);
  };

  public shared({caller}) func putInterestBallot(question_id: QuestionId, interest: Cursor) : async Result<InterestBallot, PutBallotError> {
    await* _controller.putInterestBallot(caller, question_id, Time.now(), interest);
  };

  public query({caller}) func getOpinionBallot(question_id: QuestionId) : async Result<OpinionBallot, GetBallotError> {
    _controller.getOpinionBallot(caller, question_id);
  };

  public shared({caller}) func putOpinionBallot(question_id: QuestionId, cursor: Cursor) : async Result<OpinionBallot, PutBallotError> {
    _controller.putOpinionBallot(caller, question_id, Time.now(), cursor);
  };

  public query({caller}) func getCategorizationBallot(question_id: QuestionId) : async Result<CategorizationBallot, GetBallotError> {
    _controller.getCategorizationBallot(caller, question_id);
  };

  public shared({caller}) func putCategorizationBallot(question_id: QuestionId, answer: CursorArray) : async Result<CategorizationBallot, PutBallotError> {
    await* _controller.putCategorizationBallot(caller, question_id, Time.now(), answer);
  };

  public query func getStatusInfo(question_id: QuestionId) : async Result<StatusInfo, ReopenQuestionError> {
    _controller.getStatusInfo(question_id);
  };

  public query func getStatusHistory(question_id: QuestionId) : async Result<[(Status, [Time])], ReopenQuestionError> {
    _controller.getStatusHistory(question_id);
  };

  public query func revealInterestVote(question_id: QuestionId, iteration: Nat) : async Result<PublicVote<Cursor, Polarization>, RevealVoteError>{
    _controller.revealInterestVote(question_id, iteration);
  };

  public query func revealOpinionVote(question_id: QuestionId, iteration: Nat) : async Result<PublicVote<Cursor, Polarization>, RevealVoteError>{
    _controller.revealOpinionVote(question_id, iteration);
  };

  public query func revealCategorizationVote(question_id: QuestionId, iteration: Nat) : async Result<PublicVote<CursorArray, PolarizationArray>, RevealVoteError>{
    _controller.revealCategorizationVote(question_id, iteration);
  };

  public query func getUserConvictions(principal: Principal) : async ?PolarizationArray {
    _controller.getUserConvictions(principal);
  };

  public query func getUserOpinions(principal: Principal) : async ?[(Nat, PolarizationArray, OpinionBallot)] {
    _controller.getUserOpinions(principal);
  };

  public shared func run() : async() {
    await* _controller.run(Time.now());
  };

};
