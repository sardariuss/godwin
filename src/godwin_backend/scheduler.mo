import Types "types";
import Questions "questions/questions";
import Question "questions/question";
import Queries "questions/queries";
import Users "users";
import Utils "utils";

import Buffer "mo:base/Buffer";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type SchedulerParams = Types.SchedulerParams;
  type Category = Types.Category;
  type DecayParams = Types.DecayParams;
  type Status = Types.Status;
  type Duration = Types.Duration;
  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;
  type Queries = Queries.Queries;
  type Time = Int;

  public type Register = {
    var params: SchedulerParams;
    var last_selection_date: Time;
  };

  public func initRegister(params: SchedulerParams, last_selection_date: Time) : Register {
    {
      var params = params;
      var last_selection_date = last_selection_date;
    };
  };

  // @todo: make the return of functions uniform (always return an array of questions)
  public class Scheduler(register_: Register, questions_: Questions, users_: Users, queries_: Queries, decay_params_: ?DecayParams){
    
    public func getParams() : SchedulerParams {
      register_.params;
    };

    public func setParam(status: Status, duration: Duration){
      switch(status){
        case(#CANDIDATE)             { register_.params := { register_.params with selection_rate          = duration; } };
        case(#OPEN(#OPINION))        { register_.params := { register_.params with interest_duration       = duration; } };
        case(#OPEN(#CATEGORIZATION)) { register_.params := { register_.params with opinion_duration        = duration; } };
        case(#CLOSED)                { register_.params := { register_.params with categorization_duration = duration; } };
        case(#REJECTED)              { register_.params := { register_.params with rejected_duration       = duration; } };
      };
    };

    public func rejectQuestions(time_now: Time) : [Question] {
      let buffer = Buffer.Buffer<Question>(0);
      let iter = queries_.entries(#STATUS_DATE(#CANDIDATE), #fwd);
      label iter_oldest while(true){
        switch(questions_.next(iter)){
          case(null){ break iter_oldest; };
          case(?question){
            let interest = Question.unwrapInterest(question);
            // Stop iterating here if the question is not old enough
            if (time_now < interest.date + Utils.toTime(register_.params.interest_duration)){ break iter_oldest; };
            // If old enough, reject the question
            let rejected_question = Question.rejectQuestion(question, time_now);
            questions_.replaceQuestion(rejected_question);
            buffer.add(rejected_question);
          };
        };
      };
      buffer.toArray();
    };

    
    public func deleteQuestions(time_now: Time) : [Question] {
      let buffer = Buffer.Buffer<Question>(0);
      let iter = queries_.entries(#STATUS_DATE(#REJECTED), #fwd);
      label iter_oldest while(true){
        switch(questions_.next(iter)){
          case(null){ break iter_oldest; };
          case(?question){
            // Stop iterating here if the question is not old enough
            if (time_now < Question.unwrapRejectedDate(question) + Utils.toTime(register_.params.rejected_duration)){ break iter_oldest; };
            // If old enough, delete the question
            buffer.add(questions_.removeQuestion(question.id));
          };
        };
      };
      buffer.toArray();
    };

    public func openOpinionVote(time_now: Time) : ?Question {
      if (time_now > register_.last_selection_date + Utils.toTime(register_.params.selection_rate)) {
        switch(questions_.first(queries_, #INTEREST, #bwd)){
          case(null){};
          case(?question){ 
            let updated_question = Question.openOpinionVote(question, time_now);
            questions_.replaceQuestion(updated_question);
            register_.last_selection_date := time_now;
            return ?updated_question;
          };
        };
      };
      null;
    };

    public func openCategorizationVote(time_now: Time, categories: [Category]) : ?Question {
      switch(questions_.first(queries_, #STATUS_DATE(#OPEN(#OPINION)), #fwd)){
        case(null){};
        case(?question){
          let iteration = Question.unwrapIteration(question);
          // If categorization date has come, open categorization vote
          if (time_now > iteration.opinion.date + Utils.toTime(register_.params.opinion_duration)) {
            let updated_question = Question.openCategorizationVote(question, time_now, categories);
            questions_.replaceQuestion(updated_question);
            return ?updated_question;
          };
        };
      };
      null;
    };

    public func closeQuestion(time_now: Time) : ?Question {
      switch(questions_.first(queries_, #STATUS_DATE(#OPEN(#CATEGORIZATION)), #fwd)){
        case(null){};
        case(?question){
          let iteration = Question.unwrapIteration(question);
          // If categorization duration is over, close votes
          if (time_now > iteration.categorization.date + Utils.toTime(register_.params.categorization_duration)) {
            // Need to update the users convictions
            users_.updateConvictions(Question.unwrapIteration(question), question.vote_history, decay_params_);
            // Finally close the question
            let closed_question = Question.closeQuestion(question, time_now);
            questions_.replaceQuestion(closed_question);
            return ?closed_question;
          };
        };
      };
      null;
    };

  };

};