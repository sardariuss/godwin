import Event         "Event";
import Types         "../Types";
import Model         "../Model";
import Status        "../questions/Status";
import StatusManager "../questions/StatusManager";

import Duration      "../../utils/Duration";
import StateMachine  "../../utils/StateMachine";

import Option        "mo:base/Option";
import Debug         "mo:base/Debug";
import Principal     "mo:base/Principal";

module {

  type Time            = Int;
  type Question        = Types.Question;
  type Status          = Types.Status;
  type Model           = Model.Model;
  type Event           = Event.Event;
  type QuestionId      = Types.QuestionId;
  type TransitionError = Types.TransitionError;
  
  public type Schema           = StateMachine.Schema<Status, Event, TransitionError, QuestionId>;
  public type TransitionResult = StateMachine.TransitionResult<TransitionError>;
  public type EventResult      = StateMachine.EventResult<Status, TransitionError>;

  public class SchemaBuilder(_model: Model) {

    public func build() : Schema {
      let schema = StateMachine.init<Status, Event, TransitionError, QuestionId>(Status.status_hash, Status.opt_status_hash, Event.event_hash);
      StateMachine.addTransition(schema, #CANDIDATE, ?#REJECTED,  timedOutFirstIteration, [#TIME_UPDATE(#id)]);
      StateMachine.addTransition(schema, #CANDIDATE, ?#CLOSED,    timedOutNextIterations, [#TIME_UPDATE(#id)]);
      StateMachine.addTransition(schema, #REJECTED,  null,        timedOut,               [#TIME_UPDATE(#id)]);
      StateMachine.addTransition(schema, #CANDIDATE, ?#OPEN,      tickMostInteresting,    [#TIME_UPDATE(#id)]);
      StateMachine.addTransition(schema, #OPEN,      ?#CLOSED,    timedOut,               [#TIME_UPDATE(#id)]);
      StateMachine.addTransition(schema, #CLOSED,    ?#CANDIDATE, reopenQuestion,         [#REOPEN_QUESTION(#id)]);
      schema;
    };

    func timedOutFirstIteration(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      if (StatusManager.getStatusIteration(_model.getStatusManager().getHistory(question_id), #CANDIDATE) != 0){
        result.set(#err(#WrongStatusIteration));
        return;
      };
      await* timedOut(question_id, event, result);
    };

    func timedOutNextIterations(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      if (StatusManager.getStatusIteration(_model.getStatusManager().getHistory(question_id), #CANDIDATE) == 0){
        result.set(#err(#WrongStatusIteration));
        return;
      };
      await* timedOut(question_id, event, result);
    };

    func tickMostInteresting(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let time = switch(event){
        case(#TIME_UPDATE(#data({time;}))) { time; };
        case(_) { Debug.trap("Invalid event type"); };
      };
      // Get the most interesting question
      let most_interesting = switch(_model.getQueries().iter(#INTEREST_SCORE, #BWD).next()){
        case (null) { result.set(#err(#EmptyQueryInterestScore)); return; };
        case(?question_id) { question_id; };
      };
      // Verify it is the current question
      if (most_interesting != question_id) {
        result.set(#err(#NotMostInteresting)); return;
      };
      // Verify the time is greater than the last pick date
      if (time < _model.getLastPickDate() + Duration.toTime(_model.getInterestPickRate())){
        result.set(#err(#TooSoon)); return;
      };
      // Perform the transition
      result.set(#ok);
      // Update the last pick date
      _model.setLastPickDate(time);
    };

    func timedOut(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let time = switch(event){
        case(#TIME_UPDATE(#data({time}))) { time; };
        case(_) { Debug.trap("Invalid event type"); };
      };
      let status_info = _model.getStatusManager().getCurrent(question_id);
      if (time < status_info.date + Duration.toTime(_model.getStatusDuration(status_info.status))){
        result.set(#err(#TooSoon)); return;
      };
      // Perform the transition
      result.set(#ok);
    };

    func reopenQuestion(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let caller = switch(event){
        case(#REOPEN_QUESTION(#data({caller}))) { caller; };
        case(_) { Debug.trap("Invalid event type"); };
      };
      // Verify that the caller is not anonymous
      if (Principal.isAnonymous(caller)){
        result.set(#err(#PrincipalIsAnonymous)); return;
      };
      // Verify that the question exists
      let question = switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { result.set(#err(#QuestionNotFound)); return; };
        case(?question) { question; };
      };
      // @todo: risk of reentry, user will loose tokens if the question has already been reopened
      switch(await* _model.getInterestVotes().openVote(caller, func() : Question { question; })){
        case(#err(err)) { result.set(#err(err)); return; };
        case(#ok(_)) { result.set(#ok); };
      };
    };

  };

};