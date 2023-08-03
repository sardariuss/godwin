import Event         "Event";
import StatusManager "../StatusManager";
import Types         "../Types";
import Model         "../Model";
import Status        "../questions/Status";
import KeyConverter  "../questions/KeyConverter";
import Interests     "../votes/Interests";
import InterestRules "../votes/InterestRules";
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
  type VoteLink                = Types.VoteLink;
  type Model                   = Model.Model;
  type Event                   = Event.Event;
  
  public type Schema           = StateMachine.Schema<Status, Event, [VoteLink], QuestionId>;
  public type TransitionResult = StateMachine.TransitionResult<[VoteLink]>;
  public type EventResult      = StateMachine.EventResult<Status, [VoteLink]>;

  public class SchemaBuilder(_model: Model) {

    public func build() : Schema {
      let schema = StateMachine.init<Status, Event, [VoteLink], QuestionId>(Status.status_hash, Status.opt_status_hash, Event.event_hash);
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
        await* _model.getInterestVotes().closeVote(_model.getInterestJoins().getVoteId(question_id, status_info.iteration), date, #TIMED_OUT);
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
        _model.getQueries().replace(
          ?KeyConverter.toOpinionVoteKey(question_id, status_info.date, false),
          ?KeyConverter.toOpinionVoteKey(question_id, status_info.date, true));
        result.set(#ok(null));
      });
    };

    func rejectedStatusEnded(question_id: Nat, event: Event, result: TransitionResult) : async* () {  
      // Do not delete questions that had been opened at least once
      // @todo: so this question stays rejected for ever?
      if (Option.isSome(StatusManager.findLastStatusInfo(_model.getStatusManager().getStatusHistory(question_id), #OPEN))){
        result.set(#err("The question had been opened at least once"));
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

      let time_score_switch = switch(appeal.negative_score_date){
        case(null){ result.set(#err("Appeal score has not switched yet")); return; };
        case(?time_switch) { time_switch; };
      };

      if (date < time_score_switch + Duration.toTime(_model.getSchedulerParameters().censor_timeout)){
        result.set(#err("Too soon to get censored")); return;
      };

      // Close the interest vote
      await* _model.getInterestVotes().closeVote(vote_id, date, #CENSORED);

      result.set(#ok(null));
    };

    func selected(question_id: Nat, event: Event, result: TransitionResult) : async* () {
      let date = unwrapTime(event);
      
      // Verify it is the most interesting question
      switch(_model.getQueries().iter(#HOTNESS, #BWD).next()){
        case (null) { result.set(#err("The question is not listed in the #HOTNESS order by queries")); return; };
        case(?most_interesting) {
          if (question_id != most_interesting) {
            result.set(#err("The question is currently not the most interesting question")); return;
          };
        };
      };

      let current_status = _model.getStatusManager().getCurrentStatus(question_id);
      let vote_id = _model.getInterestJoins().getVoteId(question_id, current_status.iteration);
      let appeal = _model.getInterestVotes().getVote(vote_id).aggregate;

      // Verify the score is greater or equal to the required score
      if (appeal.score < _model.getSubMomentum().get().selection_score){
        result.set(#err("The question's score is too low")); return;
      };

      // Close the interest vote
      await* _model.getInterestVotes().closeVote(_model.getInterestJoins().getVoteId(question_id, current_status.iteration), date, #SELECTED);

      // If there was a previous opinion vote, close it
      switch(StatusManager.findLastStatusInfo(_model.getStatusManager().getStatusHistory(question_id), #OPEN)){
        case(null) { /* Nothing to do */ };
        case(?status_info){
          await* _model.getOpinionVotes().closeVote(_model.getOpinionJoins().getVoteId(question_id, status_info.iteration), date);
          // Remove the key for the opinion queries
          _model.getQueries().remove(KeyConverter.toOpinionVoteKey(question_id, status_info.date, true));
        };
      };

      // Open up the opinion and categorization votes
      let opinion_vote_link        = { vote_kind = #OPINION;        vote_id = _model.getOpinionVotes().newVote(date); };
      let categorization_vote_link = { vote_kind = #CATEGORIZATION; vote_id = _model.getCategorizationVotes().newVote(date); };

      // Add the key for the opinion queries
      _model.getQueries().add(KeyConverter.toOpinionVoteKey(question_id, date, false));

      // Update the momentum args
      _model.getSubMomentum().setLastPick(date, appeal);

      // Perform the transition
      result.set(#ok(?[opinion_vote_link, categorization_vote_link]));
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
        case(#err(err)) { result.set(#err("Fail to open interest vote")); }; // @todo: stringify the error
        case(#ok((_, vote_id))) {
          result.set(#ok(?[{ vote_kind = #INTEREST; vote_id; }])); 
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