import Types "../../../src/godwin_backend/model/Types";
import Interests "../../../src/godwin_backend/model/votes/Interests";

import WSet "../../../src/godwin_backend/utils/wrappers/WSet";
import Set "mo:map/Set";
import Map "mo:map/Map";
import Prim "mo:prim";

import TestableItems "../testableItems";
import Principals "../Principals";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;

  type Set<K> = Set.Set<K>;
  type HashUtils<K> = Set.HashUtils<K>;

  public func run() {

//    type Key = (Principal, Text);
//
//    let pthash: Map.HashUtils<Key> = (
//      func(key: Key) : Nat = Nat32.toNat((Prim.hashBlob(Prim.blobOfPrincipal(key.0)) +% Prim.hashBlob(Prim.encodeUtf8(key.1))) & 0x3fffffff),
//      func(a: Key, b: Key) : Bool = a.0 == b.0 and a.1 == b.1
//    );

    type Key = (Nat, Nat);

    let keyhash: Map.HashUtils<Key> = (
      func(key: Key) : Nat = Nat32.toNat((Nat32.fromNat(key.0) +% Nat32.fromNat(key.1)) & 0x3fffffff),
      func(a: Key, b: Key) : Bool = a.0 == b.0 and a.1 == b.1
    );

    let set = WSet.WSet<Key>(Set.new<Key>(), keyhash);
    set.add((4, 4));
    set.add((2, 2));
    set.add((321329107, 321329107));
    set.add((2, 3));
    set.delete((2, 2));
    set.add((6, 6));
    
    for (key in set.keys()) {
      Debug.print(Nat.toText(key.0) # " " # Nat.toText(key.1));
    };
    
    let tests = Buffer.Buffer<Suite.Suite>(0);
    let principals = Principals.init();

    let votes = Interests.build(Interests.initRegister());

    // Question 0 : arbitrary question_id, iteration and date
    let question_0 : Nat = 0;
    let iteration_0 : Nat = 0;
    let date_0 : Time = 123456789;
    votes.newVote(question_0, iteration_0, date_0);

    // Add interest
    var ballot : Interests.Ballot = { date = date_0; answer = #UP};
    votes.putBallot(principals[0], question_0, iteration_0, ballot);
    tests.add(Suite.test(
      "Add Interests",
      votes.getBallot(principals[0], question_0, iteration_0),
      Matchers.equals(TestableItems.optInterestBallot(?ballot))
    ));
    // Update interest
    ballot := { ballot with answer = #DOWN };
    votes.putBallot(principals[0], question_0, iteration_0, ballot);
    tests.add(Suite.test(
      "Update Interests",
      votes.getBallot(principals[0], question_0, iteration_0),
      Matchers.equals(TestableItems.optInterestBallot(?ballot))
    ));
    // Remove interest
    votes.removeBallot(principals[0], question_0, iteration_0);
    tests.add(Suite.test(
      "Remove Interests",
      votes.getBallot(principals[0], question_0, iteration_0),
      Matchers.equals(TestableItems.optInterestBallot(null))
    ));

    // Question 1 : arbitrary question_id, iteration and date
    let question_1 : Nat = 1;
    let iteration_1 : Nat = 1;
    let date_1 : Time = 987654321;
    votes.newVote(question_1, iteration_1, date_1);

    // Test only ups ( 10 VS 0 )
    votes.putBallot(principals[0], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[1], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[2], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[3], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[4], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[5], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[6], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[7], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[8], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[9], question_1, iteration_1, { date = date_1; answer = #UP; });
    tests.add(Suite.test(
      "Get aggregate (1)",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.appeal({ ups = 10; downs = 0; score = 10; })
    )));

    // Test only downs ( 0 VS 10 )
    votes.putBallot(principals[0], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[1], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[2], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[3], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[4], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[5], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[6], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[7], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[8], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[9], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    tests.add(Suite.test(
      "Get aggregate (2)",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.appeal({ ups = 0; downs = 10; score = -10; })
    )));

    // Test as many ups than downs ( 5 VS 5 )
    votes.putBallot(principals[0], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[1], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[2], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[3], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[4], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[5], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[6], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[7], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[8], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[9], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    tests.add(Suite.test(
      "Get aggregate (3)",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.appeal({ ups = 5; downs = 5; score = 0; })
    )));

    // Test almost only ups ( 9 VS 1 )
    votes.putBallot(principals[0], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[1], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[2], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[3], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[4], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[5], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[6], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[7], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[8], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[9], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    tests.add(Suite.test(
      "Get aggregate (4)",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.appeal({ ups = 9; downs = 1; score = 9; }) // down votes have no effect
    )));

    // Test slight majority of ups ( 4 VS 3 )
    votes.putBallot(principals[0], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[1], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[2], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[3], question_1, iteration_1, { date = date_1; answer = #UP; });
    votes.putBallot(principals[4], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[5], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.putBallot(principals[6], question_1, iteration_1, { date = date_1; answer = #DOWN; });
    votes.removeBallot(principals[7], question_1, iteration_1);
    votes.removeBallot(principals[8], question_1, iteration_1);
    votes.removeBallot(principals[9], question_1, iteration_1);
    tests.add(Suite.test(
      "Get aggregate (1)",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.appeal({ ups = 4; downs = 3; score = 3; }) // down votes have a slight effect
    )));

    Suite.run(Suite.suite("Test Interests module", Buffer.toArray(tests)));
  };
};