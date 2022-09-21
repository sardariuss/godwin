import Types "types";
import Questions "questions";

import Result "mo:base/Result";
import Array "mo:base/Array";
import TrieSet "mo:base/TrieSet";
import Trie "mo:base/Trie";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type CategoryDefinition = Types.CategoryDefinition;
  type Question = Types.Question;
  type OrientedCategory = Types.OrientedCategory;
  type CategoriesDefinition = Types.CategoriesDefinition;
  type Pool = Types.Pool;

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

  type VerifyOrientedCategoryError = {
    #CategoryNotFound;
  };

  public func verifyOrientedCategory(definitions: CategoriesDefinition, oriented_category: OrientedCategory) : Result<(), VerifyOrientedCategoryError> {
    switch(Array.find(definitions, func(definition: CategoryDefinition) : Bool { definition.category == oriented_category.category; })){
      case(null){ #err(#CategoryNotFound); };
      case(?category){ #ok; };
    };
  };

  type CanCategorizeError = {
    #WrongCategorizationState;
  };

  public func canCategorize(question: Question) : Result<(), CanCategorizeError> {
    if(question.categorization.current.categorization == #ONGOING) { #ok;} 
    else { #err(#WrongCategorizationState); };
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

};