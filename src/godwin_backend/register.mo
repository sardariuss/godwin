import Hash "mo:base/Hash";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";

module {

  // For shorter syntax
  type Trie<K, V> = Trie.Trie<K, V>;
  type Hash = Hash.Hash;
  type Key<K> = Trie.Key<K>;
  type Principal = Principal.Principal;

  // For clarity
  type Item = Nat;

  // Keys
  func keyPrincipal(p: Principal) : Key<Principal> { { key = p; hash = Principal.hash(p) } };
  func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Int.hash(n) } };

  public type Register<B> = {
    // map<user, map<item, ballot>>
    ballots: Trie<Principal, Trie<Item, B>>;
    // map<item, map<ballot, sum>>
    totals: Trie<Item, Trie<B, Nat>>;
  };

  public func empty<B>() : Register<B> {
    {
      ballots = Trie.empty<Principal, Trie<Item, B>>();
      totals = Trie.empty<Item, Trie<B, Nat>>(); // @todo: add total of ballots, whichever it is, not only subtotals
    }
  };

  public func getUserBallots<B>(register: Register<B>, user: Principal) : Trie<Item, B> {
    var user_ballots = Trie.empty<Item, B>();
    switch(Trie.get(register.ballots, keyPrincipal(user), Principal.equal)){
      case(null){};
      case(?ballots){
        user_ballots := ballots;
      };
    };
    user_ballots;
  };

  public func getBallot<B>(register: Register<B>, user: Principal, item: Item) : ?B {
    Trie.get(getUserBallots<B>(register, user), keyNat(item), Nat.equal);
  };

  public func getItemTotals<B>(register: Register<B>, item: Item) : Trie<B, Nat> {
    var item_totals = Trie.empty<B, Nat>();
    switch(Trie.get(register.totals, keyNat(item), Nat.equal)){
      case(null){};
      case(?totals){
        item_totals := totals;
      };
    };
    item_totals;
  };

  public func getTotal<B>(register: Register<B>, item: Item, hash: (B) -> Hash, equal: (B, B) -> Bool, ballot: B) : Nat {
    switch (Trie.get(getItemTotals<B>(register, item), { key = ballot; hash = hash(ballot); }, equal)){
      case(?total){
        return total;
      };
      case(null){
        return 0;
      };
    };
  };

  public func putBallot<B>(register: Register<B>, user: Principal, item: Item, hash: (B) -> Hash, equal: (B, B) -> Bool, ballot: B) : (Register<B>, ?B) {
    // Put the ballot in the user's ballots
    let (user_ballots, removed_ballot) = Trie.put(getUserBallots<B>(register, user), keyNat(item), Nat.equal, ballot);
    // Get the total of ballots for this item
    var item_totals = getItemTotals(register, item);
    // Decrement the total of the removed ballot if any
    switch(removed_ballot){
      case(null){};
      case(?old_ballot){
        let ballot_total = getTotal(register, item, hash, equal, old_ballot) - 1;
        item_totals := Trie.put(item_totals, { key = old_ballot; hash = hash(old_ballot); }, equal, ballot_total).0;
      };
    };
    // Increment the total for the new ballot
    let ballot_total = getTotal(register, item, hash, equal, ballot) + 1;
    item_totals := Trie.put(item_totals, { key = ballot; hash = hash(ballot); }, equal, ballot_total).0;
    // Return the updated register and the removed ballot if any
    (
      {
        ballots = Trie.put(register.ballots, keyPrincipal(user), Principal.equal, user_ballots).0;
        totals = Trie.put(register.totals, keyNat(item), Nat.equal, item_totals).0;
      },
      removed_ballot
    );
  };

  public func removeBallot<B>(register: Register<B>, user: Principal, item: Item, hash: (B) -> Hash, equal: (B, B) -> Bool) : (Register<B>, ?B) {
    // Remove the ballot from the user's ballots
    let (user_ballots, removed_ballot) = Trie.remove(getUserBallots<B>(register, user), keyNat(item), Nat.equal);
    // Get the total of ballots for this item
    var item_totals = getItemTotals(register, item);
    // Decrement the total by one if a vote was already given
    switch(removed_ballot){
      case(null){};
      case(?ballot){
        let ballot_total = getTotal(register, item, hash, equal, ballot) - 1;
        item_totals := Trie.put(item_totals, { key = ballot; hash = hash(ballot); }, equal, ballot_total).0;
      };
    };
    (
      {
        ballots = Trie.put(register.ballots, keyPrincipal(user), Principal.equal, user_ballots).0;
        totals = Trie.put(register.totals, keyNat(item), Nat.equal, item_totals).0;
      },
      removed_ballot
    );
  };

};