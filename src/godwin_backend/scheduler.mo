import Types "types";
import Questions "questions/questions";
import Question "questions/question";
import Users "users";
import Utils "utils";

import Buffer "mo:base/Buffer";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type SchedulerParams = Types.SchedulerParams;
  type Category = Types.Category;
  // For convenience: from other modules
  type Questions = Questions.Register;
  type Time = Int;

  type Shareable = {
    params: SchedulerParams;
    last_selection_date: Time;
  };

  public class Scheduler(args: Shareable){
    
    /// Members
    var params_ = args.params;
    var last_selection_date_ = args.last_selection_date;

    public func share() : Shareable {
      {
        params = params_;
        last_selection_date = last_selection_date_;
      };
    };

    public func setParams(params: SchedulerParams){
      params_ := params;
    };

    public func getLastSelectionDate() : Time {
      last_selection_date_;
    };

    // @todo: find a way to break the loop
    public func rejectQuestions(questions: Questions, time_now: Time) : (Questions, [Question]) {
      var updated_questions = questions;
      let buffer = Buffer.Buffer<Question>(0);
      while(true){
        switch(Questions.getOldestInterest(updated_questions)){
          case(null){ return (updated_questions, buffer.toArray()); };
          case(?question){
            let interest = Question.unwrapInterest(question);
            // If enough time has passed, close votes
            if (time_now > interest.date + Utils.toTime(params_.interest_duration)){
              let new_question = Question.rejectQuestion(question, time_now);
              updated_questions := Questions.replaceQuestion(questions, new_question);
              buffer.add(new_question);
            } else {
              return (updated_questions, buffer.toArray());
            };
          };
        };
      };
      (updated_questions, buffer.toArray());
    };

    public func openOpinionVote(questions: Questions, time_now: Time) : (Questions, ?Question) {
      if (time_now > last_selection_date_ + Utils.toTime(params_.selection_rate)) {
        switch(Questions.getMostInteresting(questions)){
          case(null){};
          case(?question){ 
            let new_question = Question.openOpinionVote(question, time_now);
            last_selection_date_ := time_now;
            return (Questions.replaceQuestion(questions, new_question), ?new_question);
          };
        };
      };
      (questions, null);
    };

    public func openCategorizationVote(questions: Questions, time_now: Time) : (Questions, ?Question) {
      switch(Questions.getOldestOpinion(questions)){
        case(null){};
        case(?question){
          let opinion = Question.unwrapIteration(question).opinion;
          // If opinion duration is over, open categorization vote
          if (time_now > opinion.date + Utils.toTime(params_.opinion_duration)) {
            let new_question = Question.openCategorizationVote(question, time_now);
            return (Questions.replaceQuestion(questions, new_question), ?new_question);
          };
        };
      };
      (questions, null);
    };

    public func closeQuestion(questions: Questions, time_now: Time, users: Users.Register, categories: [Category]) : (Questions, Users.Register, ?Question) {
      switch(Questions.getOldestCategorization(questions)){
        case(null){};
        case(?question){
          let iteration = Question.unwrapIteration(question);
          // If categorization duration is over, close votes
          if (time_now > iteration.categorization.date + Utils.toTime(params_.categorization_duration)) {
            let new_users = Users.updateConvictions(users, iteration, question.vote_history, categories); // @todo: could use a callback
            let new_question = Question.closeQuestion(question, time_now);
            return (Questions.replaceQuestion(questions, new_question), users, ?new_question);
          };
        };
      };
      (questions, users, null);
    };

  };

};