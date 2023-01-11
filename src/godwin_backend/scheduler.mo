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
  type Questions = Questions.Questions;
  type Time = Int;

  type Shareable = {
    params: SchedulerParams;
    last_selection_date: Time;
  };

  public type OnClosingQuestion = (Question) -> ();

  // @todo: make the return of functions uniform (always return an array of questions)
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

    public func rejectQuestions(questions: Questions, time_now: Time) : [Question] {
      let buffer = Buffer.Buffer<Question>(0);
      let iter = questions.iter(#STATUS_DATE(#CANDIDATE), #fwd);
      label iter_oldest while(true){
        switch(questions.next(iter)){
          case(null){ break iter_oldest; };
          case(?question){
            let interest = Question.unwrapInterest(question);
            // Stop iterating here if the question is not old enough
            if (time_now < interest.date + Utils.toTime(params_.interest_duration)){ break iter_oldest; };
            // If old enough, reject the question
            let rejected_question = Question.rejectQuestion(question, time_now);
            questions.replaceQuestion(rejected_question);
            buffer.add(rejected_question);
          };
        };
      };
      buffer.toArray();
    };

    
    public func deleteQuestions(questions: Questions, time_now: Time) : [Question] {
      let buffer = Buffer.Buffer<Question>(0);
      let iter = questions.iter(#STATUS_DATE(#REJECTED), #fwd);
      label iter_oldest while(true){
        switch(questions.next(iter)){
          case(null){ break iter_oldest; };
          case(?question){
            // Stop iterating here if the question is not old enough
            if (time_now < Question.unwrapRejectedDate(question) + Utils.toTime(params_.rejected_duration)){ break iter_oldest; };
            // If old enough, delete the question
            buffer.add(questions.removeQuestion(question.id));
          };
        };
      };
      buffer.toArray();
    };

    public func openOpinionVote(questions: Questions, time_now: Time) : ?Question {
      if (time_now > last_selection_date_ + Utils.toTime(params_.selection_rate)) {
        switch(questions.first(#INTEREST, #bwd)){
          case(null){};
          case(?question){ 
            let updated_question = Question.openOpinionVote(question, time_now);
            questions.replaceQuestion(updated_question);
            last_selection_date_ := time_now;
            return ?updated_question;
          };
        };
      };
      null;
    };

    public func openCategorizationVote(questions: Questions, time_now: Time, categories: [Category]) : ?Question {
      switch(questions.first(#STATUS_DATE(#OPEN(#OPINION)), #fwd)){
        case(null){};
        case(?question){
          let iteration = Question.unwrapIteration(question);
          // If categorization date has come, open categorization vote
          if (time_now > iteration.opinion.date + Utils.toTime(params_.opinion_duration)) {
            let updated_question = Question.openCategorizationVote(question, time_now, categories);
            questions.replaceQuestion(updated_question);
            return ?updated_question;
          };
        };
      };
      null;
    };

    public func closeQuestion(questions: Questions, time_now: Time) : ?Question {
      switch(questions.first(#STATUS_DATE(#OPEN(#CATEGORIZATION)), #fwd)){
        case(null){};
        case(?question){
          let iteration = Question.unwrapIteration(question);
          // If categorization duration is over, close votes
          if (time_now > iteration.categorization.date + Utils.toTime(params_.categorization_duration)) {
            // Need to call the callback before closing the question
            on_closing_callback_(question);
            // Finally close the question
            let closed_question = Question.closeQuestion(question, time_now);
            questions.replaceQuestion(closed_question);
            return ?closed_question;
          };
        };
      };
      null;
    };

  };

};