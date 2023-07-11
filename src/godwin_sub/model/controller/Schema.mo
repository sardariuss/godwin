import Event         "Event";
import Types         "../Types";
import Model         "../Model";
import Status        "../questions/Status";
import StatusManager "../questions/StatusManager";
import KeyConverter  "../questions/KeyConverter";
import Interests     "../votes/Interests";
import Opinions      "../votes/Opinions";

import Duration      "../../utils/Duration";
import StateMachine  "../../utils/StateMachine";

import Option        "mo:base/Option";
import Debug         "mo:base/Debug";
import Principal     "mo:base/Principal";
import Float         "mo:base/Float";

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
    func passedDuration(duration: Duration, question_id: Nat, date: Time, result: TransitionResult, on_passed: (TransitionResult) -> async* ()) : async* () {
      // Get the date of the current status
      let status_info = _model.getStatusManager().getCurrentStatus(question_id);
      // If enough time has passed (candidate_status_duration), perform the transition
      if (date < status_info.date + Duration.toTime(duration)){
        result.set(#err("Too soon to go to next status")); return;
      };
      await* on_passed(result);
    };

    func candidateStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let date = unwrapTime(event);
      await* passedDuration(_model.getSchedulerParameters().candidate_status_duration, question_id, date, result, func(result: TransitionResult) : async* () {
        let status_info = _model.getStatusManager().getCurrentStatus(question_id);
        // Close the interest vote
        await* _model.getInterestVotes().closeVote(_model.getInterestJoins().getVoteId(question_id, status_info.iteration), date);
        // Perform the transition
        result.set(#ok(null));
      });
    };
  
    func openStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let date = unwrapTime(event);
      await* passedDuration(_model.getSchedulerParameters().open_status_duration, question_id, date, result, func(result: TransitionResult): async* () {
        let status_info = _model.getStatusManager().getCurrentStatus(question_id);
        // Lock up the opinion vote
        _model.getOpinionVotes().lockVote(_model.getOpinionJoins().getVoteId(question_id, status_info.iteration), date);
        // Close the categorization vote
        await* _model.getCategorizationVotes().closeVote(_model.getCategorizationJoins().getVoteId(question_id, status_info.iteration), date);
        // Update the key for the opinion queries
        let previous_key = KeyConverter.toOpinionVoteKey(question_id, status_info.date, false);
        _model.getQueries().replace(
          ?previous_key,
          ?KeyConverter.toOpinionVoteKey(question_id, unwrapTime(event), true));
        result.set(#ok(null));
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
      await* passedDuration(_model.getSchedulerParameters().rejected_status_duration, question_id, date, result, func(result: TransitionResult) : async* () {
        result.set(#ok(null));
      });
    };

    func censored(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let date = unwrapTime(event);
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

      if (date < time_score_switch + Duration.toTime(_model.getSchedulerParameters().censor_timeout)){
        result.set(#err("Too soon to get censored")); return;
      };

      // Close the interest vote
      await* _model.getInterestVotes().closeVote(vote_id, date);

      result.set(#ok(null));
    };

    func selected(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let date = unwrapTime(event);
      
      // Verify it is the most interesting question
      switch(_model.getQueries().iter(#INTEREST_SCORE, #BWD).next()){
        case (null) { result.set(#err("The question is not listed in the #INTEREST_SCORE order by queries")); return; };
        case(?most_interesting) {
          if (question_id != most_interesting) {
            result.set(#err("The question is currently not the most interesting question")); return;
          };
        };
      };

      let status_info = _model.getStatusManager().getCurrentStatus(question_id);
      let vote_id = _model.getInterestJoins().getVoteId(question_id, status_info.iteration);
      let question_score = _model.getInterestVotes().getVote(vote_id).aggregate.score;

      // Verify the score is positive
      if (question_score < 0.0) {
        result.set(#err("The question's score is negative")); return;
      };

      let momentum_args = _model.getMomentumArgs();

      // Verify the score is greater or equal to the required score
      if (question_score < Interests.computeSelectionScore(momentum_args, Duration.toTime(_model.getSchedulerParameters().question_pick_rate), date)){
        result.set(#err("The question's score is too low")); return;
      };

      // Close the interest vote
      await* _model.getInterestVotes().closeVote(_model.getInterestJoins().getVoteId(question_id, status_info.iteration), date);

      // If it is not the first iteration, close the previous opinion vote
      if (status_info.iteration > 0){
        switch(StatusManager.findLastStatusInfo(_model.getStatusManager().getStatusHistory(question_id), #OPEN)){
          case(null) { Debug.trap("If this is not the first selection, the history shall already contain an OPEN status"); };
          case(?status_info){
            await* _model.getOpinionVotes().closeVote(_model.getOpinionJoins().getVoteId(question_id, status_info.iteration), date);
            // Remove the key for the opinion queries
            _model.getQueries().remove(KeyConverter.toOpinionVoteKey(question_id, status_info.date, true));
          };
        };
      };

      // Open up the opinion and categorization votes
      let opinion_vote_id        = _model.getOpinionVotes().newVote(date);
      let categorization_vote_id = _model.getCategorizationVotes().newVote(date);

      // Add the key for the opinion queries
      _model.getQueries().add(KeyConverter.toOpinionVoteKey(question_id, date, false));

      // Update the momentum args
      _model.setMomentumArgs({
        last_pick_date = date;
        last_pick_score = question_score;
        num_votes_opened = momentum_args.num_votes_opened + 1;
        minimum_score = momentum_args.minimum_score;
      });

      // Perform the transition
      result.set(#ok(?#CURSOR_VOTES({ opinion_vote_id; categorization_vote_id; } )));
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