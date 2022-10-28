import Types "../types";
import StageHistory "../stageHistory";

import Array "mo:base/Array";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type SelectionStage = Types.SelectionStage;
  type SelectionStageEnum = Types.SelectionStageEnum;
  type CategorizationStage = Types.CategorizationStage;
  type CategorizationStageEnum = Types.CategorizationStageEnum;

  public func verifyCurrentSelectionStage(question: Question, stages: [SelectionStageEnum]) : ?Question {
    let current_stage = StageHistory.getActiveStage(question.selection_stage).stage;
    for (stage in Array.vals(stages)){
      switch(current_stage){
        case(#CREATED) { if (stage == #CREATED) { return ?question; }; };
        case(#SELECTED) { if (stage == #SELECTED) { return ?question; }; };
        case(#ARCHIVED(_)) { if (stage == #ARCHIVED) { return ?question; }; };
      };
    };
    null;
  };

  public func verifyCategorizationStage(question: Question, stages: [CategorizationStageEnum]) : ?Question {
    let current_stage = StageHistory.getActiveStage(question.categorization_stage).stage;
    for (stage in Array.vals(stages)){
      switch(current_stage){
        case(#PENDING) { if (stage == #PENDING) { return ?question; }; };
        case(#ONGOING) { if (stage == #ONGOING) { return ?question; }; };
        case(#DONE(_)) { if (stage == #DONE) { return ?question; }; };
      };
    };
    null;
  };

  public func updateTotalEndorsements(question: Question, total_endorsements: Nat) : Question {
    {
      id = question.id;
      author = question.author;
      title = question.title;
      text = question.text;
      date = question.date;
      endorsements = total_endorsements;
      selection_stage = question.selection_stage;
      categorization_stage = question.categorization_stage;
    };
  };

};