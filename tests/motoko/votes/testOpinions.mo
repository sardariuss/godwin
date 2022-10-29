import Types "../../../src/godwin_backend/types";
import Opinions "../../../src/godwin_backend/votes/opinions";
import TestableItemExtension "../testableItemExtension";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types modules
  type Opinion = Types.Opinion;
  type OpinionsTotal = Types.OpinionsTotal;
  // For convenience: from other modules
  type Opinions = Opinions.Opinions;

  func toTextOpinion(opinion: Opinion) : Text {
    Float.toText(opinion);
  };

  func equalOpinions(opinion1: Opinion, opinion2: Opinion) : Bool {
    Float.equal(opinion1, opinion2);
  };

  func testOptOpinion(opinion: ?Opinion) : Testable.TestableItem<?Opinion> {
    TestableItemExtension.testOptItem(opinion, toTextOpinion, equalOpinions);
  };

  func toTextOpinionsTotal(total: OpinionsTotal) : Text {
    "cursor=" # Float.toText(total.cursor) # 
    ", confidence=" # Float.toText(total.confidence) # 
    ", total=" # Nat.toText(total.total);
  };

  func equalOpinionsTotal(t1: OpinionsTotal, t2: OpinionsTotal) : Bool {
    t1.cursor == t2.cursor and t1.confidence == t2.confidence and t1.total == t2.total;
  };

  func testOpinionsTotal(total: OpinionsTotal) : Testable.TestableItem<OpinionsTotal> {
    {
      display = toTextOpinionsTotal;
      equals = equalOpinionsTotal;
      item = total;
    };
  };

  public class TestOpinions() = {

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

      let opinions = Opinions.empty();

      // Test put/remove
      opinions.put(principal_0, 0, 0.0);
      tests.add(test("Get user opinion", opinions.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptOpinion(?0.0))));
      opinions.put(principal_0, 0, 1.0);
      tests.add(test("Get user opinion", opinions.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptOpinion(?1.0))));
      opinions.remove(principal_0, 0);
      tests.add(test("Get user opinion", opinions.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptOpinion(null))));
      
      // Test total
      opinions.put(principal_0, 1,  1.0);
      opinions.put(principal_1, 1,  0.5);
      opinions.put(principal_2, 1,  0.5);
      opinions.put(principal_3, 1,  0.5);
      opinions.put(principal_4, 1,  0.5);
      opinions.put(principal_5, 1,  0.5);
      opinions.put(principal_6, 1,  0.0);
      opinions.put(principal_7, 1,  0.0);
      opinions.put(principal_8, 1, -1.0);
      opinions.put(principal_9, 1, -1.0);
      tests.add(test(
        "Total opinions",
        opinions.getTotalForQuestion(1),
        Matchers.equals(testOpinionsTotal({ cursor = 1.5; confidence = 5.5; total = 10; }))));

      suite("Test Opinions module", tests.toArray());
    };
  };

};