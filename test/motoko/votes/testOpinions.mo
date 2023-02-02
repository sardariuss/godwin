import Types "../../../src/godwin_backend/model/Types";
import Opinions "../../../src/godwin_backend/model/votes/Opinions";

import TestableItems "../testableItems";
import Principals "../Principals";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Time = Int;

  public func run() {

    let tests = Buffer.Buffer<Suite.Suite>(0);
    let principals = Principals.init();

    let votes = Opinions.build(Opinions.initRegister());

    // Question 0 : arbitrary question_id, iteration and date
    let question_0 : Nat = 0;
    let iteration_0 : Nat = 0;
    let date_0 : Time = 123456789;
    votes.newVote(question_0, iteration_0, date_0);

    // Add opinion
    var ballot = { date = date_0; answer = 0.0; };
    votes.putBallot(principals[0], question_0, iteration_0, ballot);
    tests.add(Suite.test(
      "Add ballot",
      votes.getBallot(principals[0], question_0, iteration_0),
      Matchers.equals(TestableItems.optOpinionBallot(?ballot))
    ));
    // Update opinion
    ballot := { ballot with answer = 1.0; };
    votes.putBallot(principals[0], question_0, iteration_0, ballot);
    tests.add(Suite.test(
      "Update ballot",
      votes.getBallot(principals[0], question_0, iteration_0),
      Matchers.equals(TestableItems.optOpinionBallot(?ballot))
    ));
    // Remove opinion
    votes.removeBallot(principals[0], question_0, iteration_0);
    tests.add(Suite.test(
      "Remove ballot",
      votes.getBallot(principals[0], question_0, iteration_0),
      Matchers.equals(TestableItems.optOpinionBallot(null))
    ));

    // Question 1 : arbitrary question_id, iteration and date
    let question_1 : Nat = 1;
    let iteration_1 : Nat = 1;
    let date_1 : Time = 987654321;
    votes.newVote(question_1, iteration_1, date_1);
    
    // Test aggregate
    votes.putBallot(principals[0], question_1, iteration_1, { date = date_1; answer = 1.0; });
    votes.putBallot(principals[1], question_1, iteration_1, { date = date_1; answer = 0.5; });
    votes.putBallot(principals[2], question_1, iteration_1, { date = date_1; answer = 0.5; });
    votes.putBallot(principals[3], question_1, iteration_1, { date = date_1; answer = 0.5; });
    votes.putBallot(principals[4], question_1, iteration_1, { date = date_1; answer = 0.5; });
    votes.putBallot(principals[5], question_1, iteration_1, { date = date_1; answer = 0.5; });
    votes.putBallot(principals[6], question_1, iteration_1, { date = date_1; answer = 0.0; });
    votes.putBallot(principals[7], question_1, iteration_1, { date = date_1; answer = 0.0; });
    votes.putBallot(principals[8], question_1, iteration_1, { date = date_1; answer =-1.0; });
    votes.putBallot(principals[9], question_1, iteration_1, { date = date_1; answer =-1.0; });
    tests.add(Suite.test(
      "Opinion aggregate",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.polarization({left = 2.0; center = 4.5; right = 3.5;}))
    ));

    Suite.run(Suite.suite("Test Opinions module", Buffer.toArray(tests)));
  };

};