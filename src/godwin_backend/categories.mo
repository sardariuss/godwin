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

  type VerifyOrientedCategoryError = {
    #CategoryNotFound;
  };

  public func fromArray(definition_array: [{category: Category; sides: Sides}]) : CategoriesDefinition {
    var definition_trie = Trie.empty<Category, Sides>();
    for (elem in Array.vals(definition_array)){
      definition_trie := Trie.put(definition_trie, Types.keyText(elem.category), Text.equal, elem.sides).0;
    };
    definition_trie;
  };

  public func verifyOrientedCategory(definition: CategoriesDefinition, category: OrientedCategory) : Result<(), VerifyOrientedCategoryError> {
    switch(Trie.get(definition, Types.keyText(category.category), Text.equal)){
      case(null){
        #err(#CategoryNotFound);
      };
      case(?category){
        #ok;
      };
    };
  };

  public func computeCategoriesAggregation(
    definition: CategoriesDefinition,
    aggregation_params: AggregationParameters,
    register_categories: VoteRegister<OrientedCategory>,
    question_id: Nat)
  : [OrientedCategory] {
    var categories : Buffer.Buffer<OrientedCategory> = Buffer.Buffer<OrientedCategory>(0);
    let total_all = Float.fromInt(Votes.getTotalVotes<OrientedCategory>(register_categories, question_id).all);
    for ((category, _) in Trie.iter(definition)){
      let category_a = { category = category; direction = #LR; };
      let category_b = { category = category; direction = #RL; };
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
    return categories.toArray();
  };

};