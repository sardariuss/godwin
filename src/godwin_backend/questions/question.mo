import Types "../types";
import StageHistory "../stageHistory";

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Text "mo:base/Text";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type SelectionStage = Types.SelectionStage;
  type SelectionStageEnum = Types.SelectionStageEnum;
  type CategorizationStage = Types.CategorizationStage;
  type CategorizationStageEnum = Types.CategorizationStageEnum;
  type InterestAggregate = Types.InterestAggregate;

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

  public func updateTotalInterests(question: Question, interests: InterestAggregate) : Question {
    {
      id = question.id;
      author = question.author;
      title = question.title;
      text = question.text;
      date = question.date;
      interests = interests;
      selection_stage = question.selection_stage;
      categorization_stage = question.categorization_stage;
    };
  };

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("title: " # question.title # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    buffer.add("interests: " # Int.toText(question.interests.score) # ", ");
    // buffer.add(.toText(question.selection_stage)); // @todo
    // buffer.add(.toText(question.categorization_stage)); // @todo
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
        and Principal.equal(q1.author, q2.author)
        and Text.equal(q1.title, q2.title)
        and Text.equal(q1.text, q2.text)
        and Int.equal(q1.date, q2.date)
        and Int.equal(q1.interests.score, q2.interests.score);
        // @todo
  };

};