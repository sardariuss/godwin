import Event         "Event";
import Types         "../Types";
import Model         "../Model";
import Status        "../questions/Status";
import StatusManager "../questions/StatusManager";
import KeyConverter  "../questions/KeyConverter";

import Duration      "../../utils/Duration";
import StateMachine  "../../utils/StateMachine";

import Option        "mo:base/Option";
import Debug         "mo:base/Debug";
import Principal     "mo:base/Principal";

module {

  type Time                    = Int;
  type Duration                = Types.Duration;
  type Question                = Types.Question;
  type Status                  = Types.Status;
  type QuestionId              = Types.QuestionId;
  type VoteId                  = Types.VoteId;
  type StatusInput             = Types.StatusInput;
  type Model                   = Model.Model;
  type Event                   = Event.Event;
  
  public type Schema           = StateMachine.Schema<Status, Event, StatusInput, QuestionId>;
  public type TransitionResult = StateMachine.TransitionResult<StatusInput>;
  public type EventResult      = StateMachine.EventResult<Status, StatusInput>;

  public class SchemaBuilder(_model: Model) {

    public func build() : Schema {
      let schema = StateMachine.init<Status, Event, StatusInput, QuestionId>(Status.status_hash, Status.opt_status_hash, Event.event_hash);
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
    func passedDuration(duration: Duration, question_id: Nat, date: Time, result: TransitionResult, on_passed: (TransitionResult) -> ()) {
      // Get the date of the current status
      let status_info = _model.getStatusManager().getCurrentStatus(question_id);
      // If enough time has passed (candidate_status_duration), perform the transition
      if (date < status_info.date + Duration.toTime(duration)){
        result.set(#err("Too soon to go to next status")); return;
      };
      on_passed(result);
    };

    func candidateStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let date = unwrapTime(event);
      passedDuration(_model.getSchedulerParameters().candidate_status_duration, question_id, date, result, func(result: TransitionResult) {
        result.set(#ok(null));
      });
    };
  
    func openStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let date = unwrapTime(event);
      passedDuration(_model.getSchedulerParameters().open_status_duration, question_id, date, result, func(result: TransitionResult) {
        // Open up early votes for the next iteration
        // Find the old key
        let current = _model.getStatusManager().getCurrentStatus(question_id);
        let previous_key = if (current.iteration == 0){
          KeyConverter.toOpinionVoteKey(question_id, current.date, false);
        } else {
          switch(_model.getStatusManager().findStatusInfo(question_id, #CLOSED, current.iteration - 1)){
            case(null){ Debug.trap("Could not find previous CLOSED status"); };
            case(?status_info){ KeyConverter.toOpinionVoteKey(question_id, status_info.date, true); };
          };
        };
        _model.getQueries().replace(
          ?previous_key,
          ?KeyConverter.toOpinionVoteKey(question_id, unwrapTime(event), true));
        result.set(#ok(?#CURSOR_VOTES({ 
          opinion_vote_id        = _model.getOpinionVotes().newVote(date);
          categorization_vote_id = _model.getCategorizationVotes().newVote(date);
        })));
      });
    };

    func rejectedStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {  
      // Do not delete questions that had been opened at least once
      let status_info = _model.getStatusManager().getCurrentStatus(question_id);
      if (status_info.iteration > 1){
        result.set(#err("Question had been opened at least once"));
        return;
      };
      let date = unwrapTime(event);
      passedDuration(_model.getSchedulerParameters().rejected_status_duration, question_id, date, result, func(result: TransitionResult) {
        result.set(#ok(null));
      });
    };

    func censored(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let time = unwrapTime(event);
      let status_info = _model.getStatusManager().getCurrentStatus(question_id);

      let vote_id = _model.getInterestJoins().getVoteId(question_id, status_info.iteration);
      let appeal = _model.getInterestVotes().getVote(vote_id).aggregate;

      if (appeal.score >= 0.0) {
        result.set(#err("Appeal score is positive")); return;
      };

      let time_score_switch = switch(appeal.last_score_switch){
        case(null){ result.set(#err("Appeal score has not switched yet")); return; };
        case(?time_switch) { time_switch; };
      };

      if (time < time_score_switch + Duration.toTime(_model.getSchedulerParameters().censor_timeout)){
        result.set(#err("Too soon to get censored")); return;
      };

      result.set(#ok(null));
    };

    func selected(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let date = unwrapTime(event);
      // Get the most interesting question
      let most_interesting = switch(_model.getQueries().iter(#INTEREST_SCORE, #BWD).next()){
        case (null) { result.set(#err("Not listed in interest queries")); return; };
        case(?question_id) { question_id; };
      };
      // Verify it is the current question
      if (most_interesting != question_id) {
        result.set(#err("Not the most interesting question")); return;
      };
      // Verify the time is greater than the last pick date
      if (date < _model.getLastPickDate() + Duration.toTime(_model.getSchedulerParameters().question_pick_rate)){
        result.set(#err("Too soon to get selected")); return;
      };
      // Verify the appeal is positive
      let status_info = _model.getStatusManager().getCurrentStatus(question_id);
      let vote_id = _model.getInterestJoins().getVoteId(question_id, status_info.iteration);
      let appeal = _model.getInterestVotes().getVote(vote_id).aggregate;
      if (appeal.score < 0.0) {
        result.set(#err("Cannot select a question with negative appeal")); return;
      };
      // Update the last pick date
      _model.setLastPickDate(date);
      // If it is the first iteration, open up the cursor votes, 
      // otherwise they already have been opened early
      let cursor_votes = if (status_info.iteration == 0){
        // Add to opinion vote queries
        _model.getQueries().add(KeyConverter.toOpinionVoteKey(question_id, date, false));
        // Open up the votes
        ?#CURSOR_VOTES({ 
          opinion_vote_id        = _model.getOpinionVotes().newVote(date);
          categorization_vote_id = _model.getCategorizationVotes().newVote(date);
        });
      } else {
        null;
      };
      // Perform the transition
      result.set(#ok(cursor_votes));
    };

    func reopenQuestion(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let {date; caller;} = switch(event){
        case(#REOPEN_QUESTION(#data(data))) { data; };
        case(_) { Debug.trap("Invalid event type"); };
      };
      // Verify that the caller is not anonymous
      if (Principal.isAnonymous(caller)){
        result.set(#err("Principal is anonymous")); return;
      };
      // Verify that the question exists
      let question = switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { result.set(#err("Question not found")); return; };
        case(?question) { question; };
      };
      // @todo: risk of reentry, user will loose tokens if the question has already been reopened
      switch(await* _model.getInterestVotes().openVote(caller, date, func(VoteId) : QuestionId { question.id; })){
        case(#err(err)) { result.set(#err("Fail to open interest vote")); };
        case(#ok((_, vote_id))) {
          result.set(#ok(?#INTEREST_VOTE(vote_id))); 
        };
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