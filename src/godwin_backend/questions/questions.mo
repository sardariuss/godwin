import Types "../types";
import PerSelectionStage "perSelectionStage";
import PerCategorizationStage "perCategorizationStage";
import Queries "queries";
import StageHistory "../stageHistory";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Time = Time.Time;
  type Iter<T> = Iter.Iter<T>;
  // For convenience: from types module
  type Question = Types.Question;
  type SelectionStageEnum = Types.SelectionStageEnum;
  type CategorizationStageEnum = Types.CategorizationStageEnum;
  // For convenience: from other modules
  type PerSelectionStage = PerSelectionStage.PerSelectionStage;
  type PerCategorizationStage = PerCategorizationStage.PerCategorizationStage;
  type QuestionKey = Queries.QuestionKey;
  type OrderBy = Queries.OrderBy;
  type QueryDirection = Queries.QueryDirection;

  type Register = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
    per_selection_stage: PerSelectionStage;
    per_categorization_stage : PerCategorizationStage;
  };

  public func empty() : Questions {
    Questions({
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
      per_selection_stage = PerSelectionStage.empty();
      per_categorization_stage = PerCategorizationStage.empty();
    });
  };

  public class Questions(register: Register) {

    /// Members
    var register_ = register;

    public func share() : Register {
      register_;
    };

    public func getQuestion(question_id: Nat) : Question {
      switch(findQuestion(question_id)){
        case(null) { Debug.trap("The question does not exist."); };
        case(?question) { question; };
      };
    };

    public func findQuestion(question_id: Nat) : ?Question {
      Trie.get(register_.questions, Types.keyNat(question_id), Nat.equal);
    };

    public func getInSelectionStage(selection_stage: SelectionStageEnum, order_by: OrderBy, direction: QueryDirection) : Iter<(QuestionKey, ())> {
      switch(selection_stage){
        case(#CREATED){ Queries.entries(register_.per_selection_stage.created_rbts, order_by, direction); };
        case(#SELECTED){ Queries.entries(register_.per_selection_stage.selected_rbts, order_by, direction); };
        case(#ARCHIVED){ Queries.entries(register_.per_selection_stage.archived_rbts, order_by, direction); };
      };
    };

    public func getInCategorizationStage(categorization_stage: CategorizationStageEnum, order_by: OrderBy, direction: QueryDirection) : Iter<(QuestionKey, ())> {
      switch(categorization_stage){
        case(#PENDING) { Queries.entries(register_.per_categorization_stage.pending_rbts, order_by, direction); }; 
        case(#ONGOING) { Queries.entries(register_.per_categorization_stage.ongoing_rbts, order_by, direction); }; 
        case(#DONE) { Queries.entries(register_.per_categorization_stage.done_rbts, order_by, direction); }; 
      };
    };

    public func createQuestion(author: Principal, date: Time, title: Text, text: Text) : Question {
      let question = {
        id = register_.question_index;
        author = author;
        title = title;
        text = text;
        date = date;
        endorsements = 0;
        selection_stage = StageHistory.initStageHistory({ timestamp = date; stage = #CREATED; });
        categorization_stage =  StageHistory.initStageHistory({ timestamp = date; stage = #PENDING; });
      };
      register_ := {
        questions = Trie.put(register_.questions, Types.keyNat(question.id), Nat.equal, question).0;
        question_index = register_.question_index + 1;
        per_selection_stage = PerSelectionStage.addQuestion(register_.per_selection_stage, question);
        per_categorization_stage = PerCategorizationStage.addQuestion(register_.per_categorization_stage, question);
      };
      question;
    };

    public func replaceQuestion(question: Question) {
      let (questions, removed_question) = Trie.put(register_.questions, Types.keyNat(question.id), Nat.equal, question);
      switch(removed_question){
        case(null) { Debug.trap("Cannot replace a question that does not exist"); };
        case(?old_question) {
          register_ := {
            questions = questions;
            question_index = register_.question_index;
            per_selection_stage = PerSelectionStage.replaceQuestion(register_.per_selection_stage, old_question, question);
            per_categorization_stage = PerCategorizationStage.replaceQuestion(register_.per_categorization_stage, old_question, question);
          };
        };
      };
    };

  };

  public func nextQuestion(questions: Questions, iter: Iter<(QuestionKey, ())>) : ?Question {
    switch(iter.next()){
      case(null) { null; };
      case(?(question_key, _)){ ?questions.getQuestion(question_key.id); };
    };
  };

};