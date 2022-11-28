import Types "../types";
import MultiKeyMap "../multiKeyMap";
import Votes "votes";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Float "mo:base/Float";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from types module
  type Endorsement = Types.Endorsement;
  type EndorsementsTotal = Types.EndorsementsTotal;
  type MultiKeyMap<K1, K2> = MultiKeyMap.MultiKeyMap<K1, K2>;

  type EndorsementsRegister = Votes.VoteRegister<Endorsement, EndorsementsTotal>;

  public func empty() : Endorsements {
    Endorsements(Votes.empty<Endorsement, EndorsementsTotal>());
  };

  public class Endorsements(register: EndorsementsRegister) {

    /// Members
    var register_ = register;
    var order_by_upvotes_ = MultiKeyMap.init<Int, Nat>();
    for ((question_id, aggregate) in Trie.iter(register.aggregates)){
      order_by_upvotes_ := MultiKeyMap.put(order_by_upvotes_, Int.compare, getScore(aggregate), Int.hash, Nat.equal, question_id);
    };

    public func share() : EndorsementsRegister {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Endorsement> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Endorsement {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, endorsement: Endorsement) {
      let (register, removed_ballot, old_aggregate, new_aggregate) = 
        Votes.putBallot(register_, principal, question_id, endorsement, emptyTotal, addToTotal, removeFromTotal);
      // Replace the aggregate in the multikey map
      order_by_upvotes_ := MultiKeyMap.replace(order_by_upvotes_, Int.compare, getScore(old_aggregate), getScore(new_aggregate), Int.hash, Nat.equal, question_id);
      // Update the register
      register_ := register;
    };

    public func remove(principal: Principal, question_id: Nat) {
      let (register, removed_ballot, old_aggregate, new_aggregate) = 
        Votes.removeBallot(register_, principal, question_id, emptyTotal, removeFromTotal);
      // Replace the aggregate in the multikey map
      order_by_upvotes_ := MultiKeyMap.replace(order_by_upvotes_, Int.compare, getScore(old_aggregate), getScore(new_aggregate), Int.hash, Nat.equal, question_id);
      // Update the register
      register_ := register;
    };

    public func getTotalForQuestion(question_id: Nat) : Int {
      switch(Votes.getAggregate(register_, question_id)){
        case(null) { getScore(emptyTotal()); };
        case(?total) { getScore(total); };
      };
    };

  };

  func emptyTotal() : EndorsementsTotal {
    { ups = 0; downs = 0; };
  };

  func addToTotal(total: EndorsementsTotal, ballot: Endorsement) : EndorsementsTotal {
    switch(ballot){
      case(#UP){   { ups = total.ups + 1; downs = total.downs;     }};
      case(#DOWN){ { ups = total.ups;     downs = total.downs + 1; }};
    };
  };

  func removeFromTotal(total: EndorsementsTotal, ballot: Endorsement) : EndorsementsTotal {
    switch(ballot){
      case(#UP){   { ups = total.ups - 1; downs = total.downs;     }};
      case(#DOWN){ { ups = total.ups;     downs = total.downs - 1; }};
    };
  };

  func getScore(total: EndorsementsTotal) : Int {
    if (total.ups + total.downs == 0) { return 0; };
    let ups = Float.fromInt(total.ups);
    let downs = Float.fromInt(total.downs);
    let x = ups / (ups + downs);
    let growth_rate = 20.0;
    let mid_point = 0.5;
    // https://stackoverflow.com/a/3787645: this will underflow to 0 for large negative values of x,
    // but that may be OK depending on your context since the exact result is nearly zero in that case.
    let sigmoid = 1.0 / (1.0 + Float.exp(-1.0 * growth_rate * (x - mid_point)));
    Float.toInt(Float.nearest(ups * sigmoid - downs * (1.0 - sigmoid)));
  };

};