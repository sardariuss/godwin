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
  type Duration        = Types.Duration;
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
      StateMachine.addTransition(schema, #CANDIDATE,            ?#REJECTED(#TIMED_OUT),  candidateStatusEnded, [#TIME_UPDATE(#id)    ]);
      StateMachine.addTransition(schema, #CANDIDATE,            ?#REJECTED(#CENSORED),   censored,             [#TIME_UPDATE(#id)    ]);
      StateMachine.addTransition(schema, #CANDIDATE,            ?#OPEN,                  selected,             [#TIME_UPDATE(#id)    ]);
      StateMachine.addTransition(schema, #OPEN,                 ?#CLOSED,                openStatusEnded,      [#TIME_UPDATE(#id)    ]);
      StateMachine.addTransition(schema, #CLOSED,               ?#CANDIDATE,             reopenQuestion,       [#REOPEN_QUESTION(#id)]);
      StateMachine.addTransition(schema, #REJECTED(#TIMED_OUT), ?#CANDIDATE,             reopenQuestion,       [#REOPEN_QUESTION(#id)]);
      StateMachine.addTransition(schema, #REJECTED(#TIMED_OUT), null,                    rejectedStatusEnded,  [#TIME_UPDATE(#id)    ]);
      StateMachine.addTransition(schema, #REJECTED(#CENSORED),  null,                    rejectedStatusEnded,  [#TIME_UPDATE(#id)    ]);
      schema;
    };

    // @todo: dangereous, the result can still be altered after the function returns
    func passedDuration(duration: Duration, question_id: Nat, event: Event, result: TransitionResult) {
      // Get the date of the current status
      let (iteration, status_info) = _model.getStatusManager().getCurrentStatus(question_id);
      // If enough time has passed (candidate_status_duration), perform the transition
      if (unwrapTime(event) < status_info.date + Duration.toTime(duration)){
        result.set(#err(#TooSoon)); return;
      };
      result.set(#ok);
    };

    func candidateStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      passedDuration(_model.getSchedulerParameters().candidate_status_duration, question_id, event, result);
    };
  
    func openStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      passedDuration(_model.getSchedulerParameters().open_status_duration, question_id, event, result);
    };

    func rejectedStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {  
      // Do not delete questions that had been opened at least once
      let (iteration, status_info) = _model.getStatusManager().getCurrentStatus(question_id);
      if (iteration > 1){
        result.set(#err(#WrongStatusIteration));
        return;
      };
      passedDuration(_model.getSchedulerParameters().rejected_status_duration, question_id, event, result);
    };

    func censored(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let time = unwrapTime(event);
      let (iteration, status_info) = _model.getStatusManager().getCurrentStatus(question_id);

      let vote_id = _model.getInterestJoins().getVoteId(question_id, iteration);
      let appeal = _model.getInterestVotes().getVote(vote_id).aggregate;

      if (appeal.score >= 0.0) {
        result.set(#err(#PositiveAppeal)); return;
      };

      let time_score_switch = switch(appeal.last_score_switch){
        case(null){ result.set(#err(#PositiveAppeal)); return; };
        case(?time_switch) { time_switch; };
      };

      if (time < time_score_switch + Duration.toTime(_model.getSchedulerParameters().censor_timeout)){
        result.set(#err(#TooSoon)); return;
      };

      result.set(#ok);
    };

    func selected(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let time = unwrapTime(event);
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
      if (time < _model.getLastPickDate() + Duration.toTime(_model.getSchedulerParameters().question_pick_rate)){
        result.set(#err(#TooSoon)); return;
      };
      // Verify the appeal is positive
      let (iteration, status_info) = _model.getStatusManager().getCurrentStatus(question_id);
      let vote_id = _model.getInterestJoins().getVoteId(question_id, iteration);
      let appeal = _model.getInterestVotes().getVote(vote_id).aggregate;
      if (appeal.score < 0.0) {
        result.set(#err(#NegativeAppeal)); return;
      };
      // Update the last pick date
      _model.setLastPickDate(time);
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
      switch(await* _model.getInterestVotes().openVote(caller, func() : (Question, Nat) { 
          let iteration = _model.getStatusManager().newIteration(question_id);
          (question, iteration);
        })){
        case(#err(err)) { result.set(#err(err)); return; };
        case(#ok(_)) { result.set(#ok); };
      };
    };

    func unwrapTime(event: Event) : Time {
      switch(event){
        case(#TIME_UPDATE(#data({time;}))) { time; };
        case(_) { Debug.trap("Invalid event type"); };
      };
    };

  };

};