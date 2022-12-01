import Types "../types";
import PerSelectionStage "perSelectionStage";
import PerCategorizationStage "perCategorizationStage";
import Queries "queries";
import Polarization "../representation/polarization";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";
import StageHistory "../stageHistory";
import Categories "../categories";
import Question "question";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";
import Text "mo:base/Text";

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
  type Category = Types.Category;
  // For convenience: from other modules
  type PerSelectionStage = PerSelectionStage.PerSelectionStage;
  type PerCategorizationStage = PerCategorizationStage.PerCategorizationStage;
  type QuestionKey = Queries.QuestionKey;
  type OrderBy = Queries.OrderBy;
  type QueryDirection = Queries.QueryDirection;
  type Categories = Categories.Categories;
  type UpdateType = Categories.UpdateType;

  type Register = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
    per_selection_stage: PerSelectionStage;
    per_categorization_stage : PerCategorizationStage;
  };

  public func empty(categories: Categories) : Questions {
    Questions(
    {
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
      per_selection_stage = PerSelectionStage.empty();
      per_categorization_stage = PerCategorizationStage.empty();
    },
    categories);
  };

  public class Questions(register: Register, categories: Categories) {

    /// Members
    var register_ = register;
    let categories_ = categories;

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
      let question = Question.createQuestion(register_.question_index, author, date, title, text, categories_.share());
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

    public func iter() : Iter<(Nat, Question)> {
      Trie.iter(register_.questions);
    };

    /// For every question in the register, adds a null aggregate for the category
    /// \param[in] category The category to add to the categorizations
    func addCategory(category: Category) {
      for ((_, question) in Trie.iter(register_.questions)){
        let categorization = Trie.put(question.aggregates.categorization, Types.keyText(category), Text.equal, Polarization.nil()).0;
        replaceQuestion(Question.updateCategorizationAggregate(question, categorization));
      };
    };

    /// For every question in the register, remove the category's aggregate
    /// \param[in] category The category to remove from the categorizations
    func removeCategory(category: Category) {
      for ((_, question) in Trie.iter(register_.questions)){
        let categorization = Trie.remove(question.aggregates.categorization, Types.keyText(category), Text.equal).0;
        replaceQuestion(Question.updateCategorizationAggregate(question, categorization));
      };
    };

    /// Add an observer on the categories at construction, so that every time a category
    /// is added or removed, all users' convictions are pruned.
    categories_.addCallback(func(category: Category, update_type: UpdateType) { 
       switch(update_type){
        case(#CATEGORY_ADDED){ addCategory(category); };
        case(#CATEGORY_REMOVED) { removeCategory(category); };
      };
    });

  };

  public func nextQuestion(questions: Questions, iter: Iter<(QuestionKey, ())>) : ?Question {
    switch(iter.next()){
      case(null) { null; };
      case(?(question_key, _)){ ?questions.getQuestion(question_key.id); };
    };
  };

};