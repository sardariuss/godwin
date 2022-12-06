import Types "types";
import Iterations "votes/register";
import Iteration "votes/iteration";
import Questions "questions/questions";
import Categorizations "votes/categorizations";
import Opinions "votes/opinions";
import Users "users";
import Utils "utils";
import StageHistory "stageHistory";

import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Time "mo:base/Time";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Time = Time.Time;
  // For convenience: from types module
  type Question = Types.Question;
  type SchedulerParams = Types.SchedulerParams;
  type Iteration = Types.Iteration;
  // For convenience: from other modules
  type Users = Users.Users;
  type Questions = Questions.Questions;
  type Categorizations = Categorizations.Categorizations;
  type Opinions = Opinions.Opinions;
  type Iterations = Iterations.Register;

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
        switch(Iterations.findIteration(iterations, 0)){
        //switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#CREATED, #ENDORSEMENTS, #BWD))){ // @todo
          case(null){};
          case(?iteration){ 
            assert(iteration.current_vote == #INTEREST);
            last_selection_date_ := time_now;
            let new_iteration = Iteration.updateCurrentVote(iteration, #OPINION, null);
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

    public func archiveQuestion(iterations: Iterations, time_now: Time) : (Iterations, ?Iteration) {
      switch(Iterations.findIteration(iterations, 0)){
        // switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#SELECTED, #SELECTION_STAGE_DATE, #FWD))){ // @todo
        case(null){};
        case(?iteration){
          // 
          assert(iteration.current_vote == #OPINION);
          let opinion = Iteration.unwrapOpinion(iteration);
          // If enough time has passed, archived the question
          if (time_now > opinion.date + Utils.toTime(params_.selection_duration)) {
            let new_iteration = Iteration.updateCurrentVote(iteration, #CATEGORIZATION, null);
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

    public func closeCategorization(iterations: Iterations, users: Users, time_now: Time) : (Iterations, ?Iteration) {
      // Get the oldest question currently being categorized
      switch(Iterations.findIteration(iterations, 0)){
      //switch(Questions.nextQuestion(questions, questions.getInCategorizationStage(#ONGOING, #CATEGORIZATION_STAGE_DATE, #FWD))){ // @todo
        case(null){}; // If there is no question with ongoing categorization_stage, there is nothing to do
        case(?iteration){
          // Verify the question categorization_stage is ongoing
          assert(iteration.current_vote == #CATEGORIZATION);
          let categorization = Iteration.unwrapCategorization(iteration);
          // If enough time has passed, put the categorization_stage at done and save its aggregate
          if (time_now > categorization.date + Utils.toTime(params_.categorization_duration)) {
            let new_iteration = Iteration.updateCurrentVote(iteration, #NONE, ?time_now);
            // Prune convictions of user who give their opinion on this question to force to recompute their categorization
            // @todo: think about making questions module observable to add pruneConvictions as an observer
            // @todo: updating your opinion shall also prune the convictions! right now this does not cause any 
            // problem because opinions cannot be changed after categorization is done
            users.pruneConvictions(Iteration.unwrapOpinion(iteration).ballots);
            return (Iterations.updateIteration(iterations, new_iteration), ?new_iteration);
          };
        };
      };
      (iterations, null);
    };

  };

};