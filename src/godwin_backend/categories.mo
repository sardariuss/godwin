import Register "register";
import Types "types";
import Pool "pool";
import Questions "questions";

import RBT "mo:stableRBT/StableRBTree";

import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Option "mo:base/Option";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";

module {

   // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;
  type Register<B> = Register.Register<B>;
  type Time = Time.Time;
  type Order = Order.Order;

  // For convenience: from types module
  type Question = Types.Question;
  type Dimension = Types.Dimension;
  type Sides = Types.Sides;
  type Direction = Types.Direction;
  type Category = Types.Category;
  type Endorsement = Types.Endorsement;
  type Opinion = Types.Opinion;
  type Pool = Types.Pool;
  type PoolParameters = Types.PoolParameters;
  type CategoryAggregationParameters = Types.CategoryAggregationParameters;

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