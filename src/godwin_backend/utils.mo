import Types "types";
import Questions "questions/questions";
import Users "users";

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
  type Pool = Types.Pool;
  type Profile = Types.Profile;
  type InputParameters = Types.InputParameters;
  type InputCategoriesDefinition = Types.InputCategoriesDefinition;
  type Parameters = Types.Parameters;
  type Duration = Types.Duration;
  type Sides = Types.Sides;
  type Categorization = Types.Categorization;
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

  public func toSchedulerParams(input_params: InputSchedulerParams) : SchedulerParams {
    {
      selection_interval = toTime(input_params.selection_interval);
      reward_duration = toTime(input_params.reward_duration);
      categorization_duration = toTime(input_params.categorization_duration);
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