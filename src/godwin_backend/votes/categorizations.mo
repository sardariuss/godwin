import Types "../types";
import Votes "votes";

import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  type VoteRegister<B, A> = Votes.VoteRegister<B, A>;
  type Categorization = Types.Profile;
  type SummedCategorizations = {
    count: Nat;
    sum: Categorization;
  };

  public func empty() : Categorizations {
    Categorizations(Votes.empty<Categorization, SummedCategorizations>());
  };

  public class Categorizations(register: VoteRegister<Categorization, SummedCategorizations>) {

    var categorizations_ = register;

    public func getForUser(principal: Principal) : Trie<Nat, Categorization> {
      Votes.getUserBallots(categorizations_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Categorization {
      Votes.getBallot(categorizations_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, categorization: Categorization) {
      categorizations_ := Votes.putBallot(
        categorizations_,
        principal,
        question_id,
        categorization,
        emptySummedCategorization,
        addToSummedCategorization,
        removeFromSummedCategorization
      ).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      categorizations_ := Votes.removeBallot(
        categorizations_,
        principal,
        question_id,
        removeFromSummedCategorization
      ).0;
    };

    public func getAggregatedCategorization(question_id: Nat) : Categorization {
      switch(Votes.getAggregation(categorizations_, question_id)){
        case(null) { emptySummedCategorization().sum; };
        case(?aggregation) {
          aggregation.sum; // @todo: normalize from count
        };
      };
    };

  };

  func emptySummedCategorization() : SummedCategorizations {
    {
      count = 0;
      // @todo: requires to init with the categories from the main
      sum = Trie.empty<Text, Float>();
    };
  };

  // @todo: requires to verify the categorization is well formed
  func addToSummedCategorization(summed_categorization: SummedCategorizations, categorization: Categorization) : SummedCategorizations {
    var updated_sum = summed_categorization.sum;
    for ((category, sum) in Trie.iter(summed_categorization.sum)){
      switch(Trie.get(categorization, Types.keyText(category), Text.equal)){
        case(null) { Debug.trap("@todo"); };
        case(?profile) {
          updated_sum := Trie.put(updated_sum, Types.keyText(category), Text.equal, sum + profile).0;
        };
      };
    };
    {
      count = summed_categorization.count + 1;
      sum = updated_sum;
    };
  };

  // @todo: requires to verify the categorization is well formed
  func removeFromSummedCategorization(summed_categorization: SummedCategorizations, categorization: Categorization) : SummedCategorizations {
    var updated_sum = summed_categorization.sum;
    for ((category, sum) in Trie.iter(summed_categorization.sum)){
      switch(Trie.get(categorization, Types.keyText(category), Text.equal)){
        case(null) { Debug.trap("@todo"); };
        case(?profile) {
          updated_sum := Trie.put(updated_sum, Types.keyText(category), Text.equal, sum - profile).0;
        };
      };
    };
    {
      count = summed_categorization.count - 1;
      sum = updated_sum;
    };
  };

};