import Questions "../Questions";
import Types "../Types";
import Polls "../votes/Polls";
import Model "Model";
import Schema "Schema";
import Event "Event";

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
  type Polls = Polls.Polls;

  type Model = Model.Model;
  type Event = Event.Event;
  type Schema = Schema.Schema;

  type Callback = (?Question, ?Question) -> ();

  public func build(schema: Schema, model: Model, questions: Questions, polls: Polls) : Controller {

    let controller = Controller(schema, model, questions);

    controller.addObserver(func(old: ?Question, new: ?Question) {
      Option.iterate(new, func(question: Question) {
        let indexed_status = question.status_info.current;
        switch(indexed_status.status){
          case(#VOTING(poll)){
            // Open the vote
            polls.openVote(question, poll);
            if (poll == #OPINION){
              // Update the last pick
              model.setLastPickDate(indexed_status.date);
            };
          };
          case(#TRASH){
            // Remove the question
            questions.removeQuestion(question.id);
          };
          case(_) {};
        };
      });
    });

    controller;
  };

  public class Controller(schema_: Schema, model_: Model, questions_: Questions) = {

    let observers_ = Buffer.Buffer<Callback>(0);

    public func run(questions: Iter<Question>, time: Time, most_interesting: ?Nat) {
      model_.setTime(time);
      model_.setMostInteresting(most_interesting);
      for (question in questions){
        submitEvent(question, #TIME_UPDATE, time);
      };
    };

    public func reopenQuestion(question: Question, time: Time) {
      submitEvent(question, #REOPEN_QUESTION, time);
    };

    public func addObserver(callback: Callback) {
      observers_.add(callback);
    };

    func submitEvent(question: Question, event: Event, time: Time) {

      let current = question.status_info.current.status;
      
      let state_machine = {
        schema = schema_;
        model = question;
        var current = current;
      };
      
      Option.iterate(StateMachine.submitEvent(state_machine, event), func(status: Status) {
        // Update the question status
        let updated_question = questions_.updateStatus(question.id, status, time);
        // Notify the observers
        for (observer in observers_.vals()){
          observer(?question, ?updated_question); // @todo: remove questions from parameters
        };
      });
    };

  };

};