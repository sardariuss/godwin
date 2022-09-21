import Votes "votes";
import Types "types";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Float "mo:base/Float";
import Array "mo:base/Array";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  // For convenience: from types module
  type Category = Types.Category;
  type Sides = Types.Sides;
  type OrientedCategory = Types.OrientedCategory;
  type AggregationParameters = Types.AggregationParameters;
  type VoteRegister<B> = Types.VoteRegister<B>;
  type CategoriesDefinition = Types.CategoriesDefinition;
  type CategoryDefinition = Types.CategoryDefinition;
  type Question = Types.Question;

  type VerifyOrientedCategoryError = {
    #CategoryNotFound;
  };

  public func verifyOrientedCategory(definitions: CategoriesDefinition, oriented_category: OrientedCategory) : Result<(), VerifyOrientedCategoryError> {
    switch(Array.find(definitions, func(definition: CategoryDefinition) : Bool { definition.category == oriented_category.category; })){
      case(null){
        #err(#CategoryNotFound);
      };
      case(?category){
        #ok;
      };
    };
  };

  public func computeCategoriesAggregation(
    definitions: CategoriesDefinition,
    aggregation_params: AggregationParameters,
    register_categories: VoteRegister<OrientedCategory>,
    question_id: Nat)
  : [OrientedCategory] {
    var categories : Buffer.Buffer<OrientedCategory> = Buffer.Buffer<OrientedCategory>(0);
    let total_all = Float.fromInt(Votes.getTotalVotes<OrientedCategory>(register_categories, question_id).all);
    for (definition in Array.vals(definitions)){
      let category_a = { category = definition.category; direction = #LR; };
      let category_b = { category = definition.category; direction = #RL; };
      let total_a = Float.fromInt(Votes.getTotalVotesForBallot(register_categories, question_id, Types.hashOrientedCategory, Types.equalOrientedCategory, category_a));
      let total_b = Float.fromInt(Votes.getTotalVotesForBallot(register_categories, question_id, Types.hashOrientedCategory, Types.equalOrientedCategory, category_b));
      if (((total_a + total_b) / total_all) > aggregation_params.category_threshold){
        let total_category = total_a + total_b;
        if ((total_a / total_category) > aggregation_params.direction_threshold){
          categories.add(category_a);
        } else if ((total_b / total_category) > aggregation_params.direction_threshold){
          categories.add(category_b);
        };
      };
    };
    categories.toArray();
  };

  type CanCategorizeError = {
    #WrongCategorizationState;
  };

  public func canCategorize(question: Question) : Result<(), CanCategorizeError> {
    if(question.categorization.current.categorization == #ONGOING) { #ok;} 
    else { #err(#WrongCategorizationState); };
  };

};