import Types "types";
import Questions "questions/questions";
import Queries "questions/queries";
import Manager "votes/manager";
import Users "users";
import Utils "utils";
import WMap "wrappers/WMap";

import Map "mo:map/Map";

import Buffer "mo:base/Buffer";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

module {
  // For convenience: from base module
  type Time = Int;
  // For convenience: from types module
  type Question = Types.Question;
  type Category = Types.Category;
  type Duration = Types.Duration;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;
  type Queries = Queries.Queries;
  type Manager = Manager.Manager;
  type WMap<K, V> = WMap.WMap<K, V>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type QuestionStatus = Types.QuestionStatus;
  type SchedulerParameters = Types.SchedulerParameters;
  type VoteType = Types.VoteType;

  type TriggerType = {
    #PICK;
    #TIMEOUT;
  };

  public func triggerTypeToNat(trigger: TriggerType) : Nat {
    switch(trigger){
      case(#PICK)   { 0; };
      case(#TIMEOUT){ 1; };
    };
  };

  func hashTriggerType(a: TriggerType) : Nat { Map.nhash.0(triggerTypeToNat(a)); };
  func equalTriggerType(a: TriggerType, b: TriggerType) : Bool { Map.nhash.1(triggerTypeToNat(a), triggerTypeToNat(b)); };
  let triggerTypehash : Map.HashUtils<TriggerType> = ( func(a) = hashTriggerType(a), func(a, b) = equalTriggerType(a, b));

  type TriggerParams = {
    #PICK: PickParams;
    #TIMEOUT: TimeoutParams;
  };

  type PickParams = {
    rate: Time;
    last_pick: Time;
    transition: Transition;
  };

  type TimeoutParams = {
    duration: Time;
    transition: Transition;
  };

  type Transition = {
    #NEXT: QuestionStatus;
    #DELETE;
  };

  public type Register = Map<QuestionStatus, Map<TriggerType, TriggerParams>>;

  func putHelper(register: Register, status: QuestionStatus, trigger: TriggerType, params: TriggerParams){
    ignore Utils.put2D(register, Types.questionStatushash, status, triggerTypehash, trigger, params);
  };

  public func initRegister(params: SchedulerParameters, time_now: Time) : Register {
    let register = Map.new<QuestionStatus, Map<TriggerType, TriggerParams>>();
    putHelper(register, #VOTING(#CANDIDATE),      #PICK,    #PICK   ({ rate     = Utils.toTime(params.candidate_pick_rate);     transition = #NEXT(#VOTING(#OPINION));        last_pick = time_now; }));
    putHelper(register, #VOTING(#CANDIDATE),      #TIMEOUT, #TIMEOUT({ duration = Utils.toTime(params.candidate_duration);      transition = #NEXT(#REJECTED);                                      }));
    putHelper(register, #VOTING(#OPINION),        #TIMEOUT, #TIMEOUT({ duration = Utils.toTime(params.opinion_duration);        transition = #NEXT(#VOTING(#CATEGORIZATION));                       }));
    putHelper(register, #VOTING(#CATEGORIZATION), #TIMEOUT, #TIMEOUT({ duration = Utils.toTime(params.categorization_duration); transition = #NEXT(#CLOSED);                                        }));
    putHelper(register, #REJECTED,                #TIMEOUT, #TIMEOUT({ duration = Utils.toTime(params.rejected_duration);       transition = #DELETE;                                               }));
    register;
  };

  public func build(register: Register, questions: Questions, users: Users, queries: Queries, manager: Manager) : Scheduler {
    Scheduler(
      WMap.WMap2D<QuestionStatus, TriggerType, TriggerParams>(register, Types.questionStatushash, triggerTypehash),
      questions,
      users,
      queries,
      manager
    );
  };

  public class Scheduler(
    register_: WMap2D<QuestionStatus, TriggerType, TriggerParams>,
    questions_: Questions,
    users_: Users,
    queries_: Queries,
    manager_: Manager
  ){

    public func getPickRate(status: QuestionStatus) : Time {
      getPickParams(status).rate;
    };

    public func setPickRate(status: QuestionStatus, rate: Time) {
      ignore register_.put(status, #PICK, #PICK({ getPickParams(status) with rate; }));
    };

    public func getDuration(status: QuestionStatus) : Time {
      getTimeoutParams(status).duration;
    };

    public func setDuration(status: QuestionStatus, duration: Time) {
      ignore register_.put(status, #TIMEOUT, #TIMEOUT({ getTimeoutParams(status) with duration; }));
    };

    public func run(time_now: Time) {
      for ((status, trigger) in register_.entries()){
        for ((_, trigger_params) in trigger) {
          switch(trigger_params){
            case(#PICK   (params)){ ignore pickQuestion    (status, params, time_now); };
            case(#TIMEOUT(params)){ ignore timeoutQuestions(status, params, time_now); };
          };
        };
      };
    };

    public func pickQuestion(status: QuestionStatus, params: PickParams, time_now: Time) : ?Question {
      var question : ?Question = null;
      if (time_now > params.last_pick + params.rate){
        // @todo: pass the right OrderBy ?
        Option.iterate(questions_.next(queries_.entries(#AUTHOR, #FWD)), func(most_upvoted: Question) {
          // Update the last pick
          ignore register_.put(status, #PICK, #PICK({ params with last_pick = time_now; }));
          // Perform the transition
          question := ?transitQuestion(most_upvoted, params.transition, time_now);
        }); 
      };
      return question;
    };

    public func timeoutQuestions(status: QuestionStatus, params: TimeoutParams, time_now: Time) : [Question] {
      let buffer = Buffer.Buffer<Question>(0);
      let iter = queries_.entries(#AUTHOR, #FWD); // @todo
      label iter_oldest while(true){ // @todo: have a better way to loop with a function condition
        switch(questions_.next(iter)){
          case(null){ break iter_oldest; };
          case(?question){
            // Stop iterating here if the question is not old enough
            if (time_now < question.status_info.current.date + params.duration){ break iter_oldest; };
            // If old enough, handle the question
            buffer.add(transitQuestion(question, params.transition, time_now));
          };
        };
      };
      Buffer.toArray(buffer);
    };

    func transitQuestion(question: Question, transition: Transition, time_now: Time) : Question {
      // Close the current vote if applicable
      iterateVotingStatus(question, manager_.closeVote);
      // Handle the transition
      switch(transition){
        case(#NEXT(status)){ 
          // Update the question's status
          let question_updated = questions_.updateStatus(question.id, status, time_now);
          // Open a new vote if applicable
          iterateVotingStatus(question_updated, manager_.openVote);
          // Return the updated question
          question_updated;
        };
        case(#DELETE){
          // Remove the question
          questions_.removeQuestion(question.id);
          // Delete the votes associated to this question
          manager_.deleteVotes(question);
          // Return the deleted question
          question;
        };
      };
    };

    func getParams(status: QuestionStatus, trigger_type: TriggerType) : TriggerParams {
      switch(register_.get(status, trigger_type)){
        case(null) { Debug.trap("@todo"); };
        case(?trigger_params) { trigger_params; };
      };
    };

    func getPickParams(status: QuestionStatus) : PickParams {
      switch(getParams(status, #PICK)){
        case(#PICK(params)) { params; };
        case(#TIMEOUT(_)) { Debug.trap("@todo"); };
      };
    };

    func getTimeoutParams(status: QuestionStatus) : TimeoutParams {
      switch(getParams(status, #TIMEOUT)){
        case(#PICK(_)) { Debug.trap("@todo"); };
        case(#TIMEOUT(params)) { params; };
      };
    };

    func iterateVotingStatus(question: Question, f: (Question, VoteType) -> ()) {
      switch(question.status_info.current.status){
        case(#VOTING(vote)) { f(question, vote); };
        case(_){};
      };
    };

  };

};