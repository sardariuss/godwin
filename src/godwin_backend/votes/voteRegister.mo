import Types "../types";
import Vote "vote";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Trie "mo:base/Trie";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Vote<B, A> = Types.Vote<B, A>;

  public type Register<B, A> = {
    votes: Trie<Nat, Vote<B, A>>;
    index: Nat;
  };

  public func empty<B, A>() : Register<B, A> {
    {
      votes = Trie.empty<Nat, Vote<B, A>>();
      index = 0;
    };
  };

  public func get<B, A>(register: Register<B, A>, index: Nat) : Vote<B, A> {
    switch(Trie.get(register.votes, Types.keyNat(index), Nat.equal)){
      case(null) { Debug.trap("Could not find the vote."); };
      case(?vote) { vote; }
    }
  };

  public func find<B, A>(register: Register<B, A>, index: Nat) : ?Vote<B, A> {
    Trie.get(register.votes, Types.keyNat(index), Nat.equal);
  };

  public func newVote<B, A>(register: Register<B, A>, date: Int, aggregate: A) : (Register<B, A>, Vote<B, A>) {
    let vote = Vote.new(date, aggregate); // @todo
    (
      {
        votes = Trie.put(register.votes, Types.keyNat(vote.id), Nat.equal, vote).0;
        index = register.index + 1;
      },
      vote
    );
  };

  public func updateVote<B, A>(register: Register<B, A>, vote: Vote<B, A>) : Register<B, A> {
    assert(vote.status == #OPEN);
    let (votes, old_vote) = Trie.put(register.votes, Types.keyNat(vote.id), Nat.equal, vote);
    if (Option.isNull(old_vote)) { Debug.trap("Could not find the vote."); };
    { register with votes };
  };

  public func getBallot<B, A>(register: Register<B, A>, id: Nat, principal: Principal) : ?B {
    Vote.getBallot(get(register, id), principal);
  };

  public func putBallot<B, A>(
    register: Register<B, A>,
    id: Nat,
    principal: Principal,
    ballot: B,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : Register<B, A> {
    updateVote(register, Vote.putBallot(get(register, id), principal, ballot, add_to_aggregate, remove_from_aggregate));
  };

  public func removeBallot<B, A>(
    register: Register<B, A>,
    id: Nat,
    principal: Principal,
    add_to_aggregate: (A, B) -> A,
    remove_from_aggregate: (A, B) -> A
  ) : Register<B, A> {
    updateVote(register, Vote.removeBallot(get(register, id), principal, add_to_aggregate, remove_from_aggregate));
  };

};