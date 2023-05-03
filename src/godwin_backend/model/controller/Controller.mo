import Event               "Event";
import Schema              "Schema";
import Types               "../Types";
import Model               "../Model";
import Categories          "../Categories";
import QuestionQueries     "../questions/QuestionQueries";
import Questions           "../questions/Questions";
import Categorizations     "../votes/Categorizations";
import Votes               "../votes/Votes";
import SubaccountGenerator "../token/SubaccountGenerator";

import Duration            "../../utils/Duration";
import Utils               "../../utils/Utils";
import StateMachine        "../../utils/StateMachine";

import Result              "mo:base/Result";
import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Iter                "mo:base/Iter";

module {

  // For convenience: from other modules
  type Questions              = Questions.Questions;
  type Model                  = Model.Model;
  type Duration               = Duration.Duration;
  type Event                  = Event.Event;
  type Schema                 = Schema.Schema;
  type Key                    = QuestionQueries.Key;
  let { toStatusEntry }       = QuestionQueries;

  // For convenience: from base module
  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Principal              = Principal.Principal;
  type Time                   = Int;

  // For convenience: from types module
  type Question               = Types.Question;
  type Category               = Types.Category;
  type Decay                  = Types.Decay;
  type Status                 = Types.Status;
  type PolarizationArray      = Types.PolarizationArray;
  type Ballot<T>              = Types.Ballot<T>;
  type Vote<T, A>             = Types.Vote<T, A>;
  type PublicVote<T, A>       = Types.PublicVote<T, A>;
  type Cursor                 = Types.Cursor;
  type Polarization           = Types.Polarization;
  type CursorMap              = Types.CursorMap;
  type PolarizationMap        = Types.PolarizationMap;
  type CursorArray            = Types.CursorArray;
  type CategoryInfo           = Types.CategoryInfo;
  type CategoryArray          = Types.CategoryArray;
  type StatusHistory          = Types.StatusHistory;
  type StatusInfo             = Types.StatusInfo;
  type InterestBallot         = Types.InterestBallot;
  type OpinionBallot          = Types.OpinionBallot;
  type CategorizationBallot   = Types.CategorizationBallot;
  type VoteId                 = Types.VoteId;
  // Errors
  type AddCategoryError       = Types.AddCategoryError;
  type RemoveCategoryError    = Types.RemoveCategoryError;
  type GetQuestionError       = Types.GetQuestionError;
  type OpenQuestionError      = Types.OpenQuestionError;
  type ReopenQuestionError    = Types.ReopenQuestionError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type SetPickRateError       = Types.SetPickRateError;
  type SetDurationError       = Types.SetDurationError;
  type GetBallotError         = Types.GetBallotError;
  type PutBallotError         = Types.PutBallotError;
  type GetVoteError           = Types.GetVoteError;
  type OpenVoteError          = Types.OpenVoteError;
  type RevealVoteError        = Types.RevealVoteError;
  type TransitionError        = Types.TransitionError;

  public func build(model: Model) : Controller {
    Controller(Schema.SchemaBuilder(model).build(), model);
  };

  public class Controller(_schema: Schema, _model: Model) = {

    public func getName() : Text {
      _model.getName();
    };

    public func getDecay() : ?Decay {
      _model.getUsers().getDecay();
    };

    public func getCategories() : CategoryArray {
      Iter.toArray(_model.getCategories().entries());
    };

    public func addCategory(caller: Principal, category: Category, info: CategoryInfo) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func() {
        Result.mapOk<(), (), AddCategoryError>(Utils.toResult(not _model.getCategories().has(category), #CategoryAlreadyExists), func() {
          _model.getCategories().set(category, info);
          _model.getUsers().addCategory(category);
        })
      });
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
        Result.mapOk<(), (), RemoveCategoryError>(Utils.toResult(_model.getCategories().has(category), #CategoryDoesntExist), func() {
          _model.getCategories().delete(category);
          _model.getUsers().removeCategory(category);
        })
      });
    };

    public func getInterestPickRate() : Duration {
      _model.getInterestPickRate();
    };

    public func setInterestPickRate(caller: Principal, rate: Duration) : Result<(), SetPickRateError> {
      Result.mapOk<(), (), SetPickRateError>(verifyCredentials(caller), func () {
        _model.setInterestPickRate(rate);
      });
    };

    public func getStatusDuration(status: Status) : Duration {
      _model.getStatusDuration(status);
    };

    public func setStatusDuration(caller: Principal, status: Status, duration: Duration) : Result<(), SetDurationError> {
      Result.mapOk<(), (), SetDurationError>(verifyCredentials(caller), func () {
        _model.setStatusDuration(status, duration);
      });
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      _model.getQuestions().searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(_model.getQuestions().findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries.ScanLimitResult {
      _model.getQueries().select(order_by, direction, limit, previous_id);
    };

    public func openQuestion(caller: Principal, text: Text, date: Time) : async* Result<Question, OpenQuestionError> {
      // Verify if the arguments are valid
      switch(_model.getQuestions().canCreateQuestion(caller, date, text)){
        case(?err) { return #err(err); };
        case(null) {};
      };
      // Callback on create question if opening the interest vote succeeds
      let open_question = func() : Question {
        let question = _model.getQuestions().createQuestion(caller, date, text);
        _model.getQueries().add(toStatusEntry(question.id, #CANDIDATE, date));
        _model.getStatusManager().setCurrent(question.id, #CANDIDATE, date);
        question;
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

    public func getInterestBallot(caller: Principal, question_id: Nat) : Result<Ballot<Cursor>, GetBallotError> {
      _model.getInterestVotes().getBallot(caller, question_id);
    };

    public func putInterestBallot(principal: Principal, question_id: Nat, date: Time, interest: Cursor) : async* Result<InterestBallot, PutBallotError> {
      Result.mapOk<(), InterestBallot, PutBallotError>(await* _model.getInterestVotes().putBallot(principal, question_id, date, interest), func() : InterestBallot {
        { date = date; answer = interest; }
      });
    };

    public func getOpinionBallot(caller: Principal, question_id: Nat) : Result<Ballot<Cursor>, GetBallotError> {
      _model.getOpinionVotes().getBallot(caller, question_id);
    };

    public func putOpinionBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<OpinionBallot, PutBallotError> {
      Result.mapOk<(), OpinionBallot, PutBallotError>(_model.getOpinionVotes().putBallot(principal, question_id, date, cursor), func() : OpinionBallot {
        { date = date; answer = cursor; }
      });
    };
      
    public func getCategorizationBallot(caller: Principal, question_id: Nat) : Result<Ballot<CursorArray>, GetBallotError> {
      Result.mapOk(_model.getCategorizationVotes().getBallot(caller, question_id), func(ballot: Ballot<CursorMap>) : Ballot<CursorArray> {
        { date = ballot.date; answer = Utils.trieToArray(ballot.answer); };
      });
    };
      
    public func putCategorizationBallot(principal: Principal, question_id: Nat, date: Time, cursors: CursorArray) : async* Result<CategorizationBallot, PutBallotError> {
      Result.mapOk<(), CategorizationBallot, PutBallotError>(
        await* _model.getCategorizationVotes().putBallot(principal, question_id, date, Utils.arrayToTrie(cursors, Categories.key, Categories.equal)), func() : CategorizationBallot {
          { date = date; answer = cursors; };
        });
    };

    public func getStatusInfo(question_id: Nat) : Result<StatusInfo, ReopenQuestionError> {
      switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { #err(#PrincipalIsAnonymous); };
        case(?question) { #ok(_model.getStatusManager().getCurrent(question_id)); };
      };
    };

    public func getStatusHistory(question_id: Nat) : Result<[(Status, [Time])], ReopenQuestionError> {
      switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { #err(#PrincipalIsAnonymous); };
        case(?question) { #ok(Utils.mapToArray(_model.getStatusManager().getHistory(question_id))); };
      };
    };

    public func revealInterestVote(question_id: Nat, iteration: Nat) : Result<PublicVote<Cursor, Polarization>, RevealVoteError> {
      switch(_model.getInterestVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Votes.toPublicVote(vote)); };
      };
    };

    public func revealOpinionVote(question_id: Nat, iteration: Nat) : Result<PublicVote<Cursor, Polarization>, RevealVoteError> {
      switch(_model.getOpinionVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Votes.toPublicVote(vote)); };
      };
    };

    public func revealCategorizationVote(question_id: Nat, iteration: Nat) : Result<PublicVote<CursorArray, PolarizationArray>, RevealVoteError> {
      switch(_model.getCategorizationVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Categorizations.toPublicVote(vote)); };
      };
    };

    public func getUserConvictions(principal: Principal) : ?PolarizationArray {
      Option.map(_model.getUsers().getUserConvictions(principal), func(convictions: PolarizationMap) : PolarizationArray {
        Utils.trieToArray(convictions);
      });
    };

    public func getUserOpinions(principal: Principal) : ?[(VoteId, PolarizationArray, Ballot<Cursor>)] {
      _model.getUsers().getUserOpinions(principal);
    };

    func verifyCredentials(principal: Principal) : Result<(), VerifyCredentialsError> {
      Result.mapOk<(), (), VerifyCredentialsError>(Utils.toResult(principal == _model.getMaster(), #InsufficientCredentials), (func(){}));
    };

    public func run(time: Time) : async* () {
      for (question in _model.getQuestions().iter()){
        await* submitEvent(question.id, #TIME_UPDATE(#data({time;})), time, StateMachine.initEventResult<Status, TransitionError>());
      };
    };

    func submitEvent(question_id: Nat, event: Event, date: Time, result: Schema.EventResult) : async* () {

      let current = _model.getStatusManager().getCurrent(question_id);

      // Submit the event
      await* StateMachine.submitEvent(_schema, current.status, question_id, event, result);

      switch(result.get()){
        case(#err(_)) {}; // No transition
        case(#ok(new)) {
          // When the question status changes, update the associated key for the #STATUS order_by
          _model.getQueries().replace(
            ?toStatusEntry(question_id, current.status, current.date),
            Option.map(new, func(status: Status) : Key { toStatusEntry(question_id, status, date); })
          );
          // Close vote(s) if any
          switch(current.status){
            case(#CANDIDATE) { 
              await* _model.getInterestVotes().closeVote(question_id);
            };
            case(#OPEN)      { // Update the user convictions on question closed
                               // @todo: watchout, has to be called before the votes are closed
                               _model.getUsers().onClosingQuestion(question_id);
                               _model.getOpinionVotes().closeVote(question_id);
                               await* _model.getCategorizationVotes().closeVote(question_id); 
                             };
            case(_) {};
          };
          switch(new){
            case(null) {
              // Remove status and question
              _model.getStatusManager().deleteStatus(question_id);
              _model.getQuestions().removeQuestion(question_id);
            };
            case(?status){
              // Open a vote if applicable
              switch(status){
                case(#CANDIDATE) { // @todo: the opening of the vote shall be done by the state machine transition
                                  /*ignore await* _model.getInterestVotes().openVote();*/ }; 
                case(#OPEN)      { _model.getOpinionVotes().openVote(question_id);
                                  _model.getCategorizationVotes().openVote(question_id); };
                case(_) {};
              };
              // Finally set the status as current
              _model.getStatusManager().setCurrent(question_id, status, date);
            };
          };
        };
      };
    };

  };

};