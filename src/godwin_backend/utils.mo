import Types "types";
import Questions "questions/questions";
import Users "users";
import StageHistory "stageHistory";
import Categorizations "votes/categorizations";

import Result "mo:base/Result";
import Array "mo:base/Array";
import TrieSet "mo:base/TrieSet";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";

// @todo: create a separate module for wrapper functions that purpose is to return a result
module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
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
  type CategorizationArray = Types.CategorizationArray;
  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Users = Users.Users;
  type Categorizations = Categorizations.Categorizations;

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
    #InvalidCategorization;
  };

  public func fromArray<K, V>(array: [(K, V)], key: (K) -> Key<K>, equal: (K, K) -> Bool) : Trie<K, V> {
    var trie = Trie.empty<K, V>();
    for ((k, v) in Array.vals(array)){
      trie := Trie.put(trie, key(k), equal, v).0;
    };
    trie;
  };

  public func toArray<K, V>(trie: Trie<K, V>) : [(K, V)] {
    let buffer = Buffer.Buffer<(K, V)>(Trie.size(trie));
    for (key_val in Trie.iter(trie)) {
      buffer.add(key_val);
    };
    buffer.toArray();
  };

  public func getVerifiedCategorization(categorizations: Categorizations, array: CategorizationArray) : Result<Categorization, CategorizationError> {
    var trie = fromArray(array, Types.keyText, Text.equal);
    if (not categorizations.isAcceptableCategorization(trie)){
      return #err(#InvalidCategorization);
    };
    return #ok(trie);
  };

  public type VerifySelectionStageError = {
    #WrongSelectionStage;
  };

  public func verifyCurrentSelectionStage(question: Question, stages: [SelectionStage]) : Result<(), VerifySelectionStageError> {
    let current_stage = StageHistory.getActiveStage(question.selection_stage).stage;
    for (stage in Array.vals(stages)){
      if (stage == current_stage) { return #ok; };        
    };
    #err(#WrongSelectionStage);
  };

  public type VerifyCategorizationStageError = {
    #WrongCategorizationStage;
  };

  public func verifyCategorizationStage(question: Question, stages: [CategorizationStage]) : Result<(), VerifyCategorizationStageError> {
    let current_stage = StageHistory.getActiveStage(question.categorization_stage).stage;
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