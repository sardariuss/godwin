import Types           "model/Types";
import Factory         "model/Factory";
import Controller      "model/controller/Controller";
import MigrationTypes  "stable/Types";
import Migrations      "stable/Migrations";

import Result          "mo:base/Result";
import Principal       "mo:base/Principal";
import Time            "mo:base/Time";
import Debug           "mo:base/Debug";

import ckBTC           "canister:ck_btc";

shared actor class GodwinSub(args: MigrationTypes.Args) = self {

  // For convenience: from base module
  type Result<Ok, Err>                = Result.Result<Ok, Err>;
  type Principal                      = Principal.Principal;
  type Time                           = Time.Time;

  // For convenience: from controller module
  type Controller                     = Controller.Controller;
  // For convenience: from types module
  type Question                       = Types.Question;
  type Category                       = Types.Category;
  type Duration                       = Types.Duration;
  type Status                         = Types.Status;
  type TransactionsRecord             = Types.TransactionsRecord;
  type PriceParameters                = Types.PriceParameters;
  type SchedulerParameters            = Types.SchedulerParameters;
  type QueryQuestionItem              = Types.QueryQuestionItem;
  type QueryVoteItem                  = Types.QueryVoteItem;
  type QueryOpenedVoteItem            = Types.QueryOpenedVoteItem;
  type StatusData                     = Types.StatusData;
  type QuestionId                     = Types.QuestionId;
  type SubInfo                        = Types.SubInfo;
  type VoteId                         = Types.VoteId;
  type QuestionOrderBy                = Types.QuestionOrderBy;
  type Direction                      = Types.Direction;
  type ScanLimitResult<K>             = Types.ScanLimitResult<K>;
  type VoteKind                       = Types.VoteKind;
  type Momentum                       = Types.Momentum;
  type SelectionParameters            = Types.SelectionParameters;
  type BallotConvictionInput          = Types.BallotConvictionInput;
  type KindRevealableBallot           = Types.KindRevealableBallot;
  type KindAnswer                     = Types.KindAnswer;
  type KindVote                       = Types.KindVote;
  // Error types
  type GetQuestionError               = Types.GetQuestionError;
  type OpenQuestionError              = Types.OpenQuestionError;
  type ReopenQuestionError            = Types.ReopenQuestionError;
  type AccessControlError             = Types.AccessControlError;
  type SetSchedulerParametersError    = Types.SetSchedulerParametersError;
  type FindBallotError                = Types.FindBallotError;
  type PutBallotError                 = Types.PutBallotError;
  type RevealVoteError                = Types.RevealVoteError;

  stable var _state: MigrationTypes.State = Migrations.install(Time.now(), args);

  _state := Migrations.migrate(_state, Time.now(), args);

  let _controller = switch(_state){
    case(#v0_2_0(state)) { ?Factory.build(state, Principal.fromActor(ckBTC)); };
    case(_)              { null;                                              };
  };

  public query func getVersions() : async MigrationTypes.Versions {
    Migrations.getVersions(_state);
  };

  public query func getSubInfo() : async SubInfo {
    getController().getSubInfo();
  };

  public shared({caller}) func setSchedulerParameters(params: SchedulerParameters) : async Result<(), SetSchedulerParametersError> {
    getController().setSchedulerParameters(caller, params);
  };

  public shared({caller}) func setSelectionParameters(params: SelectionParameters) : async Result<(), AccessControlError> {
    getController().setSelectionParameters(caller, params);
  };

  public shared({caller}) func setPriceParameters(params: PriceParameters) : async Result<(), AccessControlError> {
    getController().setPriceParameters(caller, params);
  };

  public query func searchQuestions(text: Text, limit: Nat) : async [QuestionId] {
    getController().searchQuestions(text, limit);
  };

  public query func getQuestion(question_id: QuestionId) : async Result<Question, GetQuestionError> {
    getController().getQuestion(question_id);
  };

  public shared({caller}) func openQuestion(text: Text) : async Result<QuestionId, OpenQuestionError> {
    await* getController().openQuestion(caller, text, Time.now());
  };

  public shared({caller}) func reopenQuestion(question_id: QuestionId) : async Result<(), Text> {
    await* getController().reopenQuestion(caller, question_id, Time.now());
  };

  public query({caller}) func revealBallot(vote_kind: VoteKind, voter: Principal, vote_id: VoteId) : async Result<KindRevealableBallot, FindBallotError> {
    getController().revealBallot(vote_kind, caller, voter, vote_id);
  };

  public shared({caller}) func putBallot(vote_kind: VoteKind, id: VoteId, answer: KindAnswer) : async Result<(), PutBallotError> {
    await* getController().putBallot(vote_kind, caller, id, Time.now(), answer);
  };

  public query func revealVote(vote_kind: VoteKind, id: VoteId) : async Result<KindVote, RevealVoteError> {
    getController().revealVote(vote_kind, id);
  };

  public query func getStatusHistory(question_id: QuestionId) : async Result<[StatusData], ReopenQuestionError> {
    getController().getStatusHistory(question_id);
  };

  public query func findOpenedVoteTransactions(principal: Principal, id: VoteId) : async ?TransactionsRecord {
    getController().findOpenedVoteTransactions(principal, id);
  };

  public query func queryOpenedVotes(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : async ScanLimitResult<QueryOpenedVoteItem> {
    getController().queryOpenedVotes(principal, direction, limit, previous_id);
  };

  public query func getVoterConvictions(principal: Principal) : async [(VoteId, BallotConvictionInput)] {
    getController().getVoterConvictions(Time.now(), principal);
  };

  public query func getNumberVotes(vote_kind: VoteKind, voter: Principal) : async Nat {
    getController().getNumberVotes(vote_kind, voter);
  };

  public query func queryQuestions(order_by: QuestionOrderBy, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QueryQuestionItem> {
    getController().queryQuestions(order_by, direction, limit, previous_id);
  };

  public query({caller}) func queryFreshVotes(vote_kind: VoteKind, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QueryVoteItem> {
    getController().queryFreshVotes(caller, vote_kind, direction, limit, previous_id);
  };

  public query({caller}) func queryVoterBallots(vote_kind: VoteKind, voter: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : async ScanLimitResult<QueryVoteItem> {
    getController().queryVoterBallots(vote_kind, caller, voter, direction, limit, previous_id);
  };

  public query({caller}) func queryVoterQuestionBallots(question_id: QuestionId, vote_kind: VoteKind, voter: Principal) : async [(Nat, ?KindRevealableBallot)] {
    getController().queryVoterQuestionBallots(question_id, vote_kind, caller, voter);
  };

  public query func findBallotTransactions(vote_kind: VoteKind, principal: Principal, id: VoteId) : async ?TransactionsRecord {
    getController().findBallotTransactions(vote_kind, principal, id);
  };

  public shared({caller}) func run() : async() {
    await* getController().run(Time.now(), caller);
  };

  func getController() : Controller {
    switch(_controller){
      case (?c) { 
        // Unfortunately the principal of the canister cannot be set at construction because of 
        // compiler error "cannot use self before self has been defined".
        // Surprisingly the getController function can still be called in query functions.
        c.setSelfId(Principal.fromActor(self));
        c; 
      };
      case (null) { Debug.trap("Controller is null"); };
    };
  };
 
};
