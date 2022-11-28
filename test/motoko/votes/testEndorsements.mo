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
      endorsements.put(principal_0, 0, #UP);
      tests.add(test("Get user endorsement", endorsements.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptEndorsement(?#UP))));
      endorsements.put(principal_0, 0, #UP);
      tests.add(test("Get user endorsement", endorsements.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptEndorsement(?#UP))));
      endorsements.remove(principal_0, 0);
      tests.add(test("Get user endorsement", endorsements.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptEndorsement(null))));
      
      // Test only ups ( 10 VS 0 )
      endorsements.put(principal_0, 1, #UP);
      endorsements.put(principal_1, 1, #UP);
      endorsements.put(principal_2, 1, #UP);
      endorsements.put(principal_3, 1, #UP);
      endorsements.put(principal_4, 1, #UP);
      endorsements.put(principal_5, 1, #UP);
      endorsements.put(principal_6, 1, #UP);
      endorsements.put(principal_7, 1, #UP);
      endorsements.put(principal_8, 1, #UP);
      endorsements.put(principal_9, 1, #UP);
      assert(endorsements.getTotalForQuestion(1) == 10);

      // Test only downs ( 0 VS 10 )
      endorsements.put(principal_0, 1, #DOWN);
      endorsements.put(principal_1, 1, #DOWN);
      endorsements.put(principal_2, 1, #DOWN);
      endorsements.put(principal_3, 1, #DOWN);
      endorsements.put(principal_4, 1, #DOWN);
      endorsements.put(principal_5, 1, #DOWN);
      endorsements.put(principal_6, 1, #DOWN);
      endorsements.put(principal_7, 1, #DOWN);
      endorsements.put(principal_8, 1, #DOWN);
      endorsements.put(principal_9, 1, #DOWN);
      assert(endorsements.getTotalForQuestion(1) == -10);

      // Test as many ups than downs ( 5 VS 5 )
      endorsements.put(principal_0, 1, #UP);
      endorsements.put(principal_1, 1, #UP);
      endorsements.put(principal_2, 1, #UP);
      endorsements.put(principal_3, 1, #UP);
      endorsements.put(principal_4, 1, #UP);
      endorsements.put(principal_5, 1, #DOWN);
      endorsements.put(principal_6, 1, #DOWN);
      endorsements.put(principal_7, 1, #DOWN);
      endorsements.put(principal_8, 1, #DOWN);
      endorsements.put(principal_9, 1, #DOWN);
      assert(endorsements.getTotalForQuestion(1) == 0);

      // Test almost only ups ( 9 VS 1 )
      endorsements.put(principal_0, 1, #UP);
      endorsements.put(principal_1, 1, #UP);
      endorsements.put(principal_2, 1, #UP);
      endorsements.put(principal_3, 1, #UP);
      endorsements.put(principal_4, 1, #UP);
      endorsements.put(principal_5, 1, #UP);
      endorsements.put(principal_6, 1, #UP);
      endorsements.put(principal_7, 1, #UP);
      endorsements.put(principal_8, 1, #UP);
      endorsements.put(principal_9, 1, #DOWN);
      assert(endorsements.getTotalForQuestion(1) == 9); // down votes have no effect

      // Test slight majority of ups ( 4 VS 3 )
      endorsements.put(principal_0, 1, #UP);
      endorsements.put(principal_1, 1, #UP);
      endorsements.put(principal_2, 1, #UP);
      endorsements.put(principal_3, 1, #UP);
      endorsements.put(principal_4, 1, #DOWN);
      endorsements.put(principal_5, 1, #DOWN);
      endorsements.put(principal_6, 1, #DOWN);
      endorsements.remove(principal_7, 1);
      endorsements.remove(principal_8, 1);
      endorsements.remove(principal_9, 1);
      assert(endorsements.getTotalForQuestion(1) == 3); // down votes have a slight effect

      suite("Test Endorsements module", tests.toArray());
    };
  };

};