import Types           "model/Types";
import Factory         "model/Factory";
import Facade          "model/Facade";
import MigrationTypes  "stable/Types";
import Migrations      "stable/Migrations";

import Result          "mo:base/Result";
import Principal       "mo:base/Principal";
import Time            "mo:base/Time";
import Debug           "mo:base/Debug";

shared actor class GodwinSub(args: MigrationTypes.Args) = {

  // For convenience: from base module
  type Result<Ok, Err>              = Result.Result<Ok, Err>;
  type Principal                    = Principal.Principal;
  type Time                         = Time.Time;

  // For convenience: from Facade module
  type Facade                       = Facade.Facade;
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
  type AccessControlError           = Types.AccessControlError;
  type BasePriceParameters          = Types.BasePriceParameters;
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
  type QueryQuestionItem            = Types.QueryQuestionItem;
  type QueryVoteItem                = Types.QueryVoteItem;
  type GetUserVotesError            = Types.GetUserVotesError;
  type CategoryInfo                 = Types.CategoryInfo;
  type CategoryArray                = Types.CategoryArray;
  type RevealVoteError              = Types.RevealVoteError;
  type FindVoteError                = Types.FindVoteError;
  type StatusInfo                   = Types.StatusInfo;
  type StatusData                   = Types.StatusData;
  type QuestionId                   = Types.QuestionId;
  type VoteId                       = Types.VoteId;
  type QuestionOrderBy              = Types.QuestionOrderBy;
  type Direction                    = Types.Direction;
  type ScanLimitResult<K>           = Types.ScanLimitResult<K>;
  type VoteKind                     = Types.VoteKind;
  type Momentum                     = Types.Momentum;
  type SelectionParameters          = Types.SelectionParameters;
  type PriceRegister                = Types.PriceRegister;
  type FindQuestionIterationError   = Types.FindQuestionIterationError;
  type RevealedInterestBallot       = Types.RevealedInterestBallot;
  type RevealedOpinionBallot        = Types.RevealedOpinionBallot;
  type RevealedCategorizationBallot = Types.RevealedCategorizationBallot;
  type BallotConvictionInput        = Types.BallotConvictionInput;

  stable var _state: MigrationTypes.State = Migrations.install(Time.now(), args);

  _state := Migrations.migrate(_state, Time.now(), args);

  // In subsequent versions, the facade will be set to null if the version of the state is not the last one
  let _facade = switch(_state){
    case(#v0_1_0(state)) { ?Factory.build(state); };
  };

  public query func getName() : async Text {
    getFacade().getName();
  };

  public query func getOpinionVoteHalfLife() : async Duration {
    getFacade().getOpinionVoteHalfLife();
  };

  public query func getLateOpinionBallotHalfLife() : async Duration {
    getFacade().getLateOpinionBallotHalfLife();
  };

  public query func getCategories() : async CategoryArray {
    getFacade().getCategories();
  };

  public shared({caller}) func addCategory(category: Category, info: CategoryInfo) : async Result<(), AddCategoryError> {
    getFacade().addCategory(caller, category, info);
  };

  public shared({caller}) func removeCategory(category: Category) : async Result<(), RemoveCategoryError> {
    getFacade().removeCategory(caller, category);
  };

  public query func getSchedulerParameters() : async SchedulerParameters {
    getFacade().getSchedulerParameters();
  };

  public shared({caller}) func setSchedulerParameters(params: SchedulerParameters) : async Result<(), SetSchedulerParametersError> {
    getFacade().setSchedulerParameters(caller, params);
  };

  public query func getSelectionParameters() : async SelectionParameters {
    getFacade().getSelectionParameters();
  };

  public query func getSelectionParametersAndMomentum() : async (SelectionParameters, Momentum) {
    getFacade().getSelectionParametersAndMomentum();
  };

  public shared({caller}) func setSelectionParameters(params: SelectionParameters) : async Result<(), AccessControlError> {
    getFacade().setSelectionParameters(caller, params);
  };

  public query func getSubPrices() : async PriceRegister {
    getFacade().getSubPrices();
  };

  public shared({caller}) func setBasePriceParameters(params: BasePriceParameters) : async Result<(), AccessControlError> {
    getFacade().setBasePriceParameters(caller, params);
  };

  public query func searchQuestions(text: Text, limit: Nat) : async [QuestionId] {
    getFacade().searchQuestions(text, limit);
  };

  public query func getQuestion(question_id: QuestionId) : async Result<Question, GetQuestionError> {
    getFacade().getQuestion(question_id);
  };

  public shared({caller}) func openQuestion(text: Text) : async Result<QuestionId, OpenQuestionError> {
    await* getFacade().openQuestion(caller, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: QuestionId) : async Result<(), [(?Status, Text)]> {
    await* getFacade().reopenQuestion(caller, question_id, Time.now());
  };

  public query({caller}) func getInterestBallot(vote_id: VoteId) : async Result<RevealedInterestBallot, FindBallotError> {
    getFacade().getInterestBallot(caller, vote_id);
  };

  public shared({caller}) func putInterestBallot(vote_id: VoteId, interest: Interest) : async Result<(), PutBallotError> {
    await* getFacade().putInterestBallot(caller, vote_id, Time.now(), interest);
  };

  public query({caller}) func getOpinionBallot(vote_id: VoteId) : async Result<RevealedOpinionBallot, FindBallotError> {
    getFacade().getOpinionBallot(caller, vote_id);
  };

  public shared({caller}) func putOpinionBallot(vote_id: VoteId, cursor: Cursor) : async Result<(), PutBallotError> {
    await* getFacade().putOpinionBallot(caller, vote_id, Time.now(), cursor);
  };

  public query({caller}) func getCategorizationBallot(vote_id: VoteId) : async Result<RevealedCategorizationBallot, FindBallotError> {
    getFacade().getCategorizationBallot(caller, vote_id);
  };

  public shared({caller}) func putCategorizationBallot(vote_id: VoteId, answer: CursorArray) : async Result<(), PutBallotError> {
    await* getFacade().putCategorizationBallot(caller, vote_id, Time.now(), answer);
  };

  public query func getStatusHistory(question_id: QuestionId) : async Result<[StatusData], ReopenQuestionError> {
    getFacade().getStatusHistory(question_id);
  };

  public query func revealInterestVote(vote_id: VoteId) : async Result<InterestVote, RevealVoteError>{
    getFacade().revealInterestVote(vote_id);
  };

  public query func revealOpinionVote(vote_id: VoteId) : async Result<OpinionVote, RevealVoteError>{
    getFacade().revealOpinionVote(vote_id);
  };

  public query func revealCategorizationVote(vote_id: VoteId) : async Result<CategorizationVote, RevealVoteError>{
    getFacade().revealCategorizationVote(vote_id);
  };

  public query func getQuestionIteration(vote_kind: VoteKind, vote_id: VoteId) : async Result<(QuestionId, Nat, ?Question), FindQuestionIterationError> {
    getFacade().getQuestionIteration(vote_kind, vote_id);
  };

  public query func queryQuestionsFromAuthor(principal: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<(QuestionId, ?Question, ?TransactionsRecord)> {
    getFacade().queryQuestionsFromAuthor(principal, direction, limit, previous_id);
  };

  public query func getVoterConvictions(principal: Principal) : async [(VoteId, BallotConvictionInput)] {
    getFacade().getVoterConvictions(Time.now(), principal);
  };

  public query func queryQuestions(order_by: QuestionOrderBy, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QueryQuestionItem> {
    getFacade().queryQuestions(order_by, direction, limit, previous_id);
  };

  public query({caller}) func queryFreshVotes(vote_kind: VoteKind, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QueryVoteItem> {
    getFacade().queryFreshVotes(caller, vote_kind, direction, limit, previous_id);
  };

  public query({caller}) func queryVoterBallots(vote_kind: VoteKind, voter: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QueryVoteItem> {
    getFacade().queryVoterBallots(vote_kind, caller, voter, direction, limit, previous_id);
  };

  public shared func run() : async() {
    await* getFacade().run(Time.now());
  };

  func getFacade() : Facade {
    switch(_facade){
      case (?f) { f; };
      case (null) { Debug.trap("Facade is null"); };
    };
  };

};
