import Types "../types";
import Queries "queries";
import StageHistory "../stageHistory";

import Debug "mo:base/Debug";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type CategorizationStage = Types.CategorizationStage;

  public type PerCategorizationStage = {
    pending_rbts: Queries.QuestionRBTs;
    ongoing_rbts: Queries.QuestionRBTs;
    done_rbts: Queries.QuestionRBTs;
  };

  public func empty() : PerCategorizationStage {
    let pending_rbts = Queries.init();
    var ongoing_rbts = Queries.init();
    ongoing_rbts := Queries.addOrderBy(ongoing_rbts, #CATEGORIZATION_STAGE_DATE);
    let done_rbts = Queries.init();
    { pending_rbts; ongoing_rbts; done_rbts; };
  };

  func getCategorizationStageRBTs(per_cat: PerCategorizationStage, categorization_stage: CategorizationStage) : Queries.QuestionRBTs {
    switch(categorization_stage){
      case(#PENDING){ per_cat.pending_rbts; };
      case(#ONGOING){ per_cat.ongoing_rbts; };
      case(#DONE(_)){ per_cat.done_rbts; };
    };
  };

  func setCategorizationStageRBTs(per_cat: PerCategorizationStage, categorization_stage: CategorizationStage, rbts: Queries.QuestionRBTs) : PerCategorizationStage {
    switch(categorization_stage){
      case(#PENDING){ { pending_rbts = rbts;                 ongoing_rbts = per_cat.ongoing_rbts; done_rbts = per_cat.done_rbts; }; };
      case(#ONGOING){ { pending_rbts = per_cat.pending_rbts; ongoing_rbts = rbts;                 done_rbts = per_cat.done_rbts; }; };
      case(#DONE(_)){ { pending_rbts = per_cat.pending_rbts; ongoing_rbts = per_cat.ongoing_rbts; done_rbts = rbts;              }; };
    };
  };

  public func addQuestion(per_cat: PerCategorizationStage, question: Question) : PerCategorizationStage {
    if (StageHistory.getActiveStage(question.categorization_stage) != #PENDING) {
      Debug.trap("Cannot add a question which categorization_stage is different from #PENDING");
    };
    {
      pending_rbts = Queries.add(per_cat.pending_rbts, question);
      ongoing_rbts = per_cat.ongoing_rbts;
      done_rbts = per_cat.done_rbts;
    };
  };

  public func replaceQuestion(per_cat: PerCategorizationStage, old_question: Question, new_question: Question) : PerCategorizationStage {
    var updated_per_cat = per_cat;
    let old_stage = StageHistory.getActiveStage(old_question.categorization_stage);
    let new_stage = StageHistory.getActiveStage(new_question.categorization_stage);
    if (old_stage == new_stage) {
      // Replace in current categorization_stage
      var rbts = getCategorizationStageRBTs(updated_per_cat, old_stage);
      rbts := Queries.replace(rbts, old_question, new_question);
      updated_per_cat := setCategorizationStageRBTs(updated_per_cat, old_stage, rbts);
    } else {
      // Remove from previous categorization_stage
      var rbts_1 = getCategorizationStageRBTs(updated_per_cat, old_stage);
      rbts_1 := Queries.remove(rbts_1, old_question);
      updated_per_cat := setCategorizationStageRBTs(updated_per_cat, old_stage, rbts_1);
      // Add in new categorization_stage
      var rbts_2 = getCategorizationStageRBTs(updated_per_cat, new_stage);
      rbts_2 := Queries.add(rbts_2, new_question);
      updated_per_cat := setCategorizationStageRBTs(updated_per_cat, new_stage, rbts_2);
    };
    updated_per_cat;
  };

  public func removeQuestion(per_cat: PerCategorizationStage, question: Question) : PerCategorizationStage {
    let current_stage = StageHistory.getActiveStage(question.categorization_stage);
    var rbts = getCategorizationStageRBTs(per_cat, current_stage);
    rbts := Queries.remove(rbts, question);
    setCategorizationStageRBTs(per_cat, current_stage, rbts);
  };

};