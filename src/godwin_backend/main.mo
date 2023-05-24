import Types           "model/Types";
import State           "model/State";
import Factory         "model/Factory";
import Facade          "model/Facade";

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
  type Duration                   = Types.Duration;
  type Status                     = Types.Status;
  type TransactionsRecord         = Types.TransactionsRecord;
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
  type FindBallotError            = Types.FindBallotError;
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
  type FindVoteError              = Types.FindVoteError;
  type StatusInfo                 = Types.StatusInfo;
  type TransitionError            = Types.TransitionError;
  type QuestionId                 = Types.QuestionId;
  type VoteId                     = Types.VoteId;
  type QuestionOrderBy            = Types.QuestionOrderBy;
  type Direction                  = Types.Direction;
  type ScanLimitResult<K>         = Types.ScanLimitResult<K>;
  type IterationHistory           = Types.IterationHistory;
  type VoteKind                   = Types.VoteKind;
  type FindQuestionIterationError = Types.FindQuestionIterationError;

  stable var time_now : Time.Time = Time.now();

  let _start_date = Time.now() - Duration.toTime(#HOURS(12));  // @temp

  stable var _state = State.initState(caller, _start_date, parameters);

  let _facade = Factory.build(_state);

  public shared func runScenario() : async () {
    await* Scenario.run(_facade, _start_date, Time.now(), #MINUTES(10));
  };

  public query func getName() : async Text {
    _facade.getName();
  };

  // @todo: revive decay
//  public query func getDecay() : async ?Decay {
//    _facade.getDecay();
//  };

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

  public query func searchQuestions(text: Text, limit: Nat) : async [QuestionId] {
    _facade.searchQuestions(text, limit);
  };

  public query func getQuestion(question_id: QuestionId) : async Result<Question, GetQuestionError> {
    _facade.getQuestion(question_id);
  };

  public query func getQuestions(order_by: QuestionOrderBy, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QuestionId> {
    _facade.getQuestions(order_by, direction, limit, previous_id);
  };

  public shared({caller}) func openQuestion(text: Text) : async Result<Question, OpenQuestionError> {
    await* _facade.openQuestion(caller, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: QuestionId) : async Result<(), [(?Status, TransitionError)]> {
    await* _facade.reopenQuestion(caller, question_id, Time.now());
  };

  public query({caller}) func getInterestBallot(vote_id: VoteId) : async Result<InterestBallot, FindBallotError> {
    _facade.getInterestBallot(caller, vote_id);
  };

  public shared({caller}) func putInterestBallot(vote_id: VoteId, interest: Cursor) : async Result<InterestBallot, PutBallotError> {
    await* _facade.putInterestBallot(caller, vote_id, Time.now(), interest);
  };

  public query({caller}) func getOpinionBallot(vote_id: VoteId) : async Result<OpinionBallot, FindBallotError> {
    _facade.getOpinionBallot(caller, vote_id);
  };

  public shared({caller}) func putOpinionBallot(vote_id: VoteId, cursor: Cursor) : async Result<OpinionBallot, PutBallotError> {
    await* _facade.putOpinionBallot(caller, vote_id, Time.now(), cursor);
  };

  public query({caller}) func getCategorizationBallot(vote_id: VoteId) : async Result<CategorizationBallot, FindBallotError> {
    _facade.getCategorizationBallot(caller, vote_id);
  };

  public shared({caller}) func putCategorizationBallot(vote_id: VoteId, answer: CursorArray) : async Result<CategorizationBallot, PutBallotError> {
    await* _facade.putCategorizationBallot(caller, vote_id, Time.now(), answer);
  };

  public query func getIterationHistory(question_id: QuestionId) : async Result<IterationHistory, ReopenQuestionError> {
    _facade.getIterationHistory(question_id);
  };

  public query func revealInterestVote(vote_id: VoteId) : async Result<InterestVote, RevealVoteError>{
    _facade.revealInterestVote(vote_id);
  };

  public query func revealOpinionVote(vote_id: VoteId) : async Result<OpinionVote, RevealVoteError>{
    _facade.revealOpinionVote(vote_id);
  };

  public query func revealCategorizationVote(vote_id: VoteId) : async Result<CategorizationVote, RevealVoteError>{
    _facade.revealCategorizationVote(vote_id);
  };

  public query func findInterestVoteId(question_id: QuestionId, iteration: Nat) : async Result<VoteId, FindVoteError> {
    _facade.findInterestVoteId(question_id, iteration);
  };

  public query func findOpinionVoteId(question_id: QuestionId, iteration: Nat) : async Result<VoteId, FindVoteError> {
    _facade.findOpinionVoteId(question_id, iteration);
  };

  public query func findCategorizationVoteId(question_id: QuestionId, iteration: Nat) : async Result<VoteId, FindVoteError> {
    _facade.findCategorizationVoteId(question_id, iteration);
  };

  public query func revealInterestBallots(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : async ScanLimitResult<(VoteId, ?InterestBallot, ?TransactionsRecord)> {
    _facade.revealInterestBallots(principal, direction, limit, previous_id);
  };

  public query func revealOpinionBallots(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : async ScanLimitResult<(VoteId, ?OpinionBallot, ?TransactionsRecord)> {
    _facade.revealOpinionBallots(principal, direction, limit, previous_id);
  };

  public query func revealCategorizationBallots(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : async ScanLimitResult<(VoteId, ?CategorizationBallot, ?TransactionsRecord)> {
    _facade.revealCategorizationBallots(principal, direction, limit, previous_id);
  };

  public query func getQuestionIteration(vote_kind: VoteKind, vote_id: VoteId) : async Result<(Question, Nat), FindQuestionIterationError> {
    _facade.getQuestionIteration(vote_kind, vote_id);
  };

  public query func getQuestionsFromAuthor(principal: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<(QuestionId, ?Question, ?TransactionsRecord)> {
    _facade.getQuestionsFromAuthor(principal, direction, limit, previous_id);
  };

  public query func getVoterConvictions(principal: Principal) : async [(VoteId, (OpinionBallot, [(Category, Float)]))] {
    _facade.getVoterConvictions(principal);
  };

  public shared func run() : async() {
    await* _facade.run(Time.now());
  };

};
