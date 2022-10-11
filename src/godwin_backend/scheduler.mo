import Types "types";
import Questions "questions/questions";
import Categorizations "votes/categorizations";
import Opinions "votes/opinions";
import Users "users";
import Utils "utils";

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
  type Profile = Types.Profile;
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
        switch(Questions.nextQuestion(questions, questions.getQuestionsInPool(#SPAWN, #ENDORSEMENTS, #BWD))){
          case(null){};
          case(?question){
            // Verify the question is in the spawn pool
            if (question.pool.current.pool != #SPAWN){
              Debug.trap("Question is not in the spawn pool.");
            };
            questions.replaceQuestion({
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              pool = {
                current = { date = time_now; pool = #REWARD; };
                history = Utils.append(question.pool.history, [ question.pool.current ]);
              };
              categorization = question.categorization;
            });
            last_selection_date_ := time_now;
          };
        };
      };
    };

    public func archiveQuestion(questions: Questions, time_now: Time) {
      switch(Questions.nextQuestion(questions, questions.getQuestionsInPool(#REWARD, #POOL_DATE, #FWD))){
        case(null){};
        case(?question){
          // Verify the question is in the reward pool
          if (question.pool.current.pool != #REWARD){
            Debug.trap("The question is not in the reward pool.");
          };
          // If enough time has passed, archive the question
          if (time_now > question.pool.current.date + params_.reward_duration) {
            questions.replaceQuestion({
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              pool = {
                current = { date = time_now; pool = #ARCHIVE; };
                history = Utils.append(question.pool.history, [ question.pool.current ]);
              };
              categorization = {
                current = { date = time_now; categorization = #ONGOING; };
                history = Utils.append(question.categorization.history, [ question.categorization.current ]);
              };
            });
          };
        };
      };
    };

    public func closeCategorization(questions: Questions, users: Users, opinions: Opinions, categorizations: Categorizations, time_now: Time) {
      // Get the oldest question currently being categorized
      switch(Questions.nextQuestion(questions, questions.getQuestionsInCategorization(#ONGOING, #CATEGORIZATION_DATE, #FWD))){
        case(null){}; // If there is no question with ongoing categorization, there is nothing to do
        case(?question){
          // Verify the question categorization is ongoing
          if (question.categorization.current.categorization != #ONGOING){
            Debug.trap("The question categorization is not ongoing.");
          };
          // If enough time has passed, put the categorization at done and save its aggregation
          if (time_now > question.categorization.current.date + params_.categorization_duration) {
            questions.replaceQuestion({
              id = question.id;
              author = question.author;
              title = question.title;
              text = question.text;
              date = question.date;
              endorsements = question.endorsements;
              pool = question.pool;
              categorization = {
                current = { date = time_now; categorization = #DONE(categorizations.getAggregatedCategorization(question.id)); };
                history = Utils.append(question.categorization.history, [ question.categorization.current ]);
              };
            });
            // Prune convictions of user who give their opinion on this question to force to recompute their profile
            users.pruneConvictions(opinions, question);
          };
        };
      };
    };

  };

};