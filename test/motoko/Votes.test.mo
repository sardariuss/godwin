import Types            "../../src/godwin_sub/model/Types";
import QuestionTypes    "../../src/godwin_sub/model/questions/Types";
import QueriesFactory   "../../src/godwin_sub/model/questions/QueriesFactory";
import KeyConverter     "../../src/godwin_sub/model/questions/KeyConverter";

import Principals                               "common/Principals";
//import { compare; optionalTestify; Testify; } = "common/Testify";

import Principal        "mo:base/Principal";
import Array            "mo:base/Array";
import Trie            "mo:base/Trie";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";

import { test; suite; } "mo:test";

type Trie<K, V> = Trie.Trie<K, V>;
type Iter<T> = Iter.Iter<T>;
type Time = Int;

type SuperBallot<T> = {
  answer: T;
  date: Time;
};

type SuperInfo<A> = {
  aggregate: A;
  date: Time;
};

type SuperVote<T, A> = {
  var ballots: Trie<Principal, SuperBallot<T>>;
  var info: SuperInfo<A>;
};

type Ballot<T> = {
  answer: T;
};

type Info<A> = {
  aggregate: A;
};

type Vote<T, A> = {
  var ballots: Trie.Trie<Principal, Ballot<T>>;
  var info: Info<A>;
};

func key(p: Principal) : Trie.Key<Principal> { { hash = Principal.hash(p); key = p; } };

func putBallot<T, A>(vote: Vote<T, A>, principal: Principal, ballot: Ballot<T>) { //, putBallot: (Vote<T, A>, Principal, Ballot<T>) -> ()){
  vote.ballots := Trie.put(vote.ballots, key(principal), Principal.equal, ballot).0;
};

func addBallot<T, A>(ballots: Trie<Principal, Ballot<T>>, principal: Principal, ballot: Ballot<T>) : Trie<Principal, Ballot<T>> {
  Trie.put(ballots, key(principal), Principal.equal, ballot).0;
};

func putBallot2<T, A>(principal: Principal, ballot: Ballot<T>, putBallot: (Principal, Ballot<T>) -> ()){
  putBallot(principal, ballot);
};

func putBallot3<T>(principal: Principal, ballot: Ballot<T>, putBallot: () -> ()){
  putBallot();
};

func putSimpleBallot<T>(principal: Principal, ballot: Ballot<T>, iter: Iter<(Principal, Ballot<T>)>, put_ballot: () -> ()) {
  for ((principal, ballot) in iter){
    Debug.print("principal: " # Principal.toText(principal));
  };
  put_ballot();
};

//func putSuperBallotBallot(){
//  // Cannot use SuperVote here
//  let vote : SuperVote<Float, Float> = {
//    var ballots = Trie.empty<Principal, { answer : Float; date : Time; }>();
//    var info = { aggregate : Float = 0.0; date : Time = 0; };
//  };
//  let ballot : SuperBallot<Float> = { answer = 0.0; date = 0; };
//  putBallot<Float, Float>(vote, Principal.fromText("aaaaa-aa"), ballot);
//
//  // Cannot user SuperBallot here neither
//  var super_ballots : Trie<Principal, SuperBallot<Float>> = Trie.empty<Principal, SuperBallot<Float>>();
//  super_ballots := addBallot(super_ballots, Principal.fromText("aaaaa-aa"), ballot);
//
//  // Does not work
//  let put_ballot_fn = func(principal: Principal, ballot: SuperBallot<Float>) {
//    vote.ballots := Trie.put(vote.ballots, key(principal), Principal.equal, ballot).0;
//  };
//
//  putBallot2<Float, Float>(Principal.fromText("aaaaa-aa"), ballot, put_ballot_fn);
//
//  // Should work
//  let principal = Principal.fromText("aaaaa-aa");
//  let put_ballot_fn2 = func() {
//    vote.ballots := Trie.put(vote.ballots, key(principal), Principal.equal, ballot).0;
//  };
//  putBallot3<Float>(principal, ballot, put_ballot_fn2);
//
//  let iter : Iter<(Principal, SuperBallot<Float>)> = Trie.iter<Principal, SuperBallot<Float>>(super_ballots);
//
//  var removed : ?SuperBallot<Float> = null;
//  
//  let put_ballot_fn4 = func() {
//    let (ballots, old) = Trie.put(vote.ballots, key(principal), Principal.equal, ballot);
//    vote.ballots := ballots;
//    removed := old;
//  };
//
//  // Let's see
//  putSimpleBallot<Float>(principal, ballot, iter, put_ballot_fn4);
//
//};

func putSuperBallot<T, A>(vote: SuperVote<T, A>, principal: Principal, ballot: SuperBallot<T>) : ?SuperBallot<T> {
  let iter : Iter<(Principal, SuperBallot<T>)> = Trie.iter<Principal, SuperBallot<T>>(vote.ballots);
  var removed : ?SuperBallot<T> = null;
  let put_ballot = func() {
    let (ballots, old) = Trie.put(vote.ballots, key(principal), Principal.equal, ballot);
    vote.ballots := ballots;
    removed := old;
  };
  putSimpleBallot<T>(principal, ballot, iter, put_ballot);
  removed;
};


// Cannot use super types as argument if:
//  - the argument is a collection (e.g. Trie)
//  - the argument is a function that uses the super type as an argument (but return type is ok!)
suite("Vote test temp test suite", func() {
  test("ola", func() {
    let super_vote : SuperVote<Float, Float> = {
      var ballots = Trie.empty<Principal, SuperBallot<Float>>();
      var info = { aggregate : Float = 0.0; date : Time = 0; };
    };
    ignore putSuperBallot(super_vote, Principal.fromText("aaaaa-aa"                                                       ), { answer =  0.0; date = 0; });
    ignore putSuperBallot(super_vote, Principal.fromText("l2dqn-dqd5a-er3f7-h472o-ainav-j3ll7-iavjt-4v6ib-c6bom-duooy-uqe"), { answer =  1.0; date = 1; });
    switch(putSuperBallot(super_vote, Principal.fromText("aaaaa-aa"                                                       ), { answer = -1.0; date = 2; })){
      case(null) { Debug.print("null"); };
      case(?old) { Debug.print("old = { answer = " # Float.toText(old.answer) # "; date = " # Int.toText(old.date) # " }"); };
    };

    for ((principal, ballot) in Trie.iter<Principal, SuperBallot<Float>>(super_vote.ballots)){
      Debug.print("principal: " # Principal.toText(principal) # "; ballot = { answer = " # Float.toText(ballot.answer) # "; date = " # Int.toText(ballot.date) # " }");
    };
    
  });
});