import Types "Types";
import StatusHelper "StatusHelper";
import Duration "Duration";
import Questions "Questions";
import Polls "votes/Polls";

import StateMachine "../utils/StateMachine";
import Ref "../utils/Ref";
import WRef "../utils/wrappers/WRef";

import Map "mo:map/Map";

import Option "mo:base/Option";
import Debug "mo:base/Debug";

module {

  type Time = Int;
  type Question = Types.Question;
  type Status = Types.Status;
  type Duration = Types.Duration;
  type Questions = Questions.Questions;
  type Polls = Polls.Polls;
  type Schema = StateMachine.Schema<Status, Event, StatusInfo, DataModel>;
  type StateInfo = StateMachine.StateInfo<Status, StatusInfo>;
  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;

  type StatusInfo = {
    date: Time;
    index: Nat;
    question_id: Nat;
  };

  public type DataModel = {
    time: Time;
    most_interesting: ?Nat;
    last_pick_date: Time;
    params: Types.SchedulerParameters;
  };

  func getStatusDuration(model: DataModel, status: Status) : Time {
    let params = model.params;
    let duration = switch(status){
      case(#VOTING(#INTEREST)) { params.interest_duration; };
      case(#VOTING(#OPINION)) { params.opinion_duration; };
      case(#VOTING(#CATEGORIZATION)) { params.categorization_duration; };
      case(#REJECTED) { params.rejected_duration; };
      case(_) { Debug.trap("There is no duration for this status"); };
    };
    Duration.toTime(duration);
  };

  func getInterestPickRate(model: DataModel) : Time {
    Duration.toTime(model.params.interest_pick_rate);
  };

  public func initDataModel(time: Time, params: Types.SchedulerParameters) : DataModel {
    { time; most_interesting = null; last_pick_date = time; params; };
  };

  type Event = {
    #TIME_UPDATE;
    #REOPEN_QUESTION;
  };

  func toTextEvent(event: Event) : Text {
    switch(event){
      case(#TIME_UPDATE) { "TIME_UPDATE"; };
      case(#REOPEN_QUESTION) { "REOPEN_QUESTION"; };
    };
  };

  func hashEvent(a: Event) : Nat { Map.thash.0(toTextEvent(a)); };
  func equalEvent(a: Event, b: Event) : Bool { Map.thash.1(toTextEvent(a), toTextEvent(b)); };
  let event_hash : Map.HashUtils<Event> = ( func(a) = hashEvent(a), func(a, b) = equalEvent(a, b) );

  func timedOutFirstIteration(state_info: StateInfo, model: DataModel) : Bool {
    state_info.info.index == 0 and timedOut(state_info, model);
  };

  func timedOutNextIterations(state_info: StateInfo, model: DataModel) : Bool {
    state_info.info.index > 0 and timedOut(state_info, model);
  };

  func tickMostInteresting(state_info: StateInfo, model: DataModel) : Bool {
    Option.getMapped(
      model.most_interesting,
      func(question_id: Nat) : Bool {
        question_id == state_info.info.question_id and model.last_pick_date + getInterestPickRate(model) > model.time;
      },
      false
    );
  };

  func timedOut(state_info: StateInfo, model: DataModel) : Bool {
    state_info.info.date + getStatusDuration(model, state_info.state) > model.time;
  };

  func passThrough(state_info: StateInfo, model: DataModel) : Bool {
    true;
  };

  public func build(model: Ref<DataModel>, questions: Questions, polls: Polls) : Controller {
    let schema = StateMachine.init<Status, Event, StatusInfo, DataModel>(StatusHelper.status_hash, event_hash);

    StateMachine.addTransition(schema, #VOTING(#INTEREST),       #REJECTED,                timedOutFirstIteration, [#TIME_UPDATE]);
    StateMachine.addTransition(schema, #VOTING(#INTEREST),       #CLOSED,                  timedOutNextIterations, [#TIME_UPDATE]);
    StateMachine.addTransition(schema, #REJECTED,                #TRASH,                   timedOut,               [#TIME_UPDATE]);
    StateMachine.addTransition(schema, #VOTING(#INTEREST),       #VOTING(#OPINION),        tickMostInteresting,    [#TIME_UPDATE]);
    StateMachine.addTransition(schema, #VOTING(#OPINION),        #VOTING(#CATEGORIZATION), timedOut,               [#TIME_UPDATE]);
    StateMachine.addTransition(schema, #VOTING(#CATEGORIZATION), #CLOSED,                  timedOut,               [#TIME_UPDATE]);
    StateMachine.addTransition(schema, #CLOSED,                  #VOTING(#INTEREST),       passThrough,            [#REOPEN_QUESTION]);

    Controller(schema, WRef.WRef(model), questions, polls);
  };

  public class Controller(schema_: Schema, model_: WRef<DataModel>, questions_: Questions, polls_: Polls) = {

    public func run(time: Time, most_interesting: ?Nat) {
      model_.set({ model() with time; most_interesting; });
      for (question in questions_.iter()){
        submitEvent(question, #TIME_UPDATE, time);
      };
      // @todo: shall update last_pick_date
    };

    public func reopenQuestion(question: Question, time: Time) {
      submitEvent(question, #REOPEN_QUESTION, time);
    };
    
    public func setDuration(status: Status, duration: Duration) {
      switch(status){
        case(#VOTING(#INTEREST)) {       model_.set({ model() with params = { model().params with interest_duration       = duration; }}); };
        case(#VOTING(#OPINION)) {        model_.set({ model() with params = { model().params with opinion_duration        = duration; }}); };
        case(#VOTING(#CATEGORIZATION)) { model_.set({ model() with params = { model().params with categorization_duration = duration; }}); };
        case(#REJECTED) {                model_.set({ model() with params = { model().params with rejected_duration       = duration; }}); };
        case(_) { Debug.trap("Cannot set a duration for this status"); };
      };
    };

    public func getDuration(status: Status) : Duration {
      Duration.fromTime(getStatusDuration(model(), status));
    };
  
    public func setPickRate(rate: Duration) {
      model_.set({ model() with params = { model().params with interest_pick_rate = rate }});
    };

    public func getPickRate() : Duration {
      Duration.fromTime(getInterestPickRate(model()));
    };

    func submitEvent(question: Question, event: Event, time: Time) {
      let indexed_status = question.status_info.current;
      let state_machine = {
        schema = schema_;
        model = model();
        current = { 
          state = indexed_status.status;
          info = {
            date = indexed_status.date;
            index = indexed_status.index;
            question_id = question.id;
          };
        };
      };
      
      Option.iterate(StateMachine.submitEvent(state_machine, event), func(status: Status){
        // Update the question status
        let updated_question = questions_.updateStatus(question.id, status, time);
        // Perform additional updates if applicable
        switch(status){
          case(#VOTING(poll)){
            // Open the vote
            polls_.openVote(updated_question, poll);
            if (poll == #OPINION){
              // Update the last pick
              model_.set({ model() with last_pick_date = time });
            };
          };
          case(#TRASH){
            // Remove the question
            questions_.removeQuestion(question.id);
          };
          case(_) {};
        };
      });
    };

    func model() : DataModel { model_.get(); };

  };

};