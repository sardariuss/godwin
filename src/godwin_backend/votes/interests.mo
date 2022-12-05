import Types "../types";
import MultiKeyMap "../multiKeyMap";
import Votes "votes";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Option "mo:base/Option";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from types module
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type MultiKeyMap<K1, K2> = MultiKeyMap.MultiKeyMap<K1, K2>;

  type InterestsRegister = Votes.VoteRegister<Interest, InterestAggregate>;

  public func empty() : Interests {
    Interests(Votes.empty<Interest, InterestAggregate>());
  };

  public class Interests(register: InterestsRegister) {

    /// Members
    var register_ = register;
    var order_by_upvotes_ = MultiKeyMap.init<Int, Nat>();
    for ((question_id, aggregate) in Trie.iter(register.aggregates)){
      order_by_upvotes_ := MultiKeyMap.put(order_by_upvotes_, Int.compare, aggregate.score, Int.hash, Nat.equal, question_id);
    };

    public func share() : InterestsRegister {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Interest> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Interest {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, interest: Interest) {
      let (register, removed_ballot, old_aggregate, new_aggregate) = 
        Votes.putBallot(register_, principal, question_id, interest, emptyAggregate, addToAggregate, removeFromAggregate);
      // Replace the aggregate in the multikey map
      order_by_upvotes_ := MultiKeyMap.replace(order_by_upvotes_, Int.compare, old_aggregate.score, new_aggregate.score, Int.hash, Nat.equal, question_id);
      // Update the register
      register_ := register;
    };

    public func remove(principal: Principal, question_id: Nat) {
      let (register, removed_ballot, old_aggregate, new_aggregate) = 
        Votes.removeBallot(register_, principal, question_id, emptyAggregate, removeFromAggregate);
      // Replace the aggregate in the multikey map
      order_by_upvotes_ := MultiKeyMap.replace(order_by_upvotes_, Int.compare, old_aggregate.score, new_aggregate.score, Int.hash, Nat.equal, question_id);
      // Update the register
      register_ := register;
    };

    public func getAggregate(question_id: Nat) : InterestAggregate {
      Option.get(Votes.getAggregate(register_, question_id), emptyAggregate());
    };

  };

  func emptyAggregate() : InterestAggregate {
    { ups = 0; downs = 0; score = 0; };
  };

  func addToAggregate(aggregate: InterestAggregate, ballot: Interest) : InterestAggregate {
    var ups = aggregate.ups;
    var downs = aggregate.downs;
    switch(ballot){
      case(#UP){ ups := aggregate.ups + 1; };
      case(#DOWN){ downs := aggregate.downs + 1; };
    };
    { ups; downs; score = computeScore(ups, downs) };
  };

  func removeFromAggregate(aggregate: InterestAggregate, ballot: Interest) : InterestAggregate {
    var ups = aggregate.ups;
    var downs = aggregate.downs;
    switch(ballot){
      case(#UP){ ups := aggregate.ups - 1; };
      case(#DOWN){ downs := aggregate.downs - 1; };
    };
    { ups; downs; score = computeScore(ups, downs) };
  };

  func computeScore(ups: Nat, downs: Nat) : Int {
    if (ups + downs == 0) { return 0; };
    let f_ups = Float.fromInt(ups);
    let f_downs = Float.fromInt(downs);
    let x = f_ups / (f_ups + f_downs);
    let growth_rate = 20.0;
    let mid_point = 0.5;
    // https://stackoverflow.com/a/3787645: this will underflow to 0 for large negative values of x,
    // but that may be OK depending on your context since the exact result is nearly zero in that case.
    let sigmoid = 1.0 / (1.0 + Float.exp(-1.0 * growth_rate * (x - mid_point)));
    Float.toInt(Float.nearest(f_ups * sigmoid - f_downs * (1.0 - sigmoid)));
  };

};