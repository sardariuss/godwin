import Event         "Event";
import StatusManager "../StatusManager";
import Model         "../Model";
import Status        "../questions/Status";
import KeyConverter  "../questions/KeyConverter";
import Types         "../../stable/Types";

import Duration      "../../utils/Duration";
import StateMachine  "../../utils/StateMachine";

import Option        "mo:base/Option";
import Principal     "mo:base/Principal";
import Debug         "mo:base/Debug";

module {

  type Time                    = Int;
  type Duration                = Types.Current.Duration;
  type Question                = Types.Current.Question;
  type Status                  = Types.Current.Status;
  type QuestionId              = Types.Current.QuestionId;
  type VoteId                  = Types.Current.VoteId;
  type VoteLink                = Types.Current.VoteLink;
  type StatusInfo              = Types.Current.StatusInfo;
  type Key                     = Types.Current.Key;
  type Model                   = Model.Model;
  type Event                   = Event.Event;
  
  public type Schema           = StateMachine.Schema<Status, Event, QuestionId>;

  public class SchemaBuilder(_model: Model) {

    public func build() : Schema {
      let schema = StateMachine.init<Status, Event, QuestionId>(Status.status_hash, Status.opt_status_hash, Event.event_hash);
      StateMachine.addTransition(schema, #CANDIDATE,            ?#REJECTED(#TIMED_OUT),  candidateStatusEnded, [#TIME_UPDATE    ]);
      StateMachine.addTransition(schema, #CANDIDATE,            ?#REJECTED(#CENSORED),   censored,             [#TIME_UPDATE    ]);
      StateMachine.addTransition(schema, #CANDIDATE,            ?#OPEN,                  selected,             [#TIME_UPDATE    ]);
      StateMachine.addTransition(schema, #OPEN,                 ?#CLOSED,                openStatusEnded,      [#TIME_UPDATE    ]);
      StateMachine.addTransition(schema, #CLOSED,               ?#CANDIDATE,             reopenQuestion,       [#REOPEN_QUESTION]);
      StateMachine.addTransition(schema, #REJECTED(#TIMED_OUT), ?#CANDIDATE,             reopenQuestion,       [#REOPEN_QUESTION]);
      StateMachine.addTransition(schema, #REJECTED(#TIMED_OUT), null,                    rejectedStatusEnded,  [#TIME_UPDATE    ]);
      StateMachine.addTransition(schema, #REJECTED(#CENSORED),  null,                    rejectedStatusEnded,  [#TIME_UPDATE    ]);
      schema;
    };

    func passedDuration(question_id: Nat, date: Time) : Bool {
      // If enough time has passed, perform the transition
      switch(_model.getStatusManager().endingDate(question_id, _model.getSchedulerParameters())){
        case(null)         { false;                   };
        case(?ending_date) { ending_date - date <= 0; };
      };
    };

    func transition(question_id: Nat, date: Time, next: ?Status) : async*() {
      let (_, status_info) = _model.getStatusManager().getCurrentStatus(question_id);

      // Close the current vote(s) if applicable
      switch(status_info.status){
        case(#CANDIDATE){
          let closure = switch(next){
            case(?#OPEN)                 { #SELECTED;  };
            case(?#REJECTED(#CENSORED))  { #CENSORED;  };
            case(?#REJECTED(#TIMED_OUT)) { #TIMED_OUT; };
            case(_)                      { Debug.trap("@todo"); };
          };
          // Close the interest vote
          await* _model.getInterestVotes().closeVote(_model.getInterestJoins().getVoteId(question_id, status_info.iteration), date, closure);
        };
        case(#OPEN){
          // Lock up the opinion vote and put the is_late flag to true for the opinion queries
          _model.getOpinionVotes().lockVote(_model.getOpinionJoins().getVoteId(question_id, status_info.iteration), date);
          _model.getQueries().replace(
            ?KeyConverter.toOpinionVoteKey(question_id, status_info.date, false),
            ?KeyConverter.toOpinionVoteKey(question_id, status_info.date, true));
          // Close the categorization vote
          await* _model.getCategorizationVotes().closeVote(_model.getCategorizationJoins().getVoteId(question_id, status_info.iteration), date);
        };
        case(_){
        };
      };

      // Update the queries, need to be done before setting up the new status!
      updateQueries(question_id, status_info, next, date);

      // Open up new votes(s) if applicable
      switch(next){
        case(null) {
          // Remove status history and question
          _model.getStatusManager().removeStatusHistory(question_id);
          _model.getQuestions().removeQuestion(question_id);
        };
        case(?status) {
          let votes = switch(status){
            case(#OPEN){
              // If there was a previous opinion vote, close it
              switch(_model.getStatusManager().findLastStatusInfo(question_id, #OPEN)){
                case(null) { /* Nothing to do */ };
                case(?(_, { iteration; date; })){
                  await* _model.getOpinionVotes().closeVote(_model.getOpinionJoins().getVoteId(question_id, iteration), date);
                  // Remove the key for the opinion queries
                  _model.getQueries().remove(KeyConverter.toOpinionVoteKey(question_id, date, true));
                };
              };
              // Add the key for the opinion queries
              _model.getQueries().add(KeyConverter.toOpinionVoteKey(question_id, date, false));
              // Open up the opinion and categorization votes
              [ 
                { vote_kind = #OPINION;        vote_id = _model.getOpinionVotes().newVote(date); },
                { vote_kind = #CATEGORIZATION; vote_id = _model.getCategorizationVotes().newVote(date); } 
              ];
            };
            case(_) { []; }; // The interest vote is processed directly in the reopenQuestion transition
          };
          // Finally set the new status
          ignore _model.getStatusManager().setCurrentStatus(question_id, status, date, votes);
        };
      };
    };

    func updateQueries(question_id: Nat, old: StatusInfo, new: ?Status, date: Time) {
      let previous_closed_status = _model.getStatusManager().findLastStatusInfo(question_id, #CLOSED);
      // Remove the associated key for the #STATUS order_by
      _model.getQueries().remove(KeyConverter.toStatusKey(question_id, old.status, old.date));
      // Remove the old associated key for the #TRASH order_by if applicable
      if (old.status == #REJECTED(#TIMED_OUT) or old.status == #REJECTED(#CENSORED)){
        // The key will only exist if there was no previous closed status
        if (Option.isNull(previous_closed_status)){
          _model.getQueries().remove(KeyConverter.toTrashKey(question_id, old.date));
        };
      };

      Option.iterate(new, func(status : Status){
        // Add the associated key for the #STATUS order_by
        _model.getQueries().add(KeyConverter.toStatusKey(question_id, status, date));
        // Update the associated key for the #ARCHIVE order_by if applicable
        if (status == #CLOSED){
          let previous_key = Option.map(previous_closed_status, func((_, status_info) : (Nat, StatusInfo)) : Key {
            KeyConverter.toArchiveKey(question_id, status_info.date);
          });
          _model.getQueries().replace(previous_key, ?KeyConverter.toArchiveKey(question_id, date));
        };
        // Add a new associated key for the #TRASH order_by if applicable
        if (status == #REJECTED(#TIMED_OUT) or status == #REJECTED(#CENSORED)){
          // Only add if there is no previous closed status
          if (Option.isNull(previous_closed_status)){
            _model.getQueries().add(KeyConverter.toTrashKey(question_id, date));
          };
        };
      });
    };

    func candidateStatusEnded(question_id: Nat, date: Time, caller: Principal, next: ?Status) : async* Bool {
      // Verify if enough time has passed
      if (not passedDuration(question_id, date)) {
        return false;
      };
      // Perform the transition
      await* transition(question_id, date, next);
      true;
    };
  
    func openStatusEnded(question_id: Nat, date: Time, caller: Principal, next: ?Status) : async* Bool {
      // Verify if enough time has passed
      if (not passedDuration(question_id, date)) {
        return false;
      };
      // Perform the transition
      await* transition(question_id, date, next);
      true;
    };

    func rejectedStatusEnded(question_id: Nat, date: Time, caller: Principal, next: ?Status) : async* Bool {
      // Verify if enough time has passed
      if (not passedDuration(question_id, date)) {
        return false;
      };
      // Perform the transition
      await* transition(question_id, date, next);
      true;
    };

    func censored(question_id: Nat, date: Time, caller: Principal, next: ?Status) : async* Bool {
      let (_, status_info) = _model.getStatusManager().getCurrentStatus(question_id);
      let vote_id = _model.getInterestJoins().getVoteId(question_id, status_info.iteration);
      let appeal = _model.getInterestVotes().getVote(vote_id).aggregate;
      // If the appeal score is positive, no need to censor
      if (appeal.score >= 0.0) {
        return false; 
      };
      // If the appeal score has not switched yet, no need to censor
      let time_score_switch = switch(appeal.negative_score_date){
        case(null){ return false; }; 
        case(?time_switch) { time_switch; };
      };
      // Verify if enough time has passed
      if (date < time_score_switch + Duration.toTime(_model.getSchedulerParameters().censor_timeout)){
        return false; 
      };
      // Perform the transition
      await* transition(question_id, date, next);
      true;
    };

    func selected(question_id: Nat, date: Time, caller: Principal, next: ?Status) : async* Bool {
      // Verify it is the most interesting question
      switch(_model.getQueries().iter(#HOTNESS, #BWD).next()){
        case (null) { return false; }; //The question is not listed in the #HOTNESS order by queries
        case(?most_interesting) {
          if (question_id != most_interesting) {
            return false; // The question is not the current most interesting question
          };
        };
      };

      let (_, current_status) = _model.getStatusManager().getCurrentStatus(question_id);
      let vote_id = _model.getInterestJoins().getVoteId(question_id, current_status.iteration);
      let appeal = _model.getInterestVotes().getVote(vote_id).aggregate;

      // Verify the score is greater or equal to the required score
      if (appeal.score < _model.getSubMomentum().get().selection_score){
        return false; // The question's score is too low
      };

      // Update the momentum args
      _model.getSubMomentum().setLastPick(date, appeal);

      // Perform the transition
      await* transition(question_id, date, next);
      true;
    };

    func reopenQuestion(question_id: Nat, date: Time, caller: Principal, next: ?Status) : async* Bool {
      // Verify that the caller is not anonymous
      if (Principal.isAnonymous(caller)){
        return false;
      };
      // Verify that the question exists
      let question = switch(_model.getQuestions().findQuestion(question_id)){
        case(null)      { return false; };
        case(?question) { question;     };
      };
      // Verify that the interest vote successfully opens
      // @todo: risk of reentry, user will loose tokens if the question has already been reopened
      switch(await* _model.getInterestVotes().openVote(caller, date, func(VoteId) : QuestionId { question.id; })){
        case(#err(err)) { return false; };
        case(#ok((_, vote_id))) {
          // @todo: explanation
          // Update the queries, need to be done before setting up the new status!
          updateQueries(question_id, _model.getStatusManager().getCurrentStatus(question_id).1, next, date);
          // Update the status
          ignore _model.getStatusManager().setCurrentStatus(question_id, #CANDIDATE, date, [{ vote_kind = #INTEREST; vote_id; }]);
          // Success
          return true;
        };
      };
    };

  };

};