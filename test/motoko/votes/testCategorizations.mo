import Types "../../../src/godwin_backend/types";
import Utils "../../../src/godwin_backend/utils";
import Categories "../../../src/godwin_backend/categories";
import Question "../../../src/godwin_backend/questions/question";
import Iteration "../../../src/godwin_backend/votes/iteration";
import Polarization "../../../src/godwin_backend/representation/polarization";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from other modules
  type Question = Types.Question;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;

  func unwrapBallot(question: Question, principal: Principal) : ?CategoryCursorTrie {
    Trie.get<Principal, CategoryCursorTrie>(Question.unwrapIteration(question).categorization.ballots, Types.keyPrincipal(principal), Principal.equal);
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

      var categories = Categories.fromArray(["IDENTITY", "ECONOMY", "CULTURE"]);
      var question_0 : Question = { 
        id = 0; 
        author = principal_0;
        title = "";
        text = "";
        date = 0;
        status = #OPEN( { stage = #CATEGORIZATION; iteration = Iteration.openCategorization(Iteration.new(0), 0, Categories.toArray(categories)); } );
        interests_history = [];
        vote_history = []; 
      };

      // Add categorization
      var categorization = Utils.arrayToTrie([("IDENTITY", 1.0), ("ECONOMY", 0.5), ("CULTURE", 0.0)], Types.keyText, Text.equal);
      Result.iterate(Question.putCategorization(question_0, principal_0, categorization), func(q: Question) { question_0 := q; });
      tests.add(test("Add ballot", unwrapBallot(question_0, principal_0), Matchers.equals(TestableItems.optCategoryCursorTrie(?categorization))));
      // Update categorization
      categorization := Utils.arrayToTrie([("IDENTITY", 0.0), ("ECONOMY", 1.0), ("CULTURE", -0.5)], Types.keyText, Text.equal);
      Result.iterate(Question.putCategorization(question_0, principal_0, categorization), func(q: Question) { question_0 := q; });
      tests.add(test("Update ballot", unwrapBallot(question_0, principal_0), Matchers.equals(TestableItems.optCategoryCursorTrie(?categorization))));
      // Remove categorization
      Result.iterate(Question.removeCategorization(question_0, principal_0), func(q: Question) { question_0 := q; });
      tests.add(test("Remove ballot", unwrapBallot(question_0, principal_0), Matchers.equals(TestableItems.optCategoryCursorTrie(null))));

      var question_1 : Question = { 
        id = 0; 
        author = principal_0;
        title = "";
        text = "";
        date = 0;
        status = #OPEN( { stage = #CATEGORIZATION; iteration = Iteration.openCategorization(Iteration.new(0), 0, Categories.toArray(categories)); });
        interests_history = [];
        vote_history = []; 
      };
      
      // Test aggregate
      Result.iterate(Question.putCategorization(question_1, principal_0, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_1, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_2, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_3, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_4, Utils.arrayToTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_5, Utils.arrayToTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_6, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_7, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_8, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_9, Utils.arrayToTrie([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });

      tests.add(test(
        "Get aggregate (1)",
        Question.unwrapIteration(question_1).categorization.aggregate,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
           ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
           ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })],
        Types.keyText, Text.equal)))
      ));

      // Update some votes, the non-updated ballots do not impact the aggregate (meaning they won't even be considered as 0.0)
      Result.iterate(Question.putCategorization(question_1, principal_5, Utils.arrayToTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_6, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_7, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_8, Utils.arrayToTrie([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_9, Utils.arrayToTrie([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });

      // The aggregate shall contain the new category
      tests.add(test(
        "Get aggregate (2)",
        Question.unwrapIteration(question_1).categorization.aggregate,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
           ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
           ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })],
        Types.keyText, Text.equal)))
      ));

      // Update some votes
      Result.iterate(Question.putCategorization(question_1, principal_0, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_1, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_2, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_3, Utils.arrayToTrie([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putCategorization(question_1, principal_4, Utils.arrayToTrie([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)], Types.keyText, Text.equal)), func(q: Question) { question_1 := q; });
      // The aggregate shall not have the removed category
      tests.add(test(
        "Get aggregate (3)",
        Question.unwrapIteration(question_1).categorization.aggregate,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie(
          [("IDENTITY", { left = 1.0; center = 4.0; right = 5.0; }),
           ("ECONOMY",  { left = 0.5; center = 8.0; right = 1.5; }),
           ("CULTURE",  { left = 5.5; center = 4.0; right = 0.5; })],
        Types.keyText, Text.equal)))
      ));

      suite("Test Categorizations module", tests.toArray());
    };
  };
 
};