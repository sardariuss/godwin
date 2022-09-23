import Votes "votes";
import Types "types";

import Buffer "mo:base/Buffer";
import Float "mo:base/Float";
import Array "mo:base/Array";

module {

  // For convenience: from types module
  type OrientedCategory = Types.OrientedCategory;
  type AggregationParameters = Types.AggregationParameters;
  type VoteRegister<B> = Types.VoteRegister<B>;
  type CategoriesDefinition = Types.CategoriesDefinition;

  public func computeAggregation(
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

};