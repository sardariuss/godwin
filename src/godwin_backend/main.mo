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
  type Result<Ok, Err>              = Result.Result<Ok, Err>;
  type Principal                    = Principal.Principal;
  type Time                         = Time.Time;

  // For convenience: from types module
  type Question                     = Types.Question;
  type Category                     = Types.Category;
  type Duration                     = Types.Duration;
  type Status                       = Types.Status;
  type TransactionsRecord           = Types.TransactionsRecord;
  type PolarizationArray            = Types.PolarizationArray;
  type AddCategoryError             = Types.AddCategoryError;
  type RemoveCategoryError          = Types.RemoveCategoryError;
  type GetQuestionError             = Types.GetQuestionError;
  type OpenQuestionError            = Types.OpenQuestionError;
  type ReopenQuestionError          = Types.ReopenQuestionError;
  type VerifyCredentialsError       = Types.VerifyCredentialsError;
  type PrincipalError               = Types.PrincipalError;
  type SetPickRateError             = Types.SetPickRateError;
  type SchedulerParameters          = Types.SchedulerParameters;
  type SetSchedulerParametersError  = Types.SetSchedulerParametersError;
  type GetUserConvictionsError      = Types.GetUserConvictionsError;
  type FindBallotError              = Types.FindBallotError;
  type PutBallotError               = Types.PutBallotError;
  type InterestBallot               = Types.InterestBallot;
  type OpinionBallot                = Types.OpinionBallot;
  type CategorizationBallot         = Types.CategorizationBallot;
  type InterestVote                 = Types.InterestVote;
  type OpinionVote                  = Types.OpinionVote;
  type CategorizationVote           = Types.CategorizationVote;
  type Interest                     = Types.Interest;
  type Cursor                       = Types.Cursor;
  type Polarization                 = Types.Polarization;
  type CursorArray                  = Types.CursorArray;
  type GetUserVotesError            = Types.GetUserVotesError;
  type CategoryInfo                 = Types.CategoryInfo;
  type CategoryArray                = Types.CategoryArray;
  type RevealVoteError              = Types.RevealVoteError;
  type FindVoteError                = Types.FindVoteError;
  type StatusInfo                   = Types.StatusInfo;
  type QuestionId                   = Types.QuestionId;
  type VoteId                       = Types.VoteId;
  type QuestionOrderBy              = Types.QuestionOrderBy;
  type Direction                    = Types.Direction;
  type ScanLimitResult<K>           = Types.ScanLimitResult<K>;
  type VoteKind                     = Types.VoteKind;
  type FindQuestionIterationError   = Types.FindQuestionIterationError;
  type RevealedInterestBallot       = Types.RevealedInterestBallot;
  type RevealedOpinionBallot        = Types.RevealedOpinionBallot;
  type RevealedCategorizationBallot = Types.RevealedCategorizationBallot;

  stable var time_now : Time.Time = Time.now();

  let _start_date = Time.now() - Duration.toTime(#MINUTES(830));  // @temp

  stable var _state = State.initState(caller, _start_date, parameters);

  let _facade = Factory.build(_state);

  public shared func runScenario() : async () {
    await* Scenario.run(_facade, _start_date, Time.now(), #MINUTES(10));
  };

  public query func getName() : async Text {
    _facade.getName();
  };

  public query func getHalfLife() : async Duration {
    _facade.getHalfLife();
  };

  public query func getSelectionScore() : async Float {
    _facade.getSelectionScore(Time.now());
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

  public query func getSchedulerParameters() : async SchedulerParameters {
    _facade.getSchedulerParameters();
  };

  public shared({caller}) func setSchedulerParameters(params: SchedulerParameters) : async Result<(), SetSchedulerParametersError> {
    _facade.setSchedulerParameters(caller, params);
  };

  public query func searchQuestions(text: Text, limit: Nat) : async [QuestionId] {
    _facade.searchQuestions(text, limit);
  };

  public query func getQuestion(question_id: QuestionId) : async Result<Question, GetQuestionError> {
    _facade.getQuestion(question_id);
  };

  public shared({caller}) func openQuestion(text: Text) : async Result<QuestionId, OpenQuestionError> {
    await* _facade.openQuestion(caller, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: QuestionId) : async Result<(), [(?Status, Text)]> {
    await* _facade.reopenQuestion(caller, question_id, Time.now());
  };

  public query({caller}) func getInterestBallot(vote_id: VoteId) : async Result<RevealedInterestBallot, FindBallotError> {
    _facade.getInterestBallot(caller, vote_id);
  };

  public shared({caller}) func putInterestBallot(vote_id: VoteId, interest: Interest) : async Result<(), PutBallotError> {
    await* _facade.putInterestBallot(caller, vote_id, Time.now(), interest);
  };

  public query({caller}) func getOpinionBallot(vote_id: VoteId) : async Result<RevealedOpinionBallot, FindBallotError> {
    _facade.getOpinionBallot(caller, vote_id);
  };

  public shared({caller}) func putOpinionBallot(vote_id: VoteId, cursor: Cursor) : async Result<(), PutBallotError> {
    await* _facade.putOpinionBallot(caller, vote_id, Time.now(), cursor);
  };

  public query({caller}) func getCategorizationBallot(vote_id: VoteId) : async Result<RevealedCategorizationBallot, FindBallotError> {
    _facade.getCategorizationBallot(caller, vote_id);
  };

  public shared({caller}) func putCategorizationBallot(vote_id: VoteId, answer: CursorArray) : async Result<(), PutBallotError> {
    await* _facade.putCategorizationBallot(caller, vote_id, Time.now(), answer);
  };

  public query func getStatusHistory(question_id: QuestionId) : async Result<[StatusInfo], ReopenQuestionError> {
    _facade.getStatusHistory(question_id);
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

  public query({caller}) func queryInterestBallots(voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : async ScanLimitResult<RevealedInterestBallot> {
    _facade.queryInterestBallots(caller, voter, direction, limit, previous_id);
  };

  public query({caller}) func queryOpinionBallots(voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : async ScanLimitResult<RevealedOpinionBallot> {
    _facade.queryOpinionBallots(caller, voter, direction, limit, previous_id);
  };

  public query({caller}) func queryCategorizationBallots(voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : async ScanLimitResult<RevealedCategorizationBallot> {
    _facade.queryCategorizationBallots(caller, voter, direction, limit, previous_id);
  };

  public query func getQuestionIteration(vote_kind: VoteKind, vote_id: VoteId) : async Result<(QuestionId, Nat, ?Question), FindQuestionIterationError> {
    _facade.getQuestionIteration(vote_kind, vote_id);
  };

  public query func queryQuestionsFromAuthor(principal: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<(QuestionId, ?Question, ?TransactionsRecord)> {
    _facade.queryQuestionsFromAuthor(principal, direction, limit, previous_id);
  };

  public query func getVoterConvictions(principal: Principal) : async [(VoteId, (OpinionBallot, [(Category, Float)], Float, Bool))] {
    _facade.getVoterConvictions(Time.now(), principal);
  };

  public query func queryQuestions(order_by: QuestionOrderBy, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QuestionId> {
    _facade.queryQuestions(order_by, direction, limit, previous_id);
  };

  public query({caller}) func queryFreshVotes(vote_kind: VoteKind, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QuestionId> {
    _facade.queryFreshVotes(caller, vote_kind, direction, limit, previous_id);
  };

  public shared func run() : async() {
    await* _facade.run(Time.now());
  };

};
