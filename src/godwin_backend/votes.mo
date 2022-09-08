import Types "types";

import Hash "mo:base/Hash";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Hash = Hash.Hash;
  type Principal = Principal.Principal;

  // For convenience: from types module
  type VoteRegister<B> = Types.VoteRegister<B>;
  type TotalVotes<B> = Types.TotalVotes<B>;

  // For clarity
  type Item = Nat;

  public func empty<B>() : VoteRegister<B> {
    {
      ballots = Trie.empty<Principal, Trie<Item, B>>();
      totals = Trie.empty<Item, TotalVotes<B>>();
    }
  };

  public func getUserBallots<B>(register: VoteRegister<B>, user: Principal) : Trie<Item, B> {
    var user_ballots = Trie.empty<Item, B>();
    switch(Trie.get(register.ballots, Types.keyPrincipal(user), Principal.equal)){
      case(null){};
      case(?ballots){
        user_ballots := ballots;
      };
    };
    user_ballots;
  };

  public func getBallot<B>(register: VoteRegister<B>, user: Principal, item: Item) : ?B {
    Trie.get(getUserBallots<B>(register, user), Types.keyNat(item), Nat.equal);
  };

  public func getTotalVotes<B>(register: VoteRegister<B>, item: Item) : TotalVotes<B> {
    var item_totals = {
      all = 0;
      per_ballot = Trie.empty<B, Nat>();
    };
    switch(Trie.get(register.totals, Types.keyNat(item), Nat.equal)){
      case(null){};
      case(?totals){
        item_totals := totals;
      };
    };
    item_totals;
  };

  public func getTotalVotesForBallot<B>(register: VoteRegister<B>, item: Item, hash: (B) -> Hash, equal: (B, B) -> Bool, ballot: B) : Nat {
    switch (Trie.get(getTotalVotes<B>(register, item).per_ballot, { key = ballot; hash = hash(ballot); }, equal)){
      case(?total){
        return total;
      };
      case(null){
        return 0;
      };
    };
  };

  public func putBallot<B>(register: VoteRegister<B>, user: Principal, item: Item, hash: (B) -> Hash, equal: (B, B) -> Bool, ballot: B) : (VoteRegister<B>, ?B) {
    // Put the ballot in the user's ballots
    let (user_ballots, removed_ballot) = Trie.put(getUserBallots<B>(register, user), Types.keyNat(item), Nat.equal, ballot);
    // Get the total of ballots for this item
    let totals = getTotalVotes(register, item);
    var totals_all = totals.all;
    var totals_per_ballot = totals.per_ballot;
    // Decrement the total of the removed ballot if any
    switch(removed_ballot){
      case(null){};
      case(?old_ballot){
        totals_all := totals_all - 1;
        let total_for_ballot = getTotalVotesForBallot(register, item, hash, equal, old_ballot) - 1;
        totals_per_ballot := Trie.put(totals_per_ballot, { key = old_ballot; hash = hash(old_ballot); }, equal, total_for_ballot).0;
      };
    };
    // Increment the total for the new ballot
    totals_all := totals_all + 1;
    let total_for_ballot = getTotalVotesForBallot(register, item, hash, equal, ballot) + 1;
    totals_per_ballot := Trie.put(totals_per_ballot, { key = ballot; hash = hash(ballot); }, equal, total_for_ballot).0;
    // Return the updated register and the removed ballot if any
    (
      {
        ballots = Trie.put(register.ballots, Types.keyPrincipal(user), Principal.equal, user_ballots).0;
        totals = Trie.put(register.totals, Types.keyNat(item), Nat.equal, { all = totals_all; per_ballot = totals_per_ballot; }).0;
      },
      removed_ballot
    );
  };

  public func removeBallot<B>(register: VoteRegister<B>, user: Principal, item: Item, hash: (B) -> Hash, equal: (B, B) -> Bool) : (VoteRegister<B>, ?B) {
    // Remove the ballot from the user's ballots
    let (user_ballots, removed_ballot) = Trie.remove(getUserBallots<B>(register, user), Types.keyNat(item), Nat.equal);
    // Get the total of ballots for this item
    let totals = getTotalVotes(register, item);
    var totals_all = totals.all;
    var totals_per_ballot = totals.per_ballot;
    // Decrement the total by one if a vote was already given
    switch(removed_ballot){
      case(null){};
      case(?old_ballot){
        totals_all := totals_all - 1;
        let total_for_ballot = getTotalVotesForBallot(register, item, hash, equal, old_ballot) - 1;
        totals_per_ballot := Trie.put(totals_per_ballot, { key = old_ballot; hash = hash(old_ballot); }, equal, total_for_ballot).0;
      };
    };
    // Return the updated register and removed ballot
    (
      {
        ballots = Trie.put(register.ballots, Types.keyPrincipal(user), Principal.equal, user_ballots).0;
        totals = Trie.put(register.totals, Types.keyNat(item), Nat.equal, { all = totals_all; per_ballot = totals_per_ballot; }).0;
      },
      removed_ballot
    );
  };

};