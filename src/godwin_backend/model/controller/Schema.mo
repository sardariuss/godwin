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

  public class SchemaBuilder(model_: Model, get_status_index_: (Nat, Status) -> Nat) {

    public func build() : Schema {
      let schema = StateMachine.init<Status, Event, Question>(Status.status_hash, Event.event_hash);
      StateMachine.addTransition(schema, #CANDIDATE, #REJECTED,  timedOutFirstIteration, [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CANDIDATE, #CLOSED,    timedOutNextIterations, [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #REJECTED,  #TRASH,     timedOut,               [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CANDIDATE, #OPEN,      tickMostInteresting,    [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #OPEN,      #CLOSED,    timedOut,               [#TIME_UPDATE]);
      StateMachine.addTransition(schema, #CLOSED,    #CANDIDATE, passThrough,            [#REOPEN_QUESTION]);
      schema;
    };

    func timedOutFirstIteration(question: Question) : Bool {
      get_status_index_(question.id, #CANDIDATE) == 0 and timedOut(question);
    };

    func timedOutNextIterations(question: Question) : Bool {
      get_status_index_(question.id, #CANDIDATE) > 0 and timedOut(question);
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
      model_.getTime() > question.status_info.date + Duration.toTime(model_.getStatusDuration(question.status_info.status));
    };

    func passThrough(question: Question) : Bool {
      true;
    };

  };

};