import Types "types";
import Iterations "votes/register";
import Iteration "votes/iteration";
import Utils "utils";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type SchedulerParams = Types.SchedulerParams;
  type Iteration = Types.Iteration;
  // For convenience: from other modules
  type Iterations = Iterations.Register;
  type Time = Int;

  type Shareable = {
    params: SchedulerParams;
    last_selection_date: Time;
  };

  // Right now, the scheduler does this:
  // SelectionStage:       created -> selected -> archived
  // CategorizationStage:       pending        -> ongoing  -> done
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

    public func selectQuestion(iterations: Iterations, time_now: Time) : (Iterations, ?Iteration) {
      if (time_now > last_selection_date_ + Utils.toTime(params_.selection_rate)) {
        switch(Iterations.find(iterations, 0)){
        //switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#CREATED, #ENDORSEMENTS, #BWD))){ // @todo
          case(null){};
          case(?iteration){ 
            let new_iteration = Iteration.openOpinionVote(iteration, time_now);
            last_selection_date_ := time_now;
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

    public func closeInterestVote(iterations: Iterations, time_now: Time) : (Iterations, ?Iteration) {
      switch(Iterations.find(iterations, 0)){
      //switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#CREATED, #ENDORSEMENTS, #BWD))){ // @todo
        case(null){};
        case(?iteration){
          if (time_now > iteration.opening_date + Utils.toTime(params_.interest_duration)) {
            let new_iteration = Iteration.closeVotes(iteration, time_now);
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

    public func closeOpinionVote(iterations: Iterations, time_now: Time) : (Iterations, ?Iteration) {
      switch(Iterations.find(iterations, 0)){
        // switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#SELECTED, #SELECTION_STAGE_DATE, #FWD))){ // @todo
        case(null){};
        case(?iteration){
          let opinion = Iteration.unwrapOpinion(iteration);
          // If enough time has passed, archived the question
          if (time_now > opinion.date + Utils.toTime(params_.selection_duration)) {
            let new_iteration = Iteration.openCategorizationVote(iteration, time_now);
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

    public func closeCategorizationVote(iterations: Iterations, time_now: Time) : (Iterations, ?Iteration) {
      // Get the oldest question currently being categorized
      switch(Iterations.find(iterations, 0)){
      //switch(Questions.nextQuestion(questions, questions.getInCategorizationStage(#ONGOING, #CATEGORIZATION_STAGE_DATE, #FWD))){ // @todo
        case(null){}; // If there is no question with ongoing categorization_stage, there is nothing to do
        case(?iteration){
          let categorization = Iteration.unwrapCategorization(iteration);
          // If enough time has passed, put the categorization_stage at done and save its aggregate
          if (time_now > categorization.date + Utils.toTime(params_.categorization_duration)) {
            let new_iteration = Iteration.closeVotes(iteration, time_now);
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

    // @todo: remove closed "new" questions 

  };

};