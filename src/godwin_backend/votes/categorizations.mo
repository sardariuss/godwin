import Types "../types";
import Votes "votes";

import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from other modules
  type Categorization = Types.Profile;
  type VoteRegister<B, A> = Votes.VoteRegister<B, A>;
  
  type SummedCategorizations = {
    count: Nat;
    sum: Categorization;
  };

  public func emptyRegister() : VoteRegister<Categorization, SummedCategorizations> {
    Votes.empty<Categorization, SummedCategorizations>();
  };

  public func empty() : Categorizations {
    Categorizations(emptyRegister());
  };

  public class Categorizations(register: VoteRegister<Categorization, SummedCategorizations>) {

    var register_ = register;

    public func getRegister() : VoteRegister<Categorization, SummedCategorizations> {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Categorization> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Categorization {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, categorization: Categorization) {
      register_ := Votes.putBallot(
        register_,
        principal,
        question_id,
        categorization,
        emptySummedCategorization,
        addToSummedCategorization,
        removeFromSummedCategorization
      ).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      register_ := Votes.removeBallot(
        register_,
        principal,
        question_id,
        removeFromSummedCategorization
      ).0;
    };

    public func getAggregatedCategorization(question_id: Nat) : Categorization {
      switch(Votes.getAggregation(register_, question_id)){
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