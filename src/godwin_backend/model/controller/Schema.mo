import Status "../Status";
import Duration "../../utils/Duration";
import Types "../Types";
import Model "Model";
import Event "Event";

import StateMachine "../../utils/StateMachine";

import Option "mo:base/Option";

module {

  type Time = Int;
  type Question = Types.Question;
  type Status = Types.Status;
  type Model = Model.Model;
  type Event = Event.Event;
  
  public type Schema = StateMachine.Schema<Status, Event, Question>;

  public class SchemaBuilder(_model: Model) {

    public func build() : Schema {
      let schema = StateMachine.init<Status, Event, Question>(Status.status_hash, Status.opt_status_hash, Event.event_hash);
      StateMachine.addTransition(schema, #CANDIDATE, ?#REJECTED,  timedOutFirstIteration, [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CANDIDATE, ?#CLOSED,    timedOutNextIterations, [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #REJECTED,  null,        timedOut,               [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CANDIDATE, ?#OPEN,      tickMostInteresting,    [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #OPEN,      ?#CLOSED,    timedOut,               [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CLOSED,    ?#CANDIDATE, passThrough,            [#REOPEN_QUESTION]);
      schema;
    };

    func timedOutFirstIteration(question: Question) : Bool {
      _model.getStatusManager().getStatusIteration(question.id, #CANDIDATE) == 0 and timedOut(question);
    };

    func timedOutNextIterations(question: Question) : Bool {
      _model.getStatusManager().getStatusIteration(question.id, #CANDIDATE) > 0 and timedOut(question);
    };

    func tickMostInteresting(question: Question) : Bool {
      Option.getMapped(
        _model.getQueries().iter(#INTEREST_SCORE, #FWD).next(),
        func(question_id: Nat) : Bool {
          if (question_id == question.id) {
            if (_model.getTime() > _model.getLastPickDate() + Duration.toTime(_model.getInterestPickRate())){
              // Update the last pick date
              _model.setLastPickDate(_model.getTime());
              return true;
            };
          };
          false;
        },
        false
      );
    };

    func timedOut(question: Question) : Bool {
      let status_info = _model.getStatusManager().getCurrent(question.id);
      _model.getTime() > status_info.date + Duration.toTime(_model.getStatusDuration(status_info.status));
    };

    func passThrough(question: Question) : Bool {
      true;
    };

  };

};