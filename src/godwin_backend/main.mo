import Types           "model/Types";
import QuestionQueries "model/questions/QuestionQueries"; // @todo
import State           "model/State";
import Factory         "model/Factory";
import Facade          "model/Facade";
import StatusManager   "model/questions/StatusManager";

import Duration        "utils/Duration";

import Scenario        "../../test/motoko/Scenario"; // @todo

import Result          "mo:base/Result";
import Principal       "mo:base/Principal";
import Time            "mo:base/Time";

shared({ caller }) actor class Godwin(parameters: Types.Parameters) = {

  // For convenience: from base module
  type Result<Ok, Err>            = Result.Result<Ok, Err>;
  type Principal                  = Principal.Principal;
  type Time                       = Time.Time;

  // For convenience: from types module
  type Question                   = Types.Question;
  type Category                   = Types.Category;
  type Decay                      = Types.Decay;
  type Duration                   = Duration.Duration;
  type Status                     = Types.Status;
  type StatusHistory              = Types.StatusHistory;
  type PolarizationArray          = Types.PolarizationArray;
  type AddCategoryError           = Types.AddCategoryError;
  type RemoveCategoryError        = Types.RemoveCategoryError;
  type GetQuestionError           = Types.GetQuestionError;
  type OpenQuestionError          = Types.OpenQuestionError;
  type ReopenQuestionError        = Types.ReopenQuestionError;
  type VerifyCredentialsError     = Types.VerifyCredentialsError;
  type PrincipalError             = Types.PrincipalError;
  type SetPickRateError           = Types.SetPickRateError;
  type SetDurationError           = Types.SetDurationError;
  type GetUserConvictionsError    = Types.GetUserConvictionsError;
  type GetBallotError             = Types.GetBallotError;
  type PutBallotError             = Types.PutBallotError;
  type InterestBallot             = Types.InterestBallot;
  type OpinionBallot              = Types.OpinionBallot;
  type CategorizationBallot       = Types.CategorizationBallot;
  type InterestVote               = Types.InterestVote;
  type OpinionVote                = Types.OpinionVote;
  type CategorizationVote         = Types.CategorizationVote;
  type Cursor                     = Types.Cursor;
  type Polarization               = Types.Polarization;
  type CursorArray                = Types.CursorArray;
  type GetUserVotesError          = Types.GetUserVotesError;
  type CategoryInfo               = Types.CategoryInfo;
  type CategoryArray              = Types.CategoryArray;
  type RevealVoteError            = Types.RevealVoteError;
  type StatusInfo                 = Types.StatusInfo;
  type TransitionError            = Types.TransitionError;
  type QuestionId                 = Types.QuestionId;

  stable var time_now : Time.Time = Time.now();

  let _start_date = Time.now() - Duration.toTime(#HOURS(6));  // @temp

  stable var _state = State.initState(caller, _start_date, parameters);

  let _facade = Factory.build(_state);

  public shared func runScenario() : async () {
    await* Scenario.run(_facade, _start_date, Time.now(), #MINUTES(5));
  };

  public query func getName() : async Text {
    _facade.getName();
  };

  public query func getDecay() : async ?Decay {
    _facade.getDecay();
  };

  public query func getCategories() : async CategoryArray {
    _facade.getCategories();
  };

  public shared({caller}) func addCategory(category: Category, info: CategoryInfo) : async Result<(), AddCategoryError> {
    _facade.addCategory(caller, category, info);
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    _facade.removeCategory(caller, category);
  };

  public query func getInterestPickRate() : async Duration {
    _facade.getInterestPickRate();
  };

  public shared({caller}) func setInterestPickRate(rate: Duration) : async Result<(), SetPickRateError> {
    _facade.setInterestPickRate(caller, rate);
  };

  public query func getStatusDuration(status: Status) : async Duration {
    _facade.getStatusDuration(status);
  };

  public shared({caller}) func setStatusDuration(status: Status, duration: Duration) : async Result<(), SetDurationError> {
    _facade.setStatusDuration(caller, status, duration);
  };

  public query func searchQuestions(text: Text, limit: Nat) : async [Nat] {
    _facade.searchQuestions(text, limit);
  };

  public query func getQuestion(question_id: QuestionId) : async Result<Question, GetQuestionError> {
    _facade.getQuestion(question_id);
  };

  public query func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : async QuestionQueries.ScanLimitResult {
    _facade.getQuestions(order_by, direction, limit, previous_id);
  };

  public shared({caller}) func openQuestion(text: Text) : async Result<Question, OpenQuestionError> {
    await* _facade.openQuestion(caller, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: QuestionId) : async Result<(), [(?Status, TransitionError)]> {
    await* _facade.reopenQuestion(caller, question_id, Time.now());
  };

  public query({caller}) func getInterestBallot(question_id: QuestionId) : async Result<InterestBallot, GetBallotError> {
    _facade.getInterestBallot(caller, question_id);
  };

  public shared({caller}) func putInterestBallot(question_id: QuestionId, interest: Cursor) : async Result<InterestBallot, PutBallotError> {
    await* _facade.putInterestBallot(caller, question_id, Time.now(), interest);
  };

  public query({caller}) func getOpinionBallot(question_id: QuestionId) : async Result<OpinionBallot, GetBallotError> {
    _facade.getOpinionBallot(caller, question_id);
  };

  public shared({caller}) func putOpinionBallot(question_id: QuestionId, cursor: Cursor) : async Result<OpinionBallot, PutBallotError> {
    _facade.putOpinionBallot(caller, question_id, Time.now(), cursor);
  };

  public query({caller}) func getCategorizationBallot(question_id: QuestionId) : async Result<CategorizationBallot, GetBallotError> {
    _facade.getCategorizationBallot(caller, question_id);
  };

  public shared({caller}) func putCategorizationBallot(question_id: QuestionId, answer: CursorArray) : async Result<CategorizationBallot, PutBallotError> {
    await* _facade.putCategorizationBallot(caller, question_id, Time.now(), answer);
  };

  public query func getStatusInfo(question_id: QuestionId) : async Result<StatusInfo, ReopenQuestionError> {
    _facade.getStatusInfo(question_id);
  };

  public query func getStatusHistory(question_id: QuestionId) : async Result<StatusHistory, ReopenQuestionError> {
    _facade.getStatusHistory(question_id);
  };

  public query func revealInterestVote(question_id: QuestionId, iteration: Nat) : async Result<InterestVote, RevealVoteError>{
    _facade.revealInterestVote(question_id, iteration);
  };

  public query func revealOpinionVote(question_id: QuestionId, iteration: Nat) : async Result<OpinionVote, RevealVoteError>{
    _facade.revealOpinionVote(question_id, iteration);
  };

  public query func revealCategorizationVote(question_id: QuestionId, iteration: Nat) : async Result<CategorizationVote, RevealVoteError>{
    _facade.revealCategorizationVote(question_id, iteration);
  };

  public query func getUserConvictions(principal: Principal) : async ?PolarizationArray {
    _facade.getUserConvictions(principal);
  };

  public query func getUserOpinions(principal: Principal) : async ?[(Nat, PolarizationArray, OpinionBallot)] {
    _facade.getUserOpinions(principal);
  };

  public shared func run() : async() {
    await* _facade.run(Time.now());
  };

};
