import Types            "../../src/godwin_sub/model/Types";
import QuestionTypes    "../../src/godwin_sub/model/questions/Types";
import VoteTypes    "../../src/godwin_sub/model/votes/Types";
import QueriesFactory   "../../src/godwin_sub/model/questions/QueriesFactory";
import KeyConverter     "../../src/godwin_sub/model/questions/KeyConverter";

import Principals                               "common/Principals";
//import { compare; optionalTestify; Testify; } = "common/Testify";

import Principal        "mo:base/Principal";
import Array            "mo:base/Array";
import Map            "mo:map/Map";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Float "mo:base/Float";
import Int "mo:base/Int";

import { test; suite; } "mo:test";

module {
  type Map<K, V> = Map.Map<K, V>;
  type Iter<T> = Iter.Iter<T>;
  type Time = Int;

  type Cursor = VoteTypes.Cursor;
  type Polarization = VoteTypes.Polarization;
  type VoteStatus = VoteTypes.VoteStatus;
  type VoteId = VoteTypes.VoteId;

  type Ballot<T> = {
    answer: T;
  };

  type Info<A> = {
    aggregate: A;
  };

  type Vote<T, A> = {
    ballots: Map.Map<Principal, Ballot<T>>;
    var status: VoteStatus;
    var info: Info<A>;
  };

  type VoteRegister<T, A> = {
    votes: Map<VoteId, Vote<T, A>>;
    var index: VoteId;
  };

  type SimpleRegister<T> = {
    map: Map<Nat, T>;
    var index: Nat;
  };

  // Cannot use that with opinions because OpinionRegister contains a collection of super types
  public class Votes<T, A>(_register: VoteRegister<T, A>){
  };

  type OpinionBallot = {
    answer: Cursor;
    date: Time;
  };

  type OpinionInfo = {
    aggregate: Polarization;
  };

  type OpinionVote = {
    ballots: Map<Principal, OpinionBallot>;
    var status: VoteStatus;
    var info: OpinionInfo;
  };

  type OpinionVoteRegister = {
    votes: Map<VoteId, OpinionVote>;
    var index: VoteId;
  };

  class OpinionVotes(register: OpinionVoteRegister){

    // Cannot use that with opinions because OpinionRegister contains a collection of super types
    //let _votes : Votes<Cursor, Polarization> = Votes<Cursor, Polarization>(register);
    public func newVote(date: Time) : VoteId {
    };
    
    public func lockVote(id: VoteId, date: Time) {
    };
    
    public func closeVote(id: VoteId, date: Time) {
    };

  };

  func putBallot<T>(principal: Principal, ballot: Ballot<T>, iter: Iter<(Principal, Ballot<T>)>, put_ballot: () -> ()) {
    for ((principal, ballot) in iter){
      Debug.print("principal: " # Principal.toText(principal));
    };
    put_ballot();
  };

  func putOpinionBallot(vote: OpinionVote, principal: Principal, ballot: OpinionBallot) : ?OpinionBallot {
    let iter : Iter<(Principal, OpinionBallot)> = Map.entries<Principal, OpinionBallot>(vote.ballots);
    var removed : ?OpinionBallot = null;
    let put_ballot = func() {
      removed := Map.put(vote.ballots, Map.phash, principal, ballot);
    };
    putBallot<Cursor>(principal, ballot, iter, put_ballot);
    removed;
  };
};


//// Cannot use super types as argument if:
////  - the argument is a collection (e.g. Map)
////  - the argument is a function that uses the super type as an argument (but return type is ok!)
//suite("Vote test temp test suite", func() {
//  test("ola", func() {
//    let vote : OpinionVote = {
//      ballots = Map.new<Principal, OpinionBallot>(Map.phash);
//      var status = #OPEN;
//      var info = { aggregate : Polarization = { left = 0.0; center = 0.0; right = 0.0; }; };
//    };
//    ignore putOpinionBallot(vote, Principal.fromText("aaaaa-aa"                                                       ), { answer =  0.0; date = 0; });
//    ignore putOpinionBallot(vote, Principal.fromText("l2dqn-dqd5a-er3f7-h472o-ainav-j3ll7-iavjt-4v6ib-c6bom-duooy-uqe"), { answer =  1.0; date = 1; });
//    switch(putOpinionBallot(vote, Principal.fromText("aaaaa-aa"                                                       ), { answer = -1.0; date = 2; })){
//      case(null) { Debug.print("null"); };
//      case(?old) { Debug.print("old = { answer = " # Float.toText(old.answer) # "; date = " # Int.toText(old.date) # " }"); };
//    };
//
//    for ((principal, ballot) in Map.entries<Principal, OpinionBallot>(vote.ballots)){
//      Debug.print("principal: " # Principal.toText(principal) # "; ballot = { answer = " # Float.toText(ballot.answer) # "; date = " # Int.toText(ballot.date) # " }");
//    };
//    
//  });
//});