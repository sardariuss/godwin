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
  type SchedulerParams = Types.SchedulerParams;
  // For convenience: from other modules
  type Users = Users.Users;
  type Questions = Questions.Questions;
  type Categorizations = Categorizations.Categorizations;
  type Opinions = Opinions.Opinions;

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

    public func selectQuestion(questions: Questions, time_now: Time) : ?Question {
      if (time_now > last_selection_date_ + Utils.toTime(params_.selection_rate)) {
        switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#CREATED, #ENDORSEMENTS, #BWD))){
          case(null){};
          case(?question){
            // Verify the question is in the created selection_stage
            if (StageHistory.getActiveStage(question.selection_stage).stage != #CREATED){
              Debug.trap("Question is not in the created selection_stage.");
            };
            last_selection_date_ := time_now;
            let updated_question = {
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              selection_stage = StageHistory.setActiveStage(question.selection_stage, { stage = #SELECTED; timestamp = time_now; });
              categorization_stage = question.categorization_stage;
            };
            questions.replaceQuestion(updated_question);
            return ?updated_question;
          };
        };
      };
      null;
    };

    public func archiveQuestion(questions: Questions, opinions: Opinions, time_now: Time) : ?Question {
      switch(Questions.nextQuestion(questions, questions.getInSelectionStage(#SELECTED, #SELECTION_STAGE_DATE, #FWD))){
        case(null){};
        case(?question){
          // Verify the question is in the selected selection_stage
          let selection_stage = StageHistory.getActiveStage(question.selection_stage);
          if (selection_stage.stage != #SELECTED){
            Debug.trap("The question is not in the selected selection_stage.");
          };
          // If enough time has passed, archived the question
          if (time_now > selection_stage.timestamp + Utils.toTime(params_.selection_duration)) {
            let updated_question = {
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              selection_stage = StageHistory.setActiveStage(
                question.selection_stage,
                { stage = #ARCHIVED(opinions.getAggregate(question.id)); timestamp = time_now; }
              );
              categorization_stage = StageHistory.setActiveStage(
                question.categorization_stage,
                { stage = #ONGOING; timestamp = time_now; }
              );
            };
            questions.replaceQuestion(updated_question);
            return ?updated_question;
          };
        };
      };
      null;
    };

    public func closeCategorization(questions: Questions, users: Users, opinions: Opinions, categorizations: Categorizations, time_now: Time) : ?Question {
      // Get the oldest question currently being categorized
      switch(Questions.nextQuestion(questions, questions.getInCategorizationStage(#ONGOING, #CATEGORIZATION_STAGE_DATE, #FWD))){
        case(null){}; // If there is no question with ongoing categorization_stage, there is nothing to do
        case(?question){
          // Verify the question categorization_stage is ongoing
          let categorization_stage = StageHistory.getActiveStage(question.categorization_stage);
          if (categorization_stage.stage != #ONGOING){
            Debug.trap("The question categorization_stage is not ongoing.");
          };
          // If enough time has passed, put the categorization_stage at done and save its aggregate
          if (time_now > categorization_stage.timestamp + Utils.toTime(params_.categorization_duration)) {
            let categorization_aggregate = Utils.trieToArray(categorizations.getAggregate(question.id));
            let updated_question = {
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              selection_stage = question.selection_stage;
              categorization_stage = StageHistory.setActiveStage(question.categorization_stage, { stage = #DONE(categorization_aggregate); timestamp = time_now; });
            };
            questions.replaceQuestion(updated_question);
            // Prune convictions of user who give their opinion on this question to force to recompute their categorization
            users.pruneConvictions(opinions, question.id);
            return ?question;
          };
        };
      };
      null;
    };

  };

};