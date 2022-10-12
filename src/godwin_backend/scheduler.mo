import Types "types";
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
  type CategoriesDefinition = Types.CategoriesDefinition;
  type Categorization = Types.Categorization;
  type SchedulerParams = Types.SchedulerParams;
  // For convenience: from other modules
  type Users = Users.Users;
  type Questions = Questions.Questions;
  type Categorizations = Categorizations.Categorizations;
  type Opinions = Opinions.Opinions;

  public class Scheduler(params: SchedulerParams, last_selection_date: Time){
    
    /// Members
    let params_ = params;
    var last_selection_date_ = last_selection_date;

    public func getParams(): SchedulerParams {
      params_;
    };

    public func getLastSelectionDate(): Time {
      last_selection_date_;
    };

    public func selectQuestion(questions: Questions, time_now: Time) {
      if (last_selection_date_ + params_.selection_interval < time_now) {
        switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#CREATED, #ENDORSEMENTS, #BWD))){
          case(null){};
          case(?question){
            // Verify the question is in the created selection_stage
            if (StageHistory.getActiveStage(question.selection_stage) != #CREATED){
              Debug.trap("Question is not in the created selection_stage.");
            };
            questions.replaceQuestion({
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              selection_stage = StageHistory.setActiveStage(question.selection_stage, #SELECTED);
              categorization_stage = question.categorization_stage;
            });
            last_selection_date_ := time_now;
          };
        };
      };
    };

    public func archivedQuestion(questions: Questions, time_now: Time) {
      switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#SELECTED, #SELECTION_STAGE_DATE, #FWD))){
        case(null){};
        case(?question){
          // Verify the question is in the selected selection_stage
          if (StageHistory.getActiveStage(question.selection_stage) != #SELECTED){
            Debug.trap("The question is not in the selected selection_stage.");
          };
          // If enough time has passed, archived the question
          if (time_now > StageHistory.getActiveTimestamp(question.selection_stage) + params_.selected_duration) {
            questions.replaceQuestion({
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              selection_stage = StageHistory.setActiveStage(question.selection_stage, #ARCHIVED);
              categorization_stage = StageHistory.setActiveStage(question.categorization_stage, #ONGOING);
            });
          };
        };
      };
    };

    public func closeCategorization(questions: Questions, users: Users, opinions: Opinions, categorizations: Categorizations, time_now: Time) {
      // Get the oldest question currently being categorized
      switch(Questions.nextQuestion(questions, questions.getInCategorizationStage(#ONGOING, #CATEGORIZATION_STAGE_DATE, #FWD))){
        case(null){}; // If there is no question with ongoing categorization_stage, there is nothing to do
        case(?question){
          // Verify the question categorization_stage is ongoing
          if (StageHistory.getActiveStage(question.categorization_stage) != #ONGOING){
            Debug.trap("The question categorization_stage is not ongoing.");
          };
          // If enough time has passed, put the categorization_stage at done and save its aggregation
          if (time_now > StageHistory.getActiveTimestamp(question.categorization_stage) + params_.categorization_stage_duration) {
            questions.replaceQuestion({
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              selection_stage = question.selection_stage;
              categorization_stage =  StageHistory.setActiveStage(
                question.categorization_stage, 
                #DONE(categorizations.getAggregatedCategorization(question.id))
              );
            });
            // Prune convictions of user who give their opinion on this question to force to recompute their categorization
            users.pruneConvictions(opinions, question);
          };
        };
      };
    };

  };

};