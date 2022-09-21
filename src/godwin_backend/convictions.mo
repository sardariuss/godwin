import Types "types";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type Opinion = Types.Opinion;
  type Conviction = Types.Conviction;
  type Direction = Types.Direction;
  type Category = Types.Category;
  type OrientedCategory = Types.OrientedCategory;
  type ArrayConvictions = Types.ArrayConvictions;
  type CategoryConviction = Types.CategoryConviction;

  func convictionMatrix(opinion: Opinion, moderate_coef: Float) : Conviction {
    switch(opinion){
      case(#AGREE(conviction)){
        switch(conviction){
          case(#ABSOLUTE){{ left = 1.0;           center = 0.0;                 right = 0.0;           }};
          case(#MODERATE){{ left = moderate_coef; center = 1.0 - moderate_coef; right = 0.0;           }};
        };
      };
      case(#NEUTRAL)     {{ left = 0.0;           center = 1.0;                 right = 0.0;           }};
      case(#DISAGREE(conviction)){
        switch(conviction){
          case(#MODERATE){{ left = 0.0;           center = 1.0 - moderate_coef; right = moderate_coef; }};
          case(#ABSOLUTE){{ left = 0.0;           center = 0.0;                 right = 1.0;           }};
        };
      };
    };
  };

  func getConviction(opinion: Opinion, direction: Direction, moderate_coef: Float) : Conviction {
    let conviction = convictionMatrix(opinion, moderate_coef);
    switch(direction){
      case(#LR){
        conviction;
      };
      case(#RL){
        {
          left = conviction.right;
          center = conviction.center;
          right = conviction.left;
        };
      };
    };
  };

  func sumConvictions(a: Conviction, b: Conviction) : Conviction {
    {
      left = a.left + b.left;
      center = a.center + b.center;
      right = a.right + b.right;
    };
  };

  public func addConviction(trie: Trie<Category, Conviction>, category: OrientedCategory, opinion: Opinion, moderate_coef: Float) : Trie<Category, Conviction> {
    var updated_conviction = { left = 0.0; center = 0.0; right = 0.0; };
    switch(Trie.get(trie, Types.keyText(category.category), Text.equal)){
      case(null){};
      case(?conviction){
        updated_conviction := conviction;
      };
    };
    updated_conviction := sumConvictions(updated_conviction, getConviction(opinion, category.direction, moderate_coef));
    Trie.put(trie, Types.keyText(category.category), Text.equal, updated_conviction).0;
  };

  public func toArray(trie: Trie<Category, Conviction>) : ArrayConvictions {
    var buffer : Buffer.Buffer<CategoryConviction> = Buffer.Buffer<CategoryConviction>(0);
    for ((category, conviction) in Trie.iter(trie)){
      buffer.add({category = category; conviction = conviction;});
    };
    buffer.toArray();
  };

};