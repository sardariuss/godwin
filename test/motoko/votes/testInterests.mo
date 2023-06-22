import VoteTypes              "../../../src/godwin_sub/model/votes/Types";
import Interests              "../../../src/godwin_sub/model/votes/Interests";
import PayTypes               "../../../src/godwin_sub/model/token/Types";
import PayForNew              "../../../src/godwin_sub/model/token/PayForNew";
import QuestionVoteJoins      "../../../src/godwin_sub/model/votes/QuestionVoteJoins";
import QuestionQueriesFactory "../../../src/godwin_sub/model/questions/QueriesFactory";

import Ref                "../../../src/godwin_sub/utils/Ref";

import MockTokenInterface "../MockTokenInterface";
import TestifyTypes       "../testifyTypes";
import Principals         "../Principals";

import Testify            "mo:testing/Testify";
import SuiteState         "mo:testing/SuiteState";
import TestStatus         "mo:testing/Status";

import Map                "mo:map/Map";

import Principal          "mo:base/Principal";
import Nat                "mo:base/Nat";

module {

  type InterestBallot     = VoteTypes.InterestBallot;
  type InterestVote       = VoteTypes.InterestVote;
  type Polarization       = VoteTypes.Polarization;
  type VoteId             = VoteTypes.VoteId;
  type Cursor             = VoteTypes.Cursor;
  type TransactionsRecord = PayTypes.TransactionsRecord;
  type Interests          = Interests.Interests;

  type NamedTest<T>       = SuiteState.NamedTest<T>;
  type Suite<T>           = SuiteState.Suite<T>;
  type TestStatus         = TestStatus.Status;
  type TestAsync<T>       = SuiteState.TestAsync<T>;

  type Map<K, V>          = Map.Map<K, V>;

  // For convenience: from base module
  type Time               = Int;

  let { testifyElement; optionalTestify; } = Testify;
  let { describe; itp; equal; itsp; } = SuiteState;

  let { testify_opinion_ballot; testify_nat; testify_polarization; testify_opinion_vote; } = TestifyTypes;

  public func run(test_status: TestStatus) : async* () {
    
    let principals = Principals.init();

    let token_interface = MockTokenInterface.MockTokenInterface();

    let interests = Interests.build(
      Interests.initRegister(),
      Map.new<Principal, Map<VoteId, TransactionsRecord>>(Map.phash),
      token_interface,
      PayForNew.build(
        token_interface,
        #OPEN_QUESTION,
        Map.new<Nat, (Principal, Blob)>(Map.nhash),
        Ref.init<Nat>(0),
        Map.new<Principal, Map<VoteId, TransactionsRecord>>(Map.phash)
      ),
      QuestionVoteJoins.build(QuestionVoteJoins.initRegister()),
      QuestionQueriesFactory.build(QuestionQueriesFactory.initRegister())
    );

    let s = SuiteState.Suite<Interests>(interests);
    //let interests = Interests.build(Interests.initRegister());

//    // Question 0 : arbitrary question_id, iteration and date
//    let question_0 : Nat = 0;
//    interests.newVote(question_0);
//
//    // Add interest
//    var ballot : Interests.Ballot = { date = 123456789; answer = #UP};
//    interests.putBallot(principals[0], question_0, ballot);
//    tests.add(Suite.test(
//      "Add Interests",
//      interests.findBallot(principals[0], question_0),
//      Matchers.equals(TestableItems.optInterestBallot(?ballot))
//    ));
//    // Update interest
//    ballot := { ballot with answer = #DOWN };
//    interests.putBallot(principals[0], question_0, ballot);
//    tests.add(Suite.test(
//      "Update Interests",
//      interests.findBallot(principals[0], question_0),
//      Matchers.equals(TestableItems.optInterestBallot(?ballot))
//    ));
//    // Remove interest
//    interests.removeBallot(principals[0], question_0);
//    tests.add(Suite.test(
//      "Remove Interests",
//      interests.findBallot(principals[0], question_0),
//      Matchers.equals(TestableItems.optInterestBallot(null))
//    ));
//
//    // Question 1 : arbitrary question_id, iteration and date
//    let question_1 : Nat = 1;
//    let date_1 : Time = 987654321;
//    interests.newVote(question_1);
//
//    // Test only ups ( 10 VS 0 )
//    interests.putBallot(principals[0], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[1], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[2], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[3], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[4], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[5], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[6], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[7], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[8], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[9], question_1, { date = date_1; answer = #UP; });
//    tests.add(Suite.test(
//      "Get aggregate (1)",
//      interests.getVote(question_1).aggregate,
//      Matchers.equals(TestableItems.appeal({ ups = 10; downs = 0; score = 10; })
//    )));
//
//    // Test only downs ( 0 VS 10 )
//    interests.putBallot(principals[0], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[1], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[2], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[3], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[4], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[5], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[6], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[7], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[8], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[9], question_1, { date = date_1; answer = #DOWN; });
//    tests.add(Suite.test(
//      "Get aggregate (2)",
//      interests.getVote(question_1).aggregate,
//      Matchers.equals(TestableItems.appeal({ ups = 0; downs = 10; score = -10; })
//    )));
//
//    // Test as many ups than downs ( 5 VS 5 )
//    interests.putBallot(principals[0], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[1], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[2], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[3], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[4], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[5], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[6], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[7], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[8], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[9], question_1, { date = date_1; answer = #DOWN; });
//    tests.add(Suite.test(
//      "Get aggregate (3)",
//      interests.getVote(question_1).aggregate,
//      Matchers.equals(TestableItems.appeal({ ups = 5; downs = 5; score = 0; })
//    )));
//
//    // Test almost only ups ( 9 VS 1 )
//    interests.putBallot(principals[0], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[1], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[2], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[3], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[4], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[5], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[6], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[7], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[8], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[9], question_1, { date = date_1; answer = #DOWN; });
//    tests.add(Suite.test(
//      "Get aggregate (4)",
//      interests.getVote(question_1).aggregate,
//      Matchers.equals(TestableItems.appeal({ ups = 9; downs = 1; score = 9; }) // down interests have no effect
//    )));
//
//    // Test slight majority of ups ( 4 VS 3 )
//    interests.putBallot(principals[0], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[1], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[2], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[3], question_1, { date = date_1; answer = #UP; });
//    interests.putBallot(principals[4], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[5], question_1, { date = date_1; answer = #DOWN; });
//    interests.putBallot(principals[6], question_1, { date = date_1; answer = #DOWN; });
//    interests.removeBallot(principals[7], question_1);
//    interests.removeBallot(principals[8], question_1);
//    interests.removeBallot(principals[9], question_1);
//    tests.add(Suite.test(
//      "Get aggregate (1)",
//      interests.getVote(question_1).aggregate,
//      Matchers.equals(TestableItems.appeal({ ups = 4; downs = 3; score = 3; }) // down interests have a slight effect
//    )));
//
//    Suite.run(Suite.suite("Test Interests module", Buffer.toArray(tests)));
  };
};