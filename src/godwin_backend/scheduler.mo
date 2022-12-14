import Types "types";
import Iterations "votes/register";
import Iteration "votes/iteration";
import Queries "votes/queries";
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
        switch(Iterations.getMostInteresting(iterations)){
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

    // @todo: could take more than one vote, cause if heartbeat does not loop fast enough, questions my stay open
    public func closeInterestVote(iterations: Iterations, time_now: Time) : (Iterations, ?Iteration) {
      switch(Iterations.getOldestInterest(iterations)){
        case(null){};
        case(?iteration){
          let interest = Iteration.unwrapInterest(iteration);
          // If enough time has passed, close votes
          if (time_now > interest.date + Utils.toTime(params_.interest_duration)) {
            let new_iteration = Iteration.closeVotes(iteration, time_now);
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

    public func closeOpinionVote(iterations: Iterations, time_now: Time) : (Iterations, ?Iteration) {
      switch(Iterations.getOldestOpinion(iterations)){
        case(null){};
        case(?iteration){
          let opinion = Iteration.unwrapOpinion(iteration);
          // If opinion duration is over, open categorization vote
          if (time_now > opinion.date + Utils.toTime(params_.opinion_duration)) {
            let new_iteration = Iteration.openCategorizationVote(iteration, time_now);
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

    public func closeCategorizationVote(iterations: Iterations, time_now: Time) : (Iterations, ?Iteration) {
      switch(Iterations.getOldestCategorization(iterations)){
        case(null){};
        case(?iteration){
          let categorization = Iteration.unwrapCategorization(iteration);
          // If categorization duration is over, close votes
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