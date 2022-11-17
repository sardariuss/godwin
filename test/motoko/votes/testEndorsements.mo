import Endorsements "../../../src/godwin_backend/votes/endorsements";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from other modules
  type Endorsements = Endorsements.Endorsements;

  let testOptEndorsementsTotal = TestableItems.testOptEndorsementsTotal;
  let testOptEndorsement = TestableItems.testOptEndorsement;

  public class TestEndorsements() = {

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

      let endorsements = Endorsements.empty();

      // Test put/remove
      endorsements.put(principal_0, 0);
      tests.add(test("Get user endorsement", endorsements.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptEndorsement(?#ENDORSE))));
      endorsements.put(principal_0, 0);
      tests.add(test("Get user endorsement", endorsements.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptEndorsement(?#ENDORSE))));
      endorsements.remove(principal_0, 0);
      tests.add(test("Get user endorsement", endorsements.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptEndorsement(null))));
      
      // Test total
      endorsements.put(principal_0, 1);
      endorsements.put(principal_1, 1);
      endorsements.put(principal_2, 1);
      endorsements.put(principal_3, 1);
      endorsements.put(principal_4, 1);
      endorsements.put(principal_5, 1);
      endorsements.put(principal_6, 1);
      endorsements.put(principal_7, 1);
      endorsements.put(principal_8, 1);
      endorsements.put(principal_9, 1);
      tests.add(test("Total endorsements", ?endorsements.getTotalForQuestion(1), Matchers.equals(testOptEndorsementsTotal(?10))));

      suite("Test Endorsements module", tests.toArray());
    };
  };

};