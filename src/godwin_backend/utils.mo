import Types "types";
import Questions "questions/questions";
import Users "users";
import StageHistory "stageHistory";

import Result "mo:base/Result";
import Array "mo:base/Array";
import TrieSet "mo:base/TrieSet";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Trie<K, V> = Trie.Trie<K, V>;
  //type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
  type Time = Time.Time;
  // For convenience: from types module
  type Category = Types.Category;
  type Question = Types.Question;
  type CategoriesDefinition = Types.CategoriesDefinition;
  type SelectionStage = Types.SelectionStage;
  type Categorization = Types.Categorization;
  type InputParameters = Types.InputParameters;
  type InputCategoriesDefinition = Types.InputCategoriesDefinition;
  type Parameters = Types.Parameters;
  type Duration = Types.Duration;
  type Sides = Types.Sides;
  type CategorizationStage = Types.CategorizationStage;
  type User = Types.User;
  type InputSchedulerParams = Types.InputSchedulerParams;
  type SchedulerParams = Types.SchedulerParams;
  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;

  type GetQuestionError = {
    #QuestionNotFound;
  };
  
  public func getQuestion(questions: Questions, question_id: Nat) : Result<Question, GetQuestionError> {
    switch(questions.findQuestion(question_id)){
      case(null){ #err(#QuestionNotFound); };
      case(?question){ #ok(question); };
    };
  };

  type CategorizationError = {
    #InvalidCategory;
    #CategoriesMissing;
  };

  public func getVerifiedCategorization(definitions: CategoriesDefinition, categorization: [(Text, Float)]) : Result<Categorization, CategorizationError> {
    var verified_categorization = Trie.empty<Category, Float>();
    for ((category, cursor) in Array.vals(categorization)){
      switch(Trie.get(definitions, Types.keyText(category), Text.equal)){
        case(null) { return #err(#InvalidCategory); };
        case(_) { verified_categorization := Trie.put(verified_categorization, Types.keyText(category), Text.equal, cursor).0;}
      };
    };
    if (Trie.size(verified_categorization) != Trie.size(definitions)){
      #err(#CategoriesMissing);
    } else {
      #ok(verified_categorization); 
    };
  };

  public type VerifySelectionStageError = {
    #WrongSelectionStage;
  };

  public func verifyCurrentSelectionStage(question: Question, stages: [SelectionStage]) : Result<(), VerifySelectionStageError> {
    let current_stage = StageHistory.getActiveStage(question.selection_stage);
    for (stage in Array.vals(stages)){
      if (stage == current_stage) { return #ok; };        
    };
    #err(#WrongSelectionStage);
  };

  public type VerifyCategorizationStageError = {
    #WrongCategorizationStage;
  };

  public func verifyCategorizationStage(question: Question, stages: [CategorizationStage]) : Result<(), VerifyCategorizationStageError> {
    let current_stage = StageHistory.getActiveStage(question.categorization_stage);
    for (stage in Array.vals(stages)){
      if (stage == current_stage) { return #ok; };        
    };
    #err(#WrongCategorizationStage);
  };

  public func toSchedulerParams(input_params: InputSchedulerParams) : SchedulerParams {
    {
      selection_interval = toTime(input_params.selection_interval);
      selected_duration = toTime(input_params.selected_duration);
      categorization_stage_duration = toTime(input_params.categorization_stage_duration);
    };
  };

  func toTime(duration: Duration) : Time {
    switch(duration) {
      case(#DAYS(days)){ days * 24 * 60 * 60 * 1_000_000_000; };
      case(#HOURS(hours)){ hours * 60 * 60 * 1_000_000_000; };
      case(#MINUTES(minutes)){ minutes * 60 * 1_000_000_000; };
      case(#SECONDS(seconds)){ seconds * 1_000_000_000; };
    };
  };

  public func toCategoriesDefinition(input: InputCategoriesDefinition) : CategoriesDefinition {
    var categories_definition = Trie.empty<Category, Sides>();
    for ((category, side) in Array.vals(input)){
      categories_definition := Trie.put(categories_definition, Types.keyText(category), Text.equal, side).0;
    };
    categories_definition;
  };

  public type GetOrCreateUserError = {
    #IsAnonymous;
  };

  public func getOrCreateUser(users: Users, principal: Principal) : Result<User, GetOrCreateUserError> {
    if (Principal.isAnonymous(principal)){
      #err(#IsAnonymous);
    } else {
      switch(users.getUser(principal)){
        case(?user){ #ok(user); };
        case(null){ #ok(users.createUser(principal)); };
      };
    };
  };

  public func append<T>(left: [T], right: [T]) : [T] {
    let buffer = Buffer.Buffer<T>(left.size());
    for(val in left.vals()){
      buffer.add(val);
    };
    for(val in right.vals()){
      buffer.add(val);
    };
    return buffer.toArray();
  };

};