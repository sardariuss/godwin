import Types "types";
import Questions "questions/questions";
import Question "questions/question";
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

  public type OnClosingQuestion = (Question) -> ();

  public class Scheduler(args: Shareable, on_closing_callback: OnClosingQuestion){
    
    /// Members
    var params_ = args.params;
    var last_selection_date_ = args.last_selection_date;
    let on_closing_callback_ = on_closing_callback;

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

    public func rejectQuestions(questions: Questions, time_now: Time) : (Questions, [Question]) {
      var updated_questions = questions;
      let buffer = Buffer.Buffer<Question>(0);
      let iter = Questions.iter(questions, #STATUS_DATE(#CANDIDATE), #FWD);
      label iter_oldest while(true){
        switch(Questions.next(questions, iter)){
          case(null){ break iter_oldest; };
          case(?question){
            let interest = Question.unwrapInterest(question);
            // Stop iterating here if the question is not old enough
            if (time_now < interest.date + Utils.toTime(params_.interest_duration)){ break iter_oldest; };
            // If old enough, reject the question
            let updated_question = Question.rejectQuestion(question, time_now);
            updated_questions := Questions.replaceQuestion(questions, updated_question);
            buffer.add(updated_question);
          };
        };
      };
      (updated_questions, buffer.toArray());
    };

    public func openOpinionVote(questions: Questions, time_now: Time) : (Questions, ?Question) {
      if (time_now > last_selection_date_ + Utils.toTime(params_.selection_rate)) {
        switch(Questions.first(questions, #INTEREST, #BWD)){
          case(null){};
          case(?question){ 
            let updated_question = Question.openOpinionVote(question, time_now, time_now + Utils.toTime(params_.opinion_duration));
            last_selection_date_ := time_now;
            return (Questions.replaceQuestion(questions, updated_question), ?updated_question);
          };
        };
      };
      (questions, null);
    };

    public func openCategorizationVote(questions: Questions, time_now: Time, categories: [Category]) : (Questions, ?Question) {
      switch(Questions.first(questions, #STATUS_DATE(#OPEN(#OPINION)), #FWD)){
        case(null){};
        case(?question){
          let opinion = Question.unwrapIteration(question).opinion;
          // If opinion duration is over, open categorization vote
          if (time_now > opinion.date + Utils.toTime(params_.opinion_duration)) {
            let updated_question = Question.openCategorizationVote(question, time_now, categories);
            return (Questions.replaceQuestion(questions, updated_question), ?updated_question);
          };
        };
      };
      (questions, null);
    };

    public func closeQuestion(questions: Questions, time_now: Time) : (Questions, ?Question) {
      switch(Questions.first(questions, #STATUS_DATE(#OPEN(#CATEGORIZATION)), #FWD)){
        case(null){};
        case(?question){
          let iteration = Question.unwrapIteration(question);
          // If categorization duration is over, close votes
          if (time_now > iteration.categorization.date + Utils.toTime(params_.categorization_duration)) {
            // Need to call the callback before closing the question
            on_closing_callback_(question);
            // Finally close the question
            let closed_question = Question.closeQuestion(question, time_now);
            return (Questions.replaceQuestion(questions, closed_question), ?closed_question);
          };
        };
      };
      (questions, null);
    };

  };

};