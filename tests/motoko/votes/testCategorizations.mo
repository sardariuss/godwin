import Types "../../../src/godwin_backend/types";
import Utils "../../../src/godwin_backend/utils";
import Categorizations "../../../src/godwin_backend/votes/categorizations";
import TestableItemExtension "../testableItemExtension";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types modules
  type Categorization = Types.Categorization;
  // For convenience: from other modules
  type Categorizations = Categorizations.Categorizations;

  func toTextCategorization(categorization: Categorization) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(Trie.size(categorization));
    for ((category, cursor) in Trie.iter(categorization)){
      buffer.add("(category: " # category # ", cursor: " # Float.toText(cursor) # ")");
    };
    Text.join(", ", buffer.vals());
  };

  func equalCategorizations(categorization1: Categorization, categorization2: Categorization) : Bool {
    if (Trie.size(categorization1) != Trie.size(categorization2)){
      return false;
    };
    if (Trie.size(categorization1) == Trie.size(categorization2)){
      for ((category1, cursor1) in Trie.iter(categorization1)){
        switch(Trie.get(categorization2, Types.keyText(category1), Text.equal)){
          case(null) { return false; };
          case(?cursor2) { if (cursor1 != cursor2) { return false; }; };
        };
      };
    };
    return true;
  };

  func testOptCategorization(categorization: ?Categorization) : Testable.TestableItem<?Categorization> {
    TestableItemExtension.testOptItem(categorization, toTextCategorization, equalCategorizations);
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

      let categories_definition = [
        ("IDENTITY", { left = "CONSTRUCTIVISM"; right = "ESSENTIALISM"; }),
        ("ECONOMY", { left = "REGULATION"; right = "LAISSEZFAIRE"; }),
        ("CULTURE", { left = "PROGRESSIVISM"; right = "CONSERVATISM"; })
      ];

      let categorizations = Categorizations.empty(Utils.fromArray(categories_definition, Types.keyText, Text.equal));

      // Add categorization
      var categorization = Utils.fromArray([("IDENTITY", 1.0), ("ECONOMY", 0.5), ("CULTURE", 0.0)], Types.keyText, Text.equal);
      categorizations.put(principal_0, 0, categorization);
      tests.add(test("Add categorization", categorizations.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptCategorization(?categorization))));
      // Update categorization
      categorization := Utils.fromArray([("IDENTITY", 0.0), ("ECONOMY", 1.0), ("CULTURE", -0.5)], Types.keyText, Text.equal);
      categorizations.put(principal_0, 0, categorization);
      tests.add(test("Update categorization", categorizations.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptCategorization(?categorization))));
      // Remove categorization
      categorizations.remove(principal_0, 0);
      tests.add(test("Remove categorization", categorizations.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptCategorization(null))));
      
      // Test mean
      categorizations.put(principal_0, 1, Utils.fromArray([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.5)], Types.keyText, Text.equal));
      categorizations.put(principal_1, 1, Utils.fromArray([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)], Types.keyText, Text.equal));
      categorizations.put(principal_2, 1, Utils.fromArray([("IDENTITY",  1.0), ("ECONOMY",  0.5), ("CULTURE",  0.0)], Types.keyText, Text.equal));
      categorizations.put(principal_3, 1, Utils.fromArray([("IDENTITY",  1.0), ("ECONOMY",  0.0), ("CULTURE",  0.0)], Types.keyText, Text.equal));
      categorizations.put(principal_4, 1, Utils.fromArray([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -0.5)], Types.keyText, Text.equal));
      categorizations.put(principal_5, 1, Utils.fromArray([("IDENTITY",  0.5), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      categorizations.put(principal_6, 1, Utils.fromArray([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      categorizations.put(principal_7, 1, Utils.fromArray([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      categorizations.put(principal_8, 1, Utils.fromArray([("IDENTITY",  0.0), ("ECONOMY",  0.0), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      categorizations.put(principal_9, 1, Utils.fromArray([("IDENTITY", -1.0), ("ECONOMY", -0.5), ("CULTURE", -1.0)], Types.keyText, Text.equal));
      tests.add(test(
        "Mean categorization",
        ?categorizations.getMeanForQuestion(1),
        Matchers.equals(testOptCategorization(?Utils.fromArray([("IDENTITY", 0.4), ("ECONOMY", 0.1), ("CULTURE", -0.5)], Types.keyText, Text.equal)))
      ));

      suite("Test Categorizations module", tests.toArray());
    };
  };

};