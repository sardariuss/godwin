import Register "register";
import Types "types";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Float "mo:base/Float";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  // For convenience: from types module
  type Dimension = Types.Dimension;
  type Sides = Types.Sides;
  type Category = Types.Category;
  type CategoryAggregationParameters = Types.CategoryAggregationParameters;
  type Register<B> = Types.Register<B>;

  type VerifyCategoryError = {
    #CategoryNotFound;
  };

  public func verifyCategory(political_categories: Trie<Dimension, Sides>, category: Category) : Result<(), VerifyCategoryError> {
    switch(Trie.get(political_categories, Types.keyText(category.dimension), Text.equal)){
      case(null){
        #err(#CategoryNotFound);
      };
      case(?category){
        #ok;
      };
    };
  };

  public func computeCategoriesAggregation(
    political_categories: Trie<Dimension, Sides>,
    aggregation_params: CategoryAggregationParameters,
    register_categories: Register<Category>,
    question_id: Nat)
  : [Category] {
    var categories : Buffer.Buffer<Category> = Buffer.Buffer<Category>(0);
    let total_all = Float.fromInt(Register.getTotals<Category>(register_categories, question_id).all);
    for ((dimension, _) in Trie.iter(political_categories)){
      let category_a = { dimension = dimension; direction = #LR; };
      let category_b = { dimension = dimension; direction = #RL; };
      let total_a = Float.fromInt(Register.getTotalForBallot(register_categories, question_id, Types.hashCategory, Types.equalCategory, category_a));
      let total_b = Float.fromInt(Register.getTotalForBallot(register_categories, question_id, Types.hashCategory, Types.equalCategory, category_b));
      if (((total_a + total_b) / total_all) > aggregation_params.dimension_threshold){
        let total_dimension = total_a + total_b;
        if ((total_a / total_dimension) > aggregation_params.direction_threshold){
          categories.add(category_a);
        } else if ((total_b / total_dimension) > aggregation_params.direction_threshold){
          categories.add(category_b);
        };
      };
    };
    return categories.toArray();
  };

};