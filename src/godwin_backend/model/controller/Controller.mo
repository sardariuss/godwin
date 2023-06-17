import Event               "Event";
import Schema              "Schema";
import Types               "../Types";
import Model               "../Model";
import Categories          "../Categories";
import QuestionTypes       "../questions/Types";
import Questions           "../questions/Questions";
import KeyConverter        "../questions/KeyConverter";
import StatusManager       "../questions/StatusManager";
import VoteTypes           "../votes/Types";
import Categorizations     "../votes/Categorizations";
import Votes               "../votes/Votes";
import SubaccountGenerator "../token/SubaccountGenerator";
import PolarizationMap     "../votes/representation/PolarizationMap";

import Duration            "../../utils/Duration";
import Utils               "../../utils/Utils";
import StateMachine        "../../utils/StateMachine";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Iter                "mo:base/Iter";
import Buffer              "mo:base/Buffer";
import Array               "mo:base/Array";

module {

  type Map<K, V>                   = Map.Map<K, V>;
  type Buffer<T>                   = Buffer.Buffer<T>;

  // For convenience: from other modules
  type Questions                   = Questions.Questions;
  type Model                       = Model.Model;
  type Event                       = Event.Event;
  type Schema                      = Schema.Schema;

  // For convenience: from base module
  type Result<Ok, Err>             = Result.Result<Ok, Err>;
  type Principal                   = Principal.Principal;
  type Time                        = Int;

  // For convenience: from types module
  type TransactionsRecord          = Types.TransactionsRecord;
  type Decay                       = Types.Decay; // @todo
  type PolarizationArray           = Types.PolarizationArray;
  type CategoryInfo                = Types.CategoryInfo;
  type CursorArray                 = Types.CursorArray;
  type Direction                   = Types.Direction;
  type ScanLimitResult<K>          = Types.ScanLimitResult<K>;
  type Duration                    = Types.Duration;
  type VoteKind                    = Types.VoteKind;
  type SchedulerParameters         = Types.SchedulerParameters;
  type QuestionId                  = QuestionTypes.QuestionId;
  type Question                    = QuestionTypes.Question;
  type Status                      = QuestionTypes.Status;
  type StatusHistory               = QuestionTypes.StatusHistory; // @todo
  type StatusInfo                  = QuestionTypes.StatusInfo;
  type Key                         = QuestionTypes.Key;
  type OrderBy                     = QuestionTypes.OrderBy;
  type IterationHistory            = QuestionTypes.IterationHistory;
  type Category                    = VoteTypes.Category;
  type VoterHistory                = VoteTypes.VoterHistory;
  type Ballot<T>                   = VoteTypes.Ballot<T>;
  type Vote<T, A>                  = VoteTypes.Vote<T, A>;
  type RevealedBallot<T>           = VoteTypes.RevealedBallot<T>;
  type Cursor                      = VoteTypes.Cursor;
  type Interest                    = VoteTypes.Interest;
  type Appeal                      = VoteTypes.Appeal;
  type Polarization                = VoteTypes.Polarization;
  type CursorMap                   = VoteTypes.CursorMap;
  type PolarizationMap             = VoteTypes.PolarizationMap;
  type InterestBallot              = VoteTypes.InterestBallot;
  type OpinionBallot               = VoteTypes.OpinionBallot;
  type CategorizationBallot        = VoteTypes.CategorizationBallot;
  type VoteId                      = VoteTypes.VoteId;
  type FindVoteError               = VoteTypes.FindVoteError;
  type FindQuestionIterationError  = VoteTypes.FindQuestionIterationError;
  // Errors
  type AddCategoryError            = Types.AddCategoryError;
  type RemoveCategoryError         = Types.RemoveCategoryError;
  type GetQuestionError            = Types.GetQuestionError;
  type ReopenQuestionError         = Types.ReopenQuestionError;
  type VerifyCredentialsError      = Types.VerifyCredentialsError;
  type SetPickRateError            = Types.SetPickRateError;
  type SetSchedulerParametersError = Types.SetSchedulerParametersError;
  type FindBallotError             = Types.FindBallotError;
  type PutBallotError              = Types.PutBallotError;
  type GetVoteError                = Types.GetVoteError;
  type OpenVoteError               = Types.OpenVoteError;
  type RevealVoteError             = Types.RevealVoteError;
  type TransitionError             = Types.TransitionError;
  type OpenQuestionError           = Types.OpenQuestionError; // @todo

  public func build(model: Model) : Controller {
    Controller(Schema.SchemaBuilder(model).build(), model);
  };

  public class Controller(_schema: Schema, _model: Model) = {

    public func getName() : Text {
      _model.getName();
    };

//    public func getDecay() : ?Decay {
//      _model.getUsers().getDecay();
//    };

    public func getCategories() : Categories.Categories {
      _model.getCategories();
    };

    public func addCategory(caller: Principal, category: Category, info: CategoryInfo) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func() {
        Result.mapOk<(), (), AddCategoryError>(Utils.toResult(not _model.getCategories().has(category), #CategoryAlreadyExists), func() {
          _model.getCategories().set(category, info);
        })
      });
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
        Result.mapOk<(), (), RemoveCategoryError>(Utils.toResult(_model.getCategories().has(category), #CategoryDoesntExist), func() {
          _model.getCategories().delete(category);
        })
      });
    };

    public func getSchedulerParameters() : SchedulerParameters {
      _model.getSchedulerParameters();
    };

    public func setSchedulerParameters(caller: Principal, params: SchedulerParameters) : Result<(), SetSchedulerParametersError> {
      Result.mapOk<(), (), SetSchedulerParametersError>(verifyCredentials(caller), func () {
        _model.setSchedulerParameters(params);
      });
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      _model.getQuestions().searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(_model.getQuestions().findQuestion(question_id), #QuestionNotFound);
    };

    public func openQuestion(caller: Principal, text: Text, date: Time) : async* Result<Question, OpenQuestionError> {
      // Verify if the arguments are valid
      switch(_model.getQuestions().canCreateQuestion(caller, date, text)){
        case(?err) { return #err(err); };
        case(null) {};
      };
      // Callback on create question if opening the interest vote succeeds
      let open_question = func() : (Question, Nat) {
        let question = _model.getQuestions().createQuestion(caller, date, text);
        _model.getQueries().add(KeyConverter.toStatusKey(question.id, #CANDIDATE, date));
        let iteration = _model.getStatusManager().newIteration(question.id);
        _model.getStatusManager().setCurrentStatus(question.id, #CANDIDATE, date);
        (question, iteration);
      };
      // Open the interest vote
      Result.mapErr<Question, OpenVoteError, OpenQuestionError>(
        await* _model.getInterestVotes().openVote(caller, open_question),
        func(err: OpenVoteError) : OpenQuestionError { #OpenInterestVoteFailed(err); }
      );
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async* Result<(), [(?Status, TransitionError)]> {
      let result = StateMachine.initEventResult<Status, TransitionError>();
      await* submitEvent(question_id, #REOPEN_QUESTION(#data({caller})), date, result);
      switch(result.get()){
        case(#err(err)) { return #err(err); };
        case(#ok(_)) { return #ok; };
      };
    };

    public func getInterestBallot(caller: Principal, vote_id: VoteId) : Result<RevealedBallot<Interest>, FindBallotError> {
      _model.getInterestVotes().revealBallot(caller, caller, vote_id);
    };

    public func putInterestBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Interest) : async* Result<(), PutBallotError> {
      await* _model.getInterestVotes().putBallot(principal, vote_id, date, interest);
    };

    public func getOpinionBallot(caller: Principal, vote_id: VoteId) : Result<RevealedBallot<Cursor>, FindBallotError> {
      _model.getOpinionVotes().revealBallot(caller, caller, vote_id);
    };

    public func putOpinionBallot(principal: Principal, vote_id: VoteId, date: Time, cursor: Cursor) : async* Result<(), PutBallotError> {
      await* _model.getOpinionVotes().putBallot(principal, vote_id, { answer = cursor; date; });
    };
      
    public func getCategorizationBallot(caller: Principal, vote_id: VoteId) : Result<RevealedBallot<CursorMap>, FindBallotError> {
      _model.getCategorizationVotes().revealBallot(caller, caller, vote_id);
    };
      
    public func putCategorizationBallot(principal: Principal, vote_id: VoteId, date: Time, cursors: CursorMap) : async* Result<(), PutBallotError> {
      await* _model.getCategorizationVotes().putBallot(principal, vote_id, { answer = cursors; date; });
    };

    public func getIterationHistory(question_id: Nat) : Result<IterationHistory, ReopenQuestionError> {
      switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { #err(#PrincipalIsAnonymous); };
        case(?question) { #ok(_model.getStatusManager().getIterationHistory(question_id)); };
      };
    };

    public func revealInterestVote(vote_id: VoteId) : Result<Vote<Interest, Appeal>, RevealVoteError> {
      _model.getInterestVotes().revealVote(vote_id);
    };

    public func revealOpinionVote(vote_id: VoteId) : Result<Vote<Cursor, Polarization>, RevealVoteError> {
      _model.getOpinionVotes().revealVote(vote_id);
    };

    public func revealCategorizationVote(vote_id: VoteId) : Result<Vote<CursorMap, PolarizationMap>, RevealVoteError> {
      _model.getCategorizationVotes().revealVote(vote_id);
    };

    public func findInterestVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _model.getInterestJoins().findVoteId(question_id, iteration);
    };

    public func findOpinionVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _model.getOpinionJoins().findVoteId(question_id, iteration);
    };

    public func findCategorizationVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _model.getCategorizationJoins().findVoteId(question_id, iteration);
    };

    public func getQuestionIteration(vote_kind: VoteKind, vote_id: VoteId) : Result<(QuestionId, Nat, ?Question), FindQuestionIterationError> {
      let result = switch(vote_kind){
        case(#INTEREST){
          _model.getInterestJoins().findQuestionIteration(vote_id);
        };
        case(#OPINION){
          _model.getOpinionJoins().findQuestionIteration(vote_id);
        };
        case(#CATEGORIZATION){
          _model.getCategorizationJoins().findQuestionIteration(vote_id);
        };
      };
      Result.mapOk<(QuestionId, Nat), (QuestionId, Nat, ?Question), FindQuestionIterationError>(result, func((question_id, iteration): (QuestionId, Nat)) : (QuestionId, Nat, ?Question){
        (question_id, iteration, _model.getQuestions().findQuestion(question_id));
      });
    };

    public func queryQuestions(order_by: OrderBy, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<QuestionId> {
      _model.getQueries().select(order_by, direction, limit, previous_id, null);
    };

    // @todo: should filter based on the question status in order to properly hide the author ?
    // This requires to remove the author from the Question type
    // @todo: we should be able to query the reopened questions too
    public func queryQuestionsFromAuthor(principal: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<(QuestionId, ?Question, ?TransactionsRecord)> {
      let question_ids = Utils.setScanLimit<QuestionId>(_model.getQuestions().getQuestionIdsFromAuthor(principal), Map.nhash, direction, limit, previous_id);
      Utils.mapScanLimitResult<QuestionId, (QuestionId, ?Question, ?TransactionsRecord)>(question_ids, func(question_id: QuestionId) : (QuestionId, ?Question, ?TransactionsRecord){
        (question_id, _model.getQuestions().findQuestion(question_id), _model.getInterestVotes().findOpenVoteTransactions(principal, _model.getInterestJoins().getVoteId(question_id, 0)));
      });
    };

    public func queryInterestBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId
    ) : ScanLimitResult<RevealedBallot<Interest>> {
      _model.getInterestVotes().revealBallots(caller, voter, direction, limit, previous_id);
    };

    public func queryOpinionBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId
    ) : ScanLimitResult<RevealedBallot<Cursor>> {
      _model.getOpinionVotes().revealBallots(caller, voter, direction, limit, previous_id);
    };

    public func queryCategorizationBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId
    ) : ScanLimitResult<RevealedBallot<CursorMap>> {
      _model.getCategorizationVotes().revealBallots(caller, voter, direction, limit, previous_id);
    };

    public func getVoterConvictions(principal: Principal) : Map<VoteId, (OpinionBallot, [(Category, Float)])> {
      // Get voter opinions
      // @toto: Watchout, asssumes same vote id for opinion and categorization!
      // One should retrieve the question vote id from the status manager
      // then get the last OPEN iteration from the history
      // and finally get the vote id from the join
      Map.mapFilter(
        _model.getOpinionVotes().getVoterBallots(principal),
        Map.nhash,
        func(vote_id: VoteId, ballot: OpinionBallot) : ?(OpinionBallot, [(Category, Float)]) {
          let opinion_vote = _model.getOpinionVotes().getVote(vote_id);
          switch(opinion_vote.status){
            case(#OPEN){ null; };
            case(#CLOSED) {
              ?(ballot, Utils.trieToArray(PolarizationMap.toCursorMap(_model.getCategorizationVotes().getVote(vote_id).aggregate)));
            };
          };
        }
      );
    };

    public func run(time: Time) : async* () {
      for (question in _model.getQuestions().iter()){
        await* submitEvent(question.id, #TIME_UPDATE(#data({time;})), time, StateMachine.initEventResult<Status, TransitionError>());
      };
    };

    func verifyCredentials(principal: Principal) : Result<(), VerifyCredentialsError> {
      Result.mapOk<(), (), VerifyCredentialsError>(Utils.toResult(principal == _model.getMaster(), #InsufficientCredentials), (func(){}));
    };

    func submitEvent(question_id: Nat, event: Event, date: Time, result: Schema.EventResult) : async* () {

      let (iteration, current) = _model.getStatusManager().getCurrentStatus(question_id);

      // Submit the event
      await* StateMachine.submitEvent(_schema, current.status, question_id, event, result);

      switch(result.get()){
        case(#err(_)) {}; // No transition
        case(#ok(new)) {
          // When the question status changes, update the associated key for the #STATUS order_by
          _model.getQueries().replace(
            ?KeyConverter.toStatusKey(question_id, current.status, current.date),
            Option.map(new, func(status: Status) : Key { KeyConverter.toStatusKey(question_id, status, date); })
          );
          // Close vote(s) if any
          switch(current.status){
            case(#CANDIDATE) { 
              await* _model.getInterestVotes().closeVote(_model.getInterestJoins().getVoteId(question_id, iteration));
            };
            case(#OPEN)      { 
              await* _model.getOpinionVotes().closeVote(_model.getOpinionJoins().getVoteId(question_id, iteration));
              await* _model.getCategorizationVotes().closeVote(_model.getCategorizationJoins().getVoteId(question_id, iteration)); 
            };
            case(_) {};
          };
          switch(new){
            case(null) {
              // Remove status and question
              _model.getStatusManager().removeIterationHistory(question_id);
              _model.getQuestions().removeQuestion(question_id);
            };
            case(?status){
              switch(status){
                case(#CANDIDATE) { 
                  // Interest vote has already been opened by the state machine
                };
                case(#OPEN) { 
                  _model.getOpinionJoins().addJoin(question_id, iteration, _model.getOpinionVotes().newVote());
                  _model.getCategorizationJoins().addJoin(question_id, iteration, _model.getCategorizationVotes().newVote());
                };
                case(#CLOSED) {
                  // Add the question to the archive queries
                  let previous_key = if (iteration == 0) { null; } else {
                    switch(StatusManager.findStatusInfo(_model.getStatusManager().getIterationHistory(question_id), #CLOSED, iteration - 1)){
                      case(null) { null; };
                      case(?status_info) { ?KeyConverter.toStatusKey(question_id, #CLOSED, status_info.date); };
                    };
                  };
                  _model.getQueries().replace(previous_key, ?KeyConverter.toArchiveKey(question_id, current.date));
                };
                case(#REJECTED(_)) {};
              };
              // Finally set the status as current
              _model.getStatusManager().setCurrentStatus(question_id, status, date);
            };
          };
        };
      };
    };

  };

};