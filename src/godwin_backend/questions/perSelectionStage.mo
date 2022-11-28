import Types "../types";
import Queries "queries";
import StageHistory "../stageHistory";

import Debug "mo:base/Debug";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type SelectionStage = Types.SelectionStage;

  public type PerSelectionStage = {
    created_rbts: Queries.QuestionRBTs;
    selected_rbts: Queries.QuestionRBTs;
    archived_rbts: Queries.QuestionRBTs;
  };

  public func empty() : PerSelectionStage {
    var created_rbts = Queries.init();
    created_rbts := Queries.addOrderBy(created_rbts, #ENDORSEMENTS);
    created_rbts := Queries.addOrderBy(created_rbts, #CREATION_HOT);
    var selected_rbts = Queries.init();
    selected_rbts := Queries.addOrderBy(created_rbts, #SELECTION_STAGE_DATE);
    let archived_rbts = Queries.init();
    { created_rbts; selected_rbts; archived_rbts; };
  };

  func getSelectionStageRBTs(per_selection_stage: PerSelectionStage, selection_stage: SelectionStage) : Queries.QuestionRBTs {
    switch(selection_stage){
      case(#CREATED){ per_selection_stage.created_rbts; };
      case(#SELECTED){ per_selection_stage.selected_rbts; };
      case(#ARCHIVED(_)){ per_selection_stage.archived_rbts; };
    };
  };

  func setSelectionStageRBTs(per_selection_stage: PerSelectionStage, selection_stage: SelectionStage, rbts: Queries.QuestionRBTs) : PerSelectionStage {
    switch(selection_stage){
      case(#CREATED){     { created_rbts = rbts;                             selected_rbts = per_selection_stage.selected_rbts; archived_rbts = per_selection_stage.archived_rbts; }; };
      case(#SELECTED){    { created_rbts = per_selection_stage.created_rbts; selected_rbts = rbts;                              archived_rbts = per_selection_stage.archived_rbts; }; };
      case(#ARCHIVED(_)){ { created_rbts = per_selection_stage.created_rbts; selected_rbts = per_selection_stage.selected_rbts; archived_rbts = rbts;                              }; };
    };
  };

  public func addQuestion(per_selection_stage: PerSelectionStage, question: Question) : PerSelectionStage {
    if (StageHistory.getActiveStage(question.selection_stage).stage != #CREATED) {
      Debug.trap("Cannot add a question which current selection_stage is different from #CREATED");
    };
    {
      created_rbts = Queries.add(per_selection_stage.created_rbts, question);
      selected_rbts = per_selection_stage.selected_rbts;
      archived_rbts = per_selection_stage.archived_rbts;
    };
  };

  public func replaceQuestion(per_selection_stage: PerSelectionStage, old_question: Question, new_question: Question) : PerSelectionStage {
    var updated_per_selection_stage = per_selection_stage;
    let old_selection_stage = StageHistory.getActiveStage(old_question.selection_stage).stage;
    let new_selection_stage = StageHistory.getActiveStage(new_question.selection_stage).stage;
    if (old_selection_stage == new_selection_stage) {
      // Replace in current selection_stage
      var rbts = getSelectionStageRBTs(updated_per_selection_stage, old_selection_stage);
      rbts := Queries.replace(rbts, old_question, new_question);
      updated_per_selection_stage := setSelectionStageRBTs(updated_per_selection_stage, old_selection_stage, rbts);
    } else {
      // Remove from previous selection_stage
      var rbts_1 = getSelectionStageRBTs(updated_per_selection_stage, old_selection_stage);
      rbts_1 := Queries.remove(rbts_1, old_question);
      updated_per_selection_stage := setSelectionStageRBTs(updated_per_selection_stage, old_selection_stage, rbts_1);
      // Add in new selection_stage
      var rbts_2 = getSelectionStageRBTs(updated_per_selection_stage, new_selection_stage);
      rbts_2 := Queries.add(rbts_2, new_question);
      updated_per_selection_stage := setSelectionStageRBTs(updated_per_selection_stage, new_selection_stage, rbts_2);
    };
    updated_per_selection_stage;
  };

  public func removeQuestion(per_selection_stage: PerSelectionStage, question: Question) : PerSelectionStage {
    let current_selection_stage = StageHistory.getActiveStage(question.selection_stage).stage;
    var rbts = getSelectionStageRBTs(per_selection_stage, current_selection_stage);
    rbts := Queries.remove(rbts, question);
    setSelectionStageRBTs(per_selection_stage, current_selection_stage, rbts);
  };

};