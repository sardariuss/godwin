import Types "../types";
import StageHistory "../stageHistory";
import Polarization "../representation/polarization";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Time "mo:base/Time";

module {

  // For convenience: from base module
  type Time = Time.Time;

  // For convenience: from types module
  type Question = Types.Question;
  type SelectionStage = Types.SelectionStage;
  type SelectionStageEnum = Types.SelectionStageEnum;
  type CategorizationStage = Types.CategorizationStage;
  type CategorizationStageEnum = Types.CategorizationStageEnum;
  type InterestAggregate = Types.InterestAggregate;
  type Polarization = Types.Polarization;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Category = Types.Category;

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

  public func createQuestion(id: Nat, author: Principal, date: Time, title: Text, text: Text, categories: [Category]) : Question {
    {
      id;
      author;
      title;
      text;
      date;
      aggregates = {
        interest = { ups = 0; downs = 0; score = 0; };
        opinion = Polarization.nil();
        categorization = CategoryPolarizationTrie.nil(categories);
      };
      selection_stage = StageHistory.initStageHistory({ timestamp = date; stage = #CREATED; });
      categorization_stage =  StageHistory.initStageHistory({ timestamp = date; stage = #PENDING; });
    };
  };

  public func updateInterestAggregate(question: Question, interest: InterestAggregate) : Question {
    {
      id = question.id;
      author = question.author;
      title = question.title;
      text = question.text;
      date = question.date;
      aggregates = {
        interest;
        opinion = question.aggregates.opinion;
        categorization = question.aggregates.categorization;
      };
      selection_stage = question.selection_stage;
      categorization_stage = question.categorization_stage;
    };
  };

  public func updateOpinionAggregate(question: Question, opinion: Polarization) : Question {
    {
      id = question.id;
      author = question.author;
      title = question.title;
      text = question.text;
      date = question.date;
      aggregates = {
        interest = question.aggregates.interest;
        opinion;
        categorization = question.aggregates.categorization;
      };
      selection_stage = question.selection_stage;
      categorization_stage = question.categorization_stage;
    };
  };

  public func updateCategorizationAggregate(question: Question, categorization: CategoryPolarizationTrie) : Question {
    {
      id = question.id;
      author = question.author;
      title = question.title;
      text = question.text;
      date = question.date;
      aggregates = {
        interest = question.aggregates.interest;
        opinion = question.aggregates.opinion;
        categorization;
      };
      selection_stage = question.selection_stage;
      categorization_stage = question.categorization_stage;
    };
  };

  public func updateDate(question: Question, date: Time) : Question {
    {
      id = question.id;
      author = question.author;
      title = question.title;
      text = question.text;
      date;
      aggregates = question.aggregates;
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
    buffer.add("interest: " # Int.toText(question.aggregates.interest.score) # ", ");
    // @todo
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
        and Principal.equal(q1.author, q2.author)
        and Text.equal(q1.title, q2.title)
        and Text.equal(q1.text, q2.text)
        and Int.equal(q1.date, q2.date)
        and Int.equal(q1.aggregates.interest.score, q2.aggregates.interest.score);
        // @todo
  };

};