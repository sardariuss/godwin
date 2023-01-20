import Types "../../../src/godwin_backend/types";
import Utils "../../../src/godwin_backend/utils";
import Votes "../../../src/godwin_backend/votes/votes";
import Categorization "../../../src/godwin_backend/votes/categorization";
import CategoryPolarizationTrie "../../../src/godwin_backend/representation/categoryPolarizationTrie";
import TestableItems "../testableItems";

import Map "mo:map/Map";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Time = Int;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from other modules
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type CategoryCursorArray = Types.CategoryCursorArray;
  type CategoryPolarizationArray = Types.CategoryPolarizationArray;
  type Ballot<T> = Types.Ballot<T>;

  type Map<K, V> = Map.Map<K, V>;

  func toCursorTrie(categorization: CategoryCursorArray): CategoryCursorTrie {
    Utils.arrayToTrie(categorization, Types.keyText, Text.equal);
  };

  func toPolarizationTrie(categorization: CategoryPolarizationArray): CategoryPolarizationTrie {
    Utils.arrayToTrie(categorization, Types.keyText, Text.equal);
  };

  public class TestCategorizations() = {

    let principal_0 = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe");
    let principal_1 = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae");
    let principal_2 = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe");
    let principal_3 = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe");
    let principal_4 = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae");
    let principal_5 = Principal.fromText("lejdd-efwn5-h3qqe-4bunw-faabt-qwb7j-oiskz-c3dkg-3q5z5-ozrtn-dqe");
    let principal_6 = Principal.fromText("amerw-mz3nq-gfkbp-o3qgo-zldsl-upilh-zatjw-66nkr-527cf-m7hnq-pae");
    let principal_7 = Principal.fromText("gbvlf-igtmq-g5vs2-skrhr-txgij-4f2j3-v2jqy-re5cm-i6hsu-gpzcd-aae");
    let principal_8 = Principal.fromText("mrdr7-aufxf-oiq6j-hyib2-rxb5m-cqrnb-uzgyq-durnt-75u4x-rrvow-iae");
    let principal_9 = Principal.fromText("zoyw4-o2dcy-xajcf-e2nvu-436rg-ghrbs-35bzk-nakpb-mvs7t-x4byt-nqe");

    public func getSuite() : Suite.Suite {
      
      let tests = Buffer.Buffer<Suite.Suite>(0);

      let votes = Categorization.build(
        Map.new<Principal, Map<Nat, Map<Nat, Timestamp<CategoryCursorTrie>>>>(),
        Map.new<Nat, Map<Nat, Timestamp<CategoryPolarizationTrie>>>(),
        ["IDENTITY", "ECONOMY", "CULTURE"]
      );

      // Question 0 : arbitrary question_id, iteration and date
      let question_0 : Nat = 0;
      let iteration_0 : Nat = 0;
      let date_0 : Time = 123456789;
      votes.newAggregate(question_0, iteration_0, date_0);

      // Add categorization
      var categorization = toCursorTrie([("IDENTITY", 1.0), ("ECONOMY", 0.5), ("CULTURE", 0.0)]);
      votes.putBallot(principal_0, question_0, iteration_0, date_0, categorization);
      tests.add(test(
        "Add ballot", 
        votes.getBallot(principal_0, question_0, iteration_0), 
        Matchers.equals(TestableItems.optCategorizationBallot(?{ date = date_0; elem = categorization; }))
      ));
      // Update categorization
      categorization := toCursorTrie([("IDENTITY", 0.0), ("ECONOMY", 1.0), ("CULTURE", -0.5)]);
      votes.putBallot(principal_0, question_0, iteration_0, date_0, categorization);
      tests.add(test(
        "Update ballot",
        votes.getBallot(principal_0, 0, 0),
        Matchers.equals(TestableItems.optCategorizationBallot(?{ date = date_0; elem = categorization; }))
      ));
      // Remove categorization
      votes.removeBallot(principal_0, question_0, iteration_0);
      tests.add(test(
        "Remove ballot",
        votes.getBallot(principal_0, question_0, iteration_0),
        Matchers.equals(TestableItems.optCategorizationBallot(null))
      ));

      // Question 1 : arbitrary question_id, iteration and date
      let question_1 : Nat = 1;
      let iteration_1 : Nat = 1;
      let date_1 : Time = 987654321;
      votes.newAggregate(question_1, iteration_1, date_1);

      votes.putBallot(principal_0, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)]));
      votes.putBallot(principal_1, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]));
      votes.putBallot(principal_2, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]));
      votes.putBallot(principal_3, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)]));
      votes.putBallot(principal_4, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)]));
      votes.putBallot(principal_5, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)]));
      votes.putBallot(principal_6, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]));
      votes.putBallot(principal_7, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]));
      votes.putBallot(principal_8, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]));
      votes.putBallot(principal_9, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)]));

      tests.add(test(
        "Get aggregate (1)",
        votes.getAggregate(question_1, iteration_1),
        Matchers.equals(TestableItems.optCategorizationAggregate(?{
          date = date_1;
          elem = toPolarizationTrie(
            [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
             ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
             ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
          )
        })
      )));

      // Update some votes, the non-updated ballots do not impact the aggregate (meaning they won't even be considered as 0.0)
      votes.putBallot(principal_5, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)]));
      votes.putBallot(principal_6, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]));
      votes.putBallot(principal_7, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]));
      votes.putBallot(principal_8, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)]));
      votes.putBallot(principal_9, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)]));

      // The aggregate shall contain the new category
      tests.add(test(
        "Get aggregate (2)",
        votes.getAggregate(question_1, iteration_1),
        Matchers.equals(TestableItems.optCategorizationAggregate(?{
          date = date_1;
          elem = toPolarizationTrie(
            [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
             ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
             ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
          )
        })
      )));

      // Update some votes
      votes.putBallot(principal_0, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)]));
      votes.putBallot(principal_1, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]));
      votes.putBallot(principal_2, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)]));
      votes.putBallot(principal_3, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)]));
      votes.putBallot(principal_4, question_1, iteration_1, date_1, toCursorTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)]));
      // The aggregate shall not have the removed category
      tests.add(test(
        "Get aggregate (3)",
        votes.getAggregate(question_1, iteration_1),
        Matchers.equals(TestableItems.optCategorizationAggregate(?{
          date = date_1;
          elem = toPolarizationTrie(
            [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
             ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
             ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })]
          )
        })
      )));

      suite("Test Categorizations module", Buffer.toArray(tests));
    };
  };
 
};