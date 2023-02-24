import StatusHelper "../StatusHelper";
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

  public class SchemaBuilder(model_: Model) {

    public func build() : Schema {
      let schema = StateMachine.init<Status, Event, Question>(StatusHelper.status_hash, Event.event_hash);
      StateMachine.addTransition(schema, #CANDIDATE,       #REJECTED,                timedOutFirstIteration, [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CANDIDATE,       #CLOSED,                  timedOutNextIterations, [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #REJECTED,                #TRASH,                   timedOut,               [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CANDIDATE,       #OPEN,        tickMostInteresting,    [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #OPEN,        #CLOSED,                  timedOut,               [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CLOSED,                  #CANDIDATE,       passThrough,            [#REOPEN_QUESTION]);
      schema;
    };

    func timedOutFirstIteration(question: Question) : Bool {
      question.status_info.current.index == 0 and timedOut(question);
    };

    func timedOutNextIterations(question: Question) : Bool {
      let indexed_status = question.status_info.current;
      question.status_info.current.index > 0 and timedOut(question);
    };

    func tickMostInteresting(question: Question) : Bool {
      Option.getMapped(
        model_.getMostInteresting(),
        func(question_id: Nat) : Bool {
          if (question_id == question.id) {
            if (model_.getTime() > model_.getLastPickDate() + Duration.toTime(model_.getInterestPickRate())){
              // Update the last pick date
              model_.setLastPickDate(model_.getTime());
              return true;
            };
          };
          false;
        },
        false
      );
    };

    func timedOut(question: Question) : Bool {
      let indexed_status = question.status_info.current;
      model_.getTime() > indexed_status.date + Duration.toTime(model_.getStatusDuration(indexed_status.status));
    };

    func passThrough(question: Question) : Bool {
      true;
    };

  };

};