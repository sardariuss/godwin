import Types "../types";
import Utils "../utils";
import Votes "votes";

import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Trie "mo:base/Trie";
import Float "mo:base/Float";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from types modules
  type Categorization = Types.Categorization;
  type Category = Types.Category;
  type Categories = Types.Categories;
  type CategorizationArray = Types.CategorizationArray;

  type CategorizationsRegister = Votes.VoteRegister<Categorization, CategorizationsSum>;
  
  type CategorizationsSum = {
    count: Nat;
    categorization: Categorization;
  };

  public func empty(categories: Categories) : Categorizations {
    Categorizations({ register = Votes.empty<Categorization, CategorizationsSum>(); categories = categories; });
  };

  type Shareable = {
    register: CategorizationsRegister;
    categories: Categories;
  };

  public class Categorizations(args: Shareable) {

    var register_ : CategorizationsRegister = args.register;
    let categories_ : Categories = args.categories;

    public func share() : Shareable {
      {
        register = register_;
        categories = categories_;
      };
    };

    public func getForUser(principal: Principal) : Trie<Nat, Categorization> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Categorization {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, categorization: Categorization) {
      if (not isAcceptableCategorization(categorization)){
        Debug.trap("The categorization is malformed.");
      };
      register_ := Votes.putBallot(register_, principal, question_id, categorization, emptySum, addToSum, removeFromSum).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      register_ := Votes.removeBallot(register_, principal, question_id, removeFromSum).0;
    };

    public func getMeanForQuestion(question_id: Nat) : Categorization {
      var mean = emptyCategorization();
      Option.iterate(Votes.getAggregate(register_, question_id), func(sum: CategorizationsSum){
        if (sum.count > 0){
          for ((category, sum_cursors) in Trie.iter(sum.categorization)){
            mean := Trie.put(mean, Types.keyText(category), Text.equal, sum_cursors / Float.fromInt(sum.count)).0;
          };
        };
      });
      mean;
    };

    public func isAcceptableCategorization(categorization: Categorization) : Bool {
      if (Trie.size(categorization) != Trie.size(categorization)){
        return false;
      };
      for ((category, cursor) in Trie.iter(categorization)){
        if (Float.abs(cursor) > 1.0){
          return false;
        };
        if (Trie.get(categories_, Types.keyText(category), Text.equal) == null){
          return false;
        };
      };
      return true;
    };

    public func verifyCategorization(array: CategorizationArray) : ?Categorization {
      var trie = Utils.arrayToTrie(array, Types.keyText, Text.equal);
      if (isAcceptableCategorization(trie)){
        return ?trie;
      };
      return null;
    };

    func emptyCategorization() : Categorization {
      var trie = Trie.empty<Category, Float>();
      for ((category, _) in Trie.iter(categories_)){
        trie := Trie.put(trie, Types.keyText(category), Text.equal, 0.0).0;
      };
      trie;
    };

    func emptySum() : CategorizationsSum {
      {
        count = 0;
        categorization = emptyCategorization();
      };
    };

  };

  func addToSum(sum: CategorizationsSum, categorization: Categorization) : CategorizationsSum {
    var updated_categorization = sum.categorization;
    for ((category, sum_cursors) in Trie.iter(sum.categorization)){
      // Assumes that the categorization is not malformed
      Option.iterate(Trie.get(categorization, Types.keyText(category), Text.equal), func(cursor: Float) {
        updated_categorization := Trie.put(updated_categorization, Types.keyText(category), Text.equal, sum_cursors + cursor).0;
      });
    };
    {
      count = sum.count + 1;
      categorization = updated_categorization;
    };
  };

  func removeFromSum(sum: CategorizationsSum, categorization: Categorization) : CategorizationsSum {
    var updated_categorization = sum.categorization;
    for ((category, sum_cursors) in Trie.iter(sum.categorization)){
      // Assumes that the categorization is not malformed
      Option.iterate(Trie.get(categorization, Types.keyText(category), Text.equal), func(cursor: Float) {
        updated_categorization := Trie.put(updated_categorization, Types.keyText(category), Text.equal, sum_cursors - cursor).0;
      });
    };
    {
      count = sum.count - 1;
      categorization = updated_categorization;
    };
  };

};