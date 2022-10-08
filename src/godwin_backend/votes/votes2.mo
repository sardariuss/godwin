import Types "../types";

import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Hash = Hash.Hash;
  type Principal = Principal.Principal;

  public type VoteRegister<B, A> = {
    // map<user, map<item, ballot>>
    ballots: Trie<Principal, Trie<Nat, B>>;
    // map<item, aggregation>
    aggregations: Trie<Nat, A>;
  };

  // For clarity
  type Item = Nat;

  public func empty<B, A>() : VoteRegister<B, A> {
    {
      ballots = Trie.empty<Principal, Trie<Item, B>>();
      aggregations = Trie.empty<Item, A>();
    }
  };

  public func getUserBallots<B, A>(register: VoteRegister<B, A>, user: Principal) : Trie<Item, B> {
    var user_ballots = Trie.empty<Item, B>();
    switch(Trie.get(register.ballots, Types.keyPrincipal(user), Principal.equal)){
      case(null){};
      case(?ballots){
        user_ballots := ballots;
      };
    };
    user_ballots;
  };

  public func getBallot<B, A>(register: VoteRegister<B, A>, user: Principal, item: Item) : ?B {
    Trie.get(getUserBallots<B, A>(register, user), Types.keyNat(item), Nat.equal);
  };

  public func getAggregation<B, A>(register: VoteRegister<B, A>, item: Item) : ?A {
    Trie.get(register.aggregations, Types.keyNat(item), Nat.equal);
  };

  public func putBallot<B, A>(
    register: VoteRegister<B, A>,
    user: Principal,
    item: Item,
    hash: (B) -> Hash,
    equal: (B, B) -> Bool,
    ballot: B,
    add_to_aggregate: (?A, B, ?B) -> A
  ) : (VoteRegister<B, A>, ?B) {
    // Put the ballot in the user's ballots
    let (user_ballots, removed_ballot) = Trie.put(getUserBallots<B, A>(register, user), Types.keyNat(item), Nat.equal, ballot);
    // Return the updated register and the removed ballot if any
    (
      {
        ballots = Trie.put(register.ballots, Types.keyPrincipal(user), Principal.equal, user_ballots).0;
        aggregations = Trie.put(register.aggregations, Types.keyNat(item), Nat.equal, add_to_aggregate(getAggregation(register, item), ballot, removed_ballot)).0;
      },
      removed_ballot
    );
  };

  public func removeBallot<B, A>(
    register: VoteRegister<B, A>,
    user: Principal,
    item: Item,
    hash: (B) -> Hash,
    equal: (B, B) -> Bool,
    remove_from_aggregate: (A, B) -> A
  ) : (VoteRegister<B, A>, ?B) {
    // Remove the ballot from the user's ballots
    let (user_ballots, removed_ballot) = Trie.remove(getUserBallots<B, A>(register, user), Types.keyNat(item), Nat.equal);
    // Check if the ballot has been removed
    switch(removed_ballot){
      case(null){
        // Nothing has been removed, return the original register
        return (register, null);
      };
      case(?old_ballot){
        switch(getAggregation(register, item)){
          case(null){ 
            Debug.trap("If the user had already voted, the aggregation shall exist.");
          };
          case(?item_aggregation) {
            // Return the updated register and removed ballot
            return (
              {
                ballots = Trie.put(register.ballots, Types.keyPrincipal(user), Principal.equal, user_ballots).0;
                aggregations = Trie.put(register.aggregations, Types.keyNat(item), Nat.equal, remove_from_aggregate(item_aggregation, old_ballot)).0;
              },
              removed_ballot
            );
          };
        };
      };
    };    
  };

};