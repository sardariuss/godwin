import Types "types";
import Questions "questions/questions";

import Result "mo:base/Result";
import Array "mo:base/Array";
import TrieSet "mo:base/TrieSet";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";
import Nat "mo:base/Nat";
import Text "mo:base/Text";
import Time "mo:base/Time";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Trie<K, V> = Trie.Trie<K, V>;
  type TrieMap<K, V> = TrieMap.TrieMap<K, V>;
  type Time = Time.Time;

  // For convenience: from types module
  type Category = Types.Category;
  type Question = Types.Question;
  type CategoriesDefinition = Types.CategoriesDefinition;
  type Pool = Types.Pool;
  type Profile = Types.Profile;
  type InputParameters = Types.InputParameters;
  type InputCategoriesDefinition = Types.InputCategoriesDefinition;
  type Parameters = Types.Parameters;
  type Duration = Types.Duration;
  type Sides = Types.Sides;
  type Categorization = Types.Categorization;

  // For convenience: from other modules
  type QuestionRegister = Questions.QuestionRegister;

  type GetQuestionError = {
    #QuestionNotFound;
  };
  
  public func getQuestion(register: QuestionRegister, question_id: Nat) : Result<Question, GetQuestionError> {
    switch(Trie.get(register.questions, Types.keyNat(question_id), Nat.equal)){
      case(null){ #err(#QuestionNotFound); };
      case(?question){ #ok(question); };
    };
  };

  type ProfileError = {
    #InvalidCategory;
    #CategoriesMissing;
  };

  public func getVerifiedProfile(definitions: CategoriesDefinition, profile: [(Text, Float)]) : Result<Profile, ProfileError> {
    var verified_profile = Trie.empty<Category, Float>();
    for ((category, cursor) in Array.vals(profile)){
      switch(Trie.get(definitions, Types.keyText(category), Text.equal)){
        case(null) { return #err(#InvalidCategory); };
        case(_) { verified_profile := Trie.put(verified_profile, Types.keyText(category), Text.equal, cursor).0;}
      };
    };
    if (Trie.size(verified_profile) != Trie.size(definitions)){
      #err(#CategoriesMissing);
    } else {
      #ok(verified_profile); 
    };
  };

  public type VerifyPoolError = {
    #WrongPool;
  };

  public func verifyCurrentPool(question: Question, pools: [Pool]) : Result<(), VerifyPoolError> {
    let set_pools = TrieSet.fromArray<Pool>(pools, Types.hashPool, Types.equalPool);
    let current_pool = question.pool.current.pool;
    switch(Trie.get(set_pools, { key = current_pool; hash = Types.hashPool(current_pool) }, Types.equalPool)){
      case(null){ #err(#WrongPool); };
      case(?pool){ #ok; };
    };
  };

  public type VerifyCategorizationError = {
    #WrongCategorizationStage;
  };

  public func verifyCategorizationStage(question: Question, stages: [Categorization]) : Result<(), VerifyCategorizationError> {
    let set_stages = TrieSet.fromArray<Categorization>(stages, Types.hashCategorization, Types.equalCategorization);
    let current_stage = question.categorization.current.categorization;
    switch(Trie.get(set_stages, { key = current_stage; hash = Types.hashCategorization(current_stage) }, Types.equalCategorization)){
      case(null){ #err(#WrongCategorizationStage); };
      case(?stage){ #ok; };
    };
  };

  public func getParameters(input: InputParameters) : Parameters {
    {
      selection_interval = toTime(input.selection_interval);
      reward_duration = toTime(input.reward_duration);
      categorization_duration = toTime(input.categorization_duration);
      categories_definition = toCategoriesDefinition(input.categories_definition);
    }
  };

  func toTime(duration: Duration) : Time {
    switch(duration) {
      case(#DAYS(days)){ days * 24 * 60 * 60 * 1_000_000_000; };
      case(#HOURS(hours)){ hours * 60 * 60 * 1_000_000_000; };
      case(#MINUTES(minutes)){ minutes * 60 * 1_000_000_000; };
      case(#SECONDS(seconds)){ seconds * 1_000_000_000; };
    };
  };

  func toCategoriesDefinition(input: InputCategoriesDefinition) : CategoriesDefinition {
    var categories_definition = Trie.empty<Category, Sides>();
    for ((category, side) in Array.vals(input)){
      categories_definition := Trie.put(categories_definition, Types.keyText(category), Text.equal, side).0;
    };
    categories_definition;
  };

};