import Questions "../Questions";
import Types "../Types";
import Model "Model";
import Schema "Schema";
import Event "Event";
import History "../History";

import StateMachine "../../utils/StateMachine";
import Observers "../../utils/Observers";

import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

module {

  type Time = Int;
  type Iter<T> = Iter.Iter<T>;

  type Question = Types.Question;
  type Status = Types.Status;
  type Questions = Questions.Questions;
  type History = History.History;

  type Model = Model.Model;
  type Event = Event.Event;
  type Schema = Schema.Schema;
  
  public type Callback = (?Question, ?Question) -> ();

  public func build(model: Model, questions: Questions) : Controller {
    Controller(Schema.SchemaBuilder(model).build(), model, questions);
  };

  public class Controller(schema_: Schema, model_: Model, questions_: Questions) = {

    let observers_ = Observers.Observers2<Question>();

    public func run(date: Time, most_interesting: ?Nat) {
      model_.setTime(date);
      model_.setMostInteresting(most_interesting);
      for (question in questions_.iter()){
        submitEvent(question, #TIME_UPDATE, date);
      };
    };

    // @todo: to be able to pass the question creation through the validation of the state machine,
    // we need to create a new question with the status #START and then update it with the status #CANDIDATE.
    // Same thing for the #END status (instead of #TRASH)
    public func openQuestion(author: Principal, date: Int, text: Text) : Question { 
      let question = questions_.createQuestion(author, date, text);
      observers_.callObs(null, ?question);
      question;
    };

    public func reopenQuestion(question: Question, date: Time) {
      submitEvent(question, #REOPEN_QUESTION, date);
    };

    public func addObs(callback: Callback) {
      observers_.addObs(callback);
    };

    func submitEvent(question: Question, event: Event, date: Time) {

      let state_machine = {
        schema = schema_;
        model = question;
        var current = question.status_info.status;
      };
      
      Option.iterate(StateMachine.submitEvent(state_machine, event), func(status: Status) {
        let question_updated = switch(status) {
          case(#TRASH) {
            // @todo: the votes need to be removed too
            // Remove the question if it is in the trash
            questions_.removeQuestion(question.id); 
            null; 
          };
          case(_) {
            // Update the question status
            let iteration = model_.getStatusIteration(question.id, status);
            let update = { question with status_info = { status; iteration; date; } };
            questions_.replaceQuestion(update);
            ?update;
          };
        };
        // Notify the observers
        observers_.callObs(?question, question_updated);
      });
    };

  };

};