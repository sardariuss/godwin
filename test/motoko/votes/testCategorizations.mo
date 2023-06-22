import Types "../../../src/godwin_sub/model/Types";
import Categories "../../../src/godwin_sub/model/Categories";
import Categorizations "../../../src/godwin_sub/model/votes/Categorizations";
import Utils "../../../src/godwin_sub/utils/Utils";

//import TestableItems "../testableItems";
import Principals "../Principals";

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
    //Utils.arrayToMap<Text, Cursor>(cursor_array, Map.thash); // @todo
  };

  func toPolarizationMap(polarization_array: PolarizationArray): PolarizationMap {
    Utils.arrayToTrie(polarization_array, Categories.key, Categories.equal);
    //Utils.arrayToMap<Text, Polarization>(polarization_array, Map.thash); // @todo
  };

  public func run() {
    
    let tests = Buffer.Buffer<Suite.Suite>(0);
    let principals = Principals.init();

    let categories = Categories.build(Categories.initRegister([
      ("IDENTITY", { left = { name = "CONSTRUCTIVISM";   symbol = "🧩"; color = "#f26c0d"; }; right = { name = "ESSENTIALISM"; symbol = "💎"; color = "#f2a60d"; }; }),
      ("ECONOMY",  { left = { name = "SOCIALISM";        symbol = "🌹";  color = "#0fca02"; }; right = { name = "CAPITALISM";   symbol = "🎩"; color = "#02ca27"; }; }),
      ("CULTURE",  { left = { name = "PROGRESSIVISM";    symbol = "🌊"; color = "#2c00cc"; }; right = { name = "CONSERVATISM"; symbol = "🧊"; color = "#5f00cc"; }; }),
    ]));
    let votes = Categorizations.build(Categorizations.initRegister(), categories);

    // Question 0 : arbitrary question_id, iteration and date
    let question_0 : Nat = 0;
    votes.newVote(question_0);

    // Add categorization
    var ballot = { date = 123456789; answer = toCursorMap([("IDENTITY", 1.0), ("ECONOMY", 0.5), ("CULTURE", 0.0)]) };
    votes.putBallot(principals[0], question_0, ballot);
    tests.add(Suite.test(
      "Add ballot", 
      votes.findBallot(principals[0], question_0), 
      Matchers.equals(TestableItems.optCategorizationBallot(?ballot))
    ));
    // Update categorization
    ballot := { ballot with answer = toCursorMap([("IDENTITY", 0.0), ("ECONOMY", 1.0), ("CULTURE", -0.5)]) };
    votes.putBallot(principals[0], question_0, ballot);
    tests.add(Suite.test(
      "Update ballot",
      votes.findBallot(principals[0], 0),
      Matchers.equals(TestableItems.optCategorizationBallot(?ballot))
    ));
    // Remove categorization
    votes.removeBallot(principals[0], question_0);
    tests.add(Suite.test(
      "Remove ballot",
      votes.findBallot(principals[0], question_0),
      Matchers.equals(TestableItems.optCategorizationBallot(null))
    ));

    // Question 1 : arbitrary question_id, iteration and date
    let question_1 : Nat = 1;
    let date_1 : Time = 987654321;
    votes.newVote(question_1);

    votes.putBallot(principals[0], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)]); });
    votes.putBallot(principals[1], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[2], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[3], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[4], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)]); });
    votes.putBallot(principals[5], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[6], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[7], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[8], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[9], question_1, { date = date_1; answer = toCursorMap([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)]); });

    tests.add(Suite.test(
      "Get aggregate (1)",
      votes.getVote(question_1).aggregate,
      Matchers.equals(TestableItems.polarizationMap(toPolarizationMap(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
            ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
            ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
      ))
    )));

    // Update some votes, the non-updated ballots do not impact the aggregate (meaning they won't even be considered as 0.0)
    votes.putBallot(principals[5], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[6], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[7], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[8], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]); });
    votes.putBallot(principals[9], question_1, { date = date_1; answer = toCursorMap([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)]); });

    // The aggregate shall contain the new category
    tests.add(Suite.test(
      "Get aggregate (2)",
      votes.getVote(question_1).aggregate,
      Matchers.equals(TestableItems.polarizationMap(toPolarizationMap(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
            ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
            ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
      ))
    )));

    // Update some votes
    votes.putBallot(principals[0], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)]); });
    votes.putBallot(principals[1], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[2], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[3], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)]); });
    votes.putBallot(principals[4], question_1, { date = date_1; answer = toCursorMap([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)]); });
    // The aggregate shall not have the removed category
    tests.add(Suite.test(
      "Get aggregate (3)",
      votes.getVote(question_1).aggregate,
      Matchers.equals(TestableItems.polarizationMap(toPolarizationMap(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
            ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
            ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
      ))
    )));

    Suite.run(Suite.suite("Test Categorizations module", Buffer.toArray(tests)));
  };
};