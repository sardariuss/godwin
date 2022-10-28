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

  // B for ballot, A for aggregate
  public type VoteRegister<B, A> = {
    // map<user, map<item, ballot>>
    ballots: Trie<Principal, Trie<Nat, B>>;
    // map<item, aggregate>
    aggregates: Trie<Nat, A>;
  };

  // For clarity
  type Item = Nat;

  public func empty<B, A>() : VoteRegister<B, A> {
    {
      ballots = Trie.empty<Principal, Trie<Item, B>>();
      aggregates = Trie.empty<Item, A>();
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

  public func getAggregate<B, A>(register: VoteRegister<B, A>, item: Item) : ?A {
    Trie.get(register.aggregates, Types.keyNat(item), Nat.equal);
  };

  public func putBallot<B, A>(
    register: VoteRegister<B, A>,
    user: Principal,
    item: Item,
    ballot: B,
    empty_aggregate: () -> A,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : (VoteRegister<B, A>, ?B) {
    // Put the ballot in the user's ballots
    let (user_ballots, removed_ballot) = Trie.put(getUserBallots<B, A>(register, user), Types.keyNat(item), Nat.equal, ballot);
    // Return the updated register and the removed ballot if any
    var aggregate = switch(getAggregate(register, item)){
      case(null){
        switch(removed_ballot){
          // It is the first ballot, initialize aggregate
          case(null){ add_to_aggregate(empty_aggregate(), ballot); };
          // It is impossible to not have an aggregate if somebody already voted
          case(_){ Debug.trap("A ballot has been removed, the aggregate shall already exist."); };
        };
      };
      case(?aggregate){
        var new_aggregate = add_to_aggregate(aggregate, ballot);
        switch(removed_ballot){
          // No old ballot, nothing to do
          case(null){};
          // Old ballot, remove it from aggregate
          case(?removed){ new_aggregate := remove_from_aggregate(new_aggregate, removed); };
        };
        new_aggregate;
      };
    };
    (
      {
        ballots = Trie.put(register.ballots, Types.keyPrincipal(user), Principal.equal, user_ballots).0;
        aggregates = Trie.put(register.aggregates, Types.keyNat(item), Nat.equal, aggregate).0;
      },
      removed_ballot
    );
  };

  public func removeBallot<B, A>(
    register: VoteRegister<B, A>,
    user: Principal,
    item: Item,
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
        switch(getAggregate(register, item)){
          case(null){ 
            Debug.trap("A ballot has been removed, the aggregate shall already exist.");
          };
          case(?aggregate) {
            // Return the updated register and removed ballot
            return (
              {
                ballots = Trie.put(register.ballots, Types.keyPrincipal(user), Principal.equal, user_ballots).0;
                aggregates = Trie.put(register.aggregates, Types.keyNat(item), Nat.equal, remove_from_aggregate(aggregate, old_ballot)).0;
              },
              removed_ballot
            );
          };
        };
      };
    };    
  };

};