import Types "../types";

import RBT "mo:stableRBT/StableRBTree";

import Trie "mo:base/Trie";
import Option "mo:base/Option";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";
import Order "mo:base/Order";
import Int "mo:base/Int";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Order = Order.Order;
  type Time = Int;

  type TimedBallot<B> = {
    date: Time;
    ballot: B;
  };

  type Key = {
    date: Time;
    question_id: Nat32;
    iteration: Nat;
  };

  public type Register<B> = {
    trie: Trie<Nat32, Trie<Nat, TimedBallot<B>>>;
    rbt: RBT.Tree<Key, B>;
  };

  public func putBallot<B>(register: Register<B>, date: Time, question_id: Nat32, iteration: Nat, ballot: B) : (Register<B>, ?TimedBallot<B>) {
    // 1. Update the trie
    // Get the iterations for this question
    let iterations = Option.get(Trie.get(register.trie, Types.keyNat32(question_id), Nat32.equal), Trie.empty<Nat, TimedBallot<B>>());
    // Add the ballot to the iteration, get the previous one if any
    let (updated_iterations, removed_ballot) = Trie.put(iterations, Types.keyNat(iteration), Nat.equal, { date; ballot; });
    // Update the question's iterations
    let updated_trie = Trie.put(register.trie, Types.keyNat32(question_id), Nat32.equal, updated_iterations).0;

    // 2. Update the RBT
    var updated_rbt = register.rbt;    
    // Remove old key from rbt if any
    Option.iterate(removed_ballot, func(timed_ballot: TimedBallot<B>) {
      updated_rbt := RBT.remove(updated_rbt, compareKey, {date = timed_ballot.date; question_id; iteration;}).1;
    });
    // Add new key in rbt
    updated_rbt := RBT.put(updated_rbt, compareKey, {date; question_id; iteration;}, ballot);

    ( 
      {
        trie = updated_trie;
        rbt = updated_rbt;
      },
      removed_ballot
    );
  };

  public func removeBallot<B>(register: Register<B>, date: Time, question_id: Nat32, iteration: Nat) : (Register<B>, ?TimedBallot<B>) {
    var updated_trie = register.trie;
    var updated_rbt = register.rbt;
    var removed_ballot : ?TimedBallot<B> = null;
    
    Option.iterate(Trie.get(register.trie, Types.keyNat32(question_id), Nat32.equal), func(iterations: Trie<Nat, TimedBallot<B>>){
      let (updated_iterations, removed) = Trie.remove(iterations, Types.keyNat(iteration), Nat.equal);
      Option.iterate(removed, func(ballot: TimedBallot<B>){
        updated_trie := Trie.put(updated_trie, Types.keyNat32(question_id), Nat32.equal, updated_iterations).0;
        removed_ballot := ?ballot;
        updated_rbt := RBT.remove(updated_rbt, compareKey, {date; question_id; iteration;}).1;
      });
    });

    ( 
      {
        trie = updated_trie;
        rbt = updated_rbt;
      },
      removed_ballot
    );
  };

  public func getBallot<B>(register: Register<B>, question_id: Nat32, iteration: Nat) : ?TimedBallot<B> {
    Option.chain(Trie.get(register.trie, Types.keyNat32(question_id), Nat32.equal), func(iterations: Trie<Nat, TimedBallot<B>>) : ?TimedBallot<B> {
      Trie.get(iterations, Types.keyNat(iteration), Nat.equal);
    });
  };

  public func queryBallots<B>(register: Register<B>, direction: RBT.Direction, limit: Nat, previous_key: ?Key) : RBT.ScanLimitResult<Key, B> {
    switch(RBT.entries(register.rbt).next()){
      case(null){ { results  = []; nextKey = null; } };
      case(?first){
        switch(RBT.entriesRev(register.rbt).next()){
          case(null){ { results = []; nextKey = null; } };
          case(?last){
            switch(direction){
              case(#fwd){
                RBT.scanLimit(register.rbt, compareKey, Option.get(previous_key, first.0), last.0, direction, limit);
              };
              case(#bwd){
                RBT.scanLimit(register.rbt, compareKey, first.0, Option.get(previous_key, last.0), direction, limit);
              };
            };
          };
        };
      };
    };
  };


  private func compareKey(a: Key, b: Key) : Order {
    let iteration_order = Int.compare(a.iteration, b.iteration);
    let question_order = compareNat32(a.question_id, b.question_id, iteration_order);
    return compareTime(a.date, b.date, question_order);
  };

  func compare<T>(a: T, b: T, compare: (T, T) -> Order, on_equality: Order) : Order {
    switch(compare(a, b)){
      case(#greater) { #greater; };
      case(#less) { #less; };
      case(#equal) { on_equality; };     
    };
  };

  private func compareNat(a: Nat, b: Nat, default_order: Order) : Order {
    compare<Nat>(a, b, Nat.compare, default_order);
  };

  private func compareNat32(a: Nat32, b: Nat32, default_order: Order) : Order {
    compare<Nat32>(a, b, Nat32.compare, default_order);
  };

  private func compareTime(a: Time, b: Time, default_order: Order) : Order {
    compare<Time>(a, b, Int.compare, default_order);
  };

}