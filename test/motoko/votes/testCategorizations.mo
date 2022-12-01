import Types "../../../src/godwin_backend/types";
import Utils "../../../src/godwin_backend/utils";
import Categorizations "../../../src/godwin_backend/votes/categorizations";
import Categories "../../../src/godwin_backend/categories";
import Users "../../../src/godwin_backend/users";
import Questions "../../../src/godwin_backend/questions/questions";
import User "../../../src/godwin_backend/user";
import TestableItems "../testableItems";

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
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;

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

      let categories = Categories.Categories(["IDENTITY", "ECONOMY", "CULTURE"]);
      
      let users = Users.empty(categories);
      
      let questions = Questions.empty(categories);
      let question_0 = questions.createQuestion(principal_0, 0, "title0", "text0");
      let question_1 = questions.createQuestion(principal_0, 0, "title1", "text1");

      // Add categorization
      var categorization = Utils.arrayToTrie([("IDENTITY", 1.0), ("ECONOMY", 0.5), ("CULTURE", 0.0)], Types.keyText, Text.equal);
      Categorizations.put(users, principal_0, questions, question_0.id, categorization);
      tests.add(test("Add ballot", User.getCategorization(users.getUser(principal_0), question_0.id), Matchers.equals(TestableItems.optCategoryCursorTrie(?categorization))));
      // Update categorization
      categorization := Utils.arrayToTrie([("IDENTITY", 0.0), ("ECONOMY", 1.0), ("CULTURE", -0.5)], Types.keyText, Text.equal);
      Categorizations.put(users, principal_0, questions, question_0.id, categorization);
      tests.add(test("Update ballot", User.getCategorization(users.getUser(principal_0), question_0.id), Matchers.equals(TestableItems.optCategoryCursorTrie(?categorization))));
      // Remove categorization
      Categorizations.remove(users, principal_0, questions, question_0.id);
      tests.add(test("Remove ballot", User.getCategorization(users.getUser(principal_0), question_0.id), Matchers.equals(TestableItems.optCategoryCursorTrie(null))));
      
      // Test aggregate
      Categorizations.put(users, principal_0, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_1, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_2, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_3, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_4, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_5, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_6, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_7, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_8, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_9, questions, question_1.id, Utils.arrayToTrie([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)], Types.keyText, Text.equal));

      tests.add(test(
        "Get aggregate",
        questions.getQuestion(question_1.id).aggregates.categorization,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
           ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
           ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })],
        Types.keyText, Text.equal)))
      ));

      // Add a new category
      categories.add("JUSTICE");

      // The aggregate shall contain the new category
      tests.add(test(
        "Get aggregate with new category before voting again",
        questions.getQuestion(question_1.id).aggregates.categorization,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
           ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
           ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; }),
           ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })],
        Types.keyText, Text.equal)))
      ));

      // Without the added category, voting shall trap
      Categorizations.put(users, principal_0, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)], Types.keyText, Text.equal));
      
      // Update some votes, the non-updated ballots do not impact the aggregate (meaning they won't even be considered as 0.0)
      Categorizations.put(users, principal_5, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0), ("JUSTICE", -1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_6, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0), ("JUSTICE", -1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_7, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0), ("JUSTICE", -1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_8, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0), ("JUSTICE", -1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_9, questions, question_1.id, Utils.arrayToTrie([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0), ("JUSTICE", -1.0)], Types.keyText, Text.equal));

      // The aggregate shall contain the new category
      tests.add(test(
        "Get aggregate with new category after voting again",
        questions.getQuestion(question_1.id).aggregates.categorization,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
           ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
           ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; }),
           ("JUSTICE",  { left = 5.0; center = 0.0; right = 0.0; })], // For justice, total is 5 and not 10 because only 5 people updated their vote with the new category
        Types.keyText, Text.equal)))
      ));

      // Remove an old category
      categories.remove("ECONOMY");

      // The aggregate shall not have the removed category
      tests.add(test(
        "Get aggregate with new category before voting again",
        questions.getQuestion(question_1.id).aggregates.categorization,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
           ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; }),
           ("JUSTICE",  { left = 5.0; center = 0.0; right = 0.0; })],
        Types.keyText, Text.equal)))
      ));

      // With the removed category, voting shall trap
      Categorizations.put(users, principal_0, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5), ("JUSTICE", -1.0)], Types.keyText, Text.equal));
      // Update some votes
      Categorizations.put(users, principal_0, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("CULTURE",  0.5), ("JUSTICE",  1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_1, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("CULTURE",  0.0), ("JUSTICE",  1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_2, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("CULTURE",  0.0), ("JUSTICE",  1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_3, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  1.0), ("CULTURE",  0.0), ("JUSTICE",  1.0)], Types.keyText, Text.equal));
      Categorizations.put(users, principal_4, questions, question_1.id, Utils.arrayToTrie([("IDENTITY",  0.5), ("CULTURE", -0.5), ("JUSTICE",  1.0)], Types.keyText, Text.equal));
      // The aggregate shall not have the removed category
      tests.add(test(
        "Get aggregate with new category after voting again",
        questions.getQuestion(question_1.id).aggregates.categorization,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
           ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; }),
           ("JUSTICE",  { left = 5.0; center = 0.0; right = 5.0; })],
        Types.keyText, Text.equal)))
      ));

      suite("Test Categorizations module", tests.toArray());
    };
  };
 
};