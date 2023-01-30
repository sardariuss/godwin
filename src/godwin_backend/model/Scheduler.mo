import Types "Types";
import Questions "Questions";
import QuestionQueries "QuestionQueries";
import Polls "votes/Polls";
import Users "Users";
import Duration "Duration";
import StatusHelper "StatusHelper";
import Utils "../utils/Utils";
import WMap "../utils/wrappers/WMap";

import Map "mo:map/Map";

import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

module {
  // For convenience: from base module
  type Time = Int;
  // For convenience: from types module
  type Question = Types.Question;
  type Category = Types.Category;
  type Duration = Types.Duration;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;
  type Iter<T> = Iter.Iter<T>;

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;
  type QuestionQueries = QuestionQueries.QuestionQueries;
  type Polls = Polls.Polls;
  type WMap<K, V> = WMap.WMap<K, V>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type Status = Types.Status;
  type SchedulerParameters = Types.SchedulerParameters;
  type Poll = Types.Poll;
  type OrderBy = QuestionQueries.OrderBy;
  type Direction = QuestionQueries.Direction;

  type TriggerType = {
    #PICK;
    #TIMEOUT;
  };

  type Params = {
    transition: Transition;
    trigger: TriggerParams;
    order_by: OrderBy;
    direction: Direction;
  };

  type TriggerParams = {
    #PICK: PickParams;
    #TIMEOUT: TimeoutParams;
  };

  type PickParams = {
    rate: Time;
    last_pick: Time;
  };

  type TimeoutParams = {
    duration: Time;
  };

  type Transition = {
    #NEXT: Status;
    #DELETE;
  };

  public type Register = Map<Status, Map<TriggerType, Params>>;

  public func triggerTypeToText(trigger: TriggerType) : Text {
    switch(trigger){
      case(#PICK)   { "PICK";    };
      case(#TIMEOUT){ "TIMEOUT"; };
    };
  };

  func hashTriggerType(a: TriggerType) : Nat { Map.thash.0(triggerTypeToText(a)); };
  func equalTriggerType(a: TriggerType, b: TriggerType) : Bool { Map.thash.1(triggerTypeToText(a), triggerTypeToText(b)); };
  let triggerTypehash : Map.HashUtils<TriggerType> = ( func(a) = hashTriggerType(a), func(a, b) = equalTriggerType(a, b));

  func putHelper(register: Register, status: Status, transition: Transition, order_by: OrderBy, direction: Direction, trigger: TriggerParams){
    ignore Utils.put2D(register, StatusHelper.status_hash, status, triggerTypehash, getTriggerType(trigger), { transition; order_by; direction; trigger; });
  };

  public func initRegister(params: SchedulerParameters, time_now: Time) : Register {
    let register = Map.new<Status, Map<TriggerType, Params>>();
    putHelper(register, #VOTING(#INTEREST),       #NEXT(#REJECTED),                #STATUS(#VOTING(#INTEREST)),       #BWD, #TIMEOUT({ duration = Duration.toTime(params.interest_duration);                            }));
    putHelper(register, #REJECTED,                #DELETE,                         #STATUS(#REJECTED),                #BWD, #TIMEOUT({ duration = Duration.toTime(params.rejected_duration);                             }));
    putHelper(register, #VOTING(#INTEREST),       #NEXT(#VOTING(#OPINION)),        #INTEREST_SCORE,                   #FWD, #PICK   ({ rate     = Duration.toTime(params.interest_pick_rate);     last_pick = time_now; }));
    putHelper(register, #VOTING(#OPINION),        #NEXT(#VOTING(#CATEGORIZATION)), #STATUS(#VOTING(#OPINION)),        #BWD, #TIMEOUT({ duration = Duration.toTime(params.opinion_duration);                              }));
    putHelper(register, #VOTING(#CATEGORIZATION), #NEXT(#CLOSED),                  #STATUS(#VOTING(#CATEGORIZATION)), #BWD, #TIMEOUT({ duration = Duration.toTime(params.categorization_duration);                       }));
    register;
  };

  public func build(register: Register, questions: Questions, queries: QuestionQueries, polls: Polls) : Scheduler {
    Scheduler(
      WMap.WMap2D<Status, TriggerType, Params>(register, StatusHelper.status_hash, triggerTypehash),
      questions,
      queries,
      polls
    );
  };

  public class Scheduler(
    register_: WMap2D<Status, TriggerType, Params>,
    questions_: Questions,
    queries_: QuestionQueries,
    polls_: Polls
  ){

    public func getPickRate(status: Status) : Time {
      getPickParams(status).rate;
    };

    public func setPickRate(status: Status, rate: Time) {
      updateTrigger(status, #PICK({ getPickParams(status) with rate; }));
    };

    public func getDuration(status: Status) : Time {
      getTimeoutParams(status).duration;
    };

    public func setDuration(status: Status, duration: Time) {
      updateTrigger(status, #TIMEOUT({ getTimeoutParams(status) with duration; }));
    };

    public func run(time_now: Time) {
      for ((status, trigger_type) in register_.entries()){
        for ((_, {transition; trigger; order_by; direction;}) in trigger_type) {
          let iter = queries_.entries(order_by, direction);
          switch(trigger){
            case(#PICK   (params)){ ignore pickQuestion    (iter, transition, params, status, time_now); };
            case(#TIMEOUT(params)){ ignore timeoutQuestions(iter, transition, params, time_now); };
          };
        };
      };
    };

    public func pickQuestion(iter: Iter<Question>, transition: Transition, params: PickParams, status: Status, time_now: Time) : ?Question {
      var question : ?Question = null;
      if (time_now > params.last_pick + params.rate){
        Option.iterate(iter.next(), func(most_upvoted: Question) {
          // Perform the transition
          question := ?transitQuestion(most_upvoted, transition, time_now);
        });
        // Update the last pick
        updateTrigger(status, #PICK({ params with last_pick = time_now; }));
      };
      return question;
    };

    public func timeoutQuestions(iter: Iter<Question>, transition: Transition, params: TimeoutParams, time_now: Time) : [Question] {
      let buffer = Buffer.Buffer<Question>(0);
      label iter_oldest while(true){ // @todo: have a better way to loop with a function condition
        switch(iter.next()){
          case(null){ break iter_oldest; };
          case(?question){
            // Stop iterating here if the question is not old enough
            if (time_now < question.status_info.current.date + params.duration){ break iter_oldest; };
            // If old enough, handle the question
            buffer.add(transitQuestion(question, transition, time_now));
          };
        };
      };
      Buffer.toArray(buffer);
    };

    func transitQuestion(question: Question, transition: Transition, time_now: Time) : Question {
      // Handle the transition
      switch(transition){
        case(#NEXT(status)){ 
          // Update the question's status
          let question_updated = questions_.updateStatus(question.id, status, time_now);
          // Open a new vote if applicable
          StatusHelper.iterateVotingStatus(question_updated, polls_.openVote);
          // Return the updated question
          question_updated;
        };
        case(#DELETE){
          // Remove the question
          questions_.removeQuestion(question.id);
          // Delete the votes associated to this question
          polls_.deleteVotes(question);
          // Return the deleted question
          question;
        };
      };
    };

    func getParams(status: Status, trigger_type: TriggerType) : TriggerParams {
      switch(register_.get(status, trigger_type)){
        case(null) { Debug.trap("@todo"); };
        case(?params) { params.trigger; };
      };
    };

    func unwrapPickParams(trigger: TriggerParams) : PickParams {
      switch(trigger){
        case(#PICK(params)) { params; };
        case(#TIMEOUT(_)) { Debug.trap("@todo"); };
      };
    };

    func unwrapTimeoutParams(trigger: TriggerParams) : TimeoutParams {
      switch(trigger){
        case(#PICK(_)) { Debug.trap("@todo"); };
        case(#TIMEOUT(params)) { params; };
      };
    };

    func getPickParams(status: Status) : PickParams {
      unwrapPickParams(getParams(status, #PICK));
    };

    func getTimeoutParams(status: Status) : TimeoutParams {
      unwrapTimeoutParams(getParams(status, #TIMEOUT));
    };

    func updateTrigger(status: Status, trigger: TriggerParams) {
      let trigger_type =  getTriggerType(trigger);
      switch(register_.get(status, trigger_type)){
        case(null) { Debug.trap("@todo"); };
        case(?params) { ignore register_.put(status, trigger_type, {params with trigger}); };
      };
    };

  };

  func getTriggerType(trigger: TriggerParams) : TriggerType {
    switch(trigger){
      case(#PICK(_)) { #PICK; };
      case(#TIMEOUT(_)) { #TIMEOUT; };
    };
  };

};