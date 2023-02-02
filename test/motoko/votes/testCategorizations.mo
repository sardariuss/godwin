import Types "../../../src/godwin_backend/model/Types";
import Categories "../../../src/godwin_backend/model/Categories";
import Categorizations "../../../src/godwin_backend/model/votes/Categorizations";
import Utils "../../../src/godwin_backend/utils/Utils";

import TestableItems "../testableItems";
import Principals "../Principals";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;
  // For convenience: from other modules
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type CursorArray = Types.CursorArray;
  type PolarizationArray = Types.PolarizationArray;

  func toCursorMap(cursor_array: CursorArray): CursorMap {
    Utils.arrayToTrie(cursor_array, Categories.key, Categories.equal);
    //Utils.arrayToMap<Text, Cursor>(cursor_array, Map.thash);
  };

  func toPolarizationMap(polarization_array: PolarizationArray): PolarizationMap {
    Utils.arrayToTrie(polarization_array, Categories.key, Categories.equal);
    //Utils.arrayToMap<Text, Polarization>(polarization_array, Map.thash);
  };

  public func run() {
    
    let tests = Buffer.Buffer<Suite.Suite>(0);
    let principals = Principals.init();

    let categories = Categories.build(Categories.initRegister(["IDENTITY", "ECONOMY", "CULTURE"]));
    let votes = Categorizations.build(Categorizations.initRegister(), categories);

    // Question 0 : arbitrary question_id, iteration and date
    let question_0 : Nat = 0;
    let iteration_0 : Nat = 0;
    let date_0 : Time = 123456789;
    votes.newVote(question_0, iteration_0, date_0);

    // Add categorization
    var ballot = { date = date_0; answer = toCursorMap([("IDENTITY", 1.0), ("ECONOMY", 0.5), ("CULTURE", 0.0)]) };
    votes.putBallot(principals[0], question_0, iteration_0, ballot);
    tests.add(Suite.test(
      "Add ballot", 
      votes.getBallot(principals[0], question_0, iteration_0), 
      Matchers.equals(TestableItems.optCategorizationBallot(?ballot))
    ));
    // Update categorization
    ballot := { ballot with answer = toCursorMap([("IDENTITY", 0.0), ("ECONOMY", 1.0), ("CULTURE", -0.5)]) };
    votes.putBallot(principals[0], question_0, iteration_0, ballot);
    tests.add(Suite.test(
      "Update ballot",
      votes.getBallot(principals[0], 0, 0),
      Matchers.equals(TestableItems.optCategorizationBallot(?ballot))
    ));
    // Remove categorization
    votes.removeBallot(principals[0], question_0, iteration_0);
    tests.add(Suite.test(
      "Remove ballot",
      votes.getBallot(principals[0], question_0, iteration_0),
      Matchers.equals(TestableItems.optCategorizationBallot(null))
    ));

    // Question 1 : arbitrary question_id, iteration and date
    let question_1 : Nat = 1;
    let iteration_1 : Nat = 1;
    let date_1 : Time = 987654321;
    votes.newVote(question_1, iteration_1, date_1);

    votes.putBallot(principals[0], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)]); });
    votes.putBallot(principals[1], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[2], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[3], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[4], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)]); });
    votes.putBallot(principals[5], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[6], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[7], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[8], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[9], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)]); });

    tests.add(Suite.test(
      "Get aggregate (1)",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.polarizationMap(toPolarizationMap(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
            ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
            ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
      ))
    )));

    // Update some votes, the non-updated ballots do not impact the aggregate (meaning they won't even be considered as 0.0)
    votes.putBallot(principals[5], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[6], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[7], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[8], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[9], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)]); });

    // The aggregate shall contain the new category
    tests.add(Suite.test(
      "Get aggregate (2)",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.polarizationMap(toPolarizationMap(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
            ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
            ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
      ))
    )));

    // Update some votes
    votes.putBallot(principals[0], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)]); });
    votes.putBallot(principals[1], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[2], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[3], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[4], question_1, iteration_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)]); });
    // The aggregate shall not have the removed category
    tests.add(Suite.test(
      "Get aggregate (3)",
      votes.getVote(question_1, iteration_1).aggregate,
      Matchers.equals(TestableItems.polarizationMap(toPolarizationMap(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
            ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
            ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
      ))
    )));

    Suite.run(Suite.suite("Test Categorizations module", Buffer.toArray(tests)));
  };
};