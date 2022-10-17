import Types "../types";
import StageHistory "../stageHistory";

import Array "mo:base/Array";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type SelectionStage = Types.SelectionStage;
  type CategorizationStage = Types.CategorizationStage;

  public func verifyCurrentSelectionStage(question: Question, stages: [SelectionStage]) : ?Question {
    let current_stage = StageHistory.getActiveStage(question.selection_stage).stage;
    for (stage in Array.vals(stages)){
      if (stage == current_stage) { return ?question; };        
    };
    null;
  };

  public func verifyCategorizationStage(question: Question, stages: [CategorizationStage]) : ?Question {
    let current_stage = StageHistory.getActiveStage(question.categorization_stage).stage;
    // @todo: if stage is done it won't work
    for (stage in Array.vals(stages)){
      if (stage == current_stage) { return ?question; };        
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