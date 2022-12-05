import Interests "../../../src/godwin_backend/votes/interests";
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
  type Interests = Interests.Interests;

  let testOptInterestAggregate = TestableItems.testOptInterestAggregate;
  let testOptInterest = TestableItems.testOptInterest;

  public class TestInterests() = {

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

      let interests = Interests.empty();

      // Test put/remove
      interests.put(principal_0, 0, #UP);
      tests.add(test("Get user interest", interests.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptInterest(?#UP))));
      interests.put(principal_0, 0, #UP);
      tests.add(test("Get user interest", interests.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptInterest(?#UP))));
      interests.remove(principal_0, 0);
      tests.add(test("Get user interest", interests.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptInterest(null))));
      
      // Test only ups ( 10 VS 0 )
      interests.put(principal_0, 1, #UP);
      interests.put(principal_1, 1, #UP);
      interests.put(principal_2, 1, #UP);
      interests.put(principal_3, 1, #UP);
      interests.put(principal_4, 1, #UP);
      interests.put(principal_5, 1, #UP);
      interests.put(principal_6, 1, #UP);
      interests.put(principal_7, 1, #UP);
      interests.put(principal_8, 1, #UP);
      interests.put(principal_9, 1, #UP);
      assert(interests.getAggregate(1) == { ups = 10; downs = 0; score = 10; });

      // Test only downs ( 0 VS 10 )
      interests.put(principal_0, 1, #DOWN);
      interests.put(principal_1, 1, #DOWN);
      interests.put(principal_2, 1, #DOWN);
      interests.put(principal_3, 1, #DOWN);
      interests.put(principal_4, 1, #DOWN);
      interests.put(principal_5, 1, #DOWN);
      interests.put(principal_6, 1, #DOWN);
      interests.put(principal_7, 1, #DOWN);
      interests.put(principal_8, 1, #DOWN);
      interests.put(principal_9, 1, #DOWN);
      assert(interests.getAggregate(1) == { ups = 0; downs = 10; score = -10; });

      // Test as many ups than downs ( 5 VS 5 )
      interests.put(principal_0, 1, #UP);
      interests.put(principal_1, 1, #UP);
      interests.put(principal_2, 1, #UP);
      interests.put(principal_3, 1, #UP);
      interests.put(principal_4, 1, #UP);
      interests.put(principal_5, 1, #DOWN);
      interests.put(principal_6, 1, #DOWN);
      interests.put(principal_7, 1, #DOWN);
      interests.put(principal_8, 1, #DOWN);
      interests.put(principal_9, 1, #DOWN);
      assert(interests.getAggregate(1) == { ups = 5; downs = 5; score = 0; });

      // Test almost only ups ( 9 VS 1 )
      interests.put(principal_0, 1, #UP);
      interests.put(principal_1, 1, #UP);
      interests.put(principal_2, 1, #UP);
      interests.put(principal_3, 1, #UP);
      interests.put(principal_4, 1, #UP);
      interests.put(principal_5, 1, #UP);
      interests.put(principal_6, 1, #UP);
      interests.put(principal_7, 1, #UP);
      interests.put(principal_8, 1, #UP);
      interests.put(principal_9, 1, #DOWN);
      assert(interests.getAggregate(1) == { ups = 9; downs = 1; score = 9; }); // down votes have no effect

      // Test slight majority of ups ( 4 VS 3 )
      interests.put(principal_0, 1, #UP);
      interests.put(principal_1, 1, #UP);
      interests.put(principal_2, 1, #UP);
      interests.put(principal_3, 1, #UP);
      interests.put(principal_4, 1, #DOWN);
      interests.put(principal_5, 1, #DOWN);
      interests.put(principal_6, 1, #DOWN);
      interests.remove(principal_7, 1);
      interests.remove(principal_8, 1);
      interests.remove(principal_9, 1);
      assert(interests.getAggregate(1) == { ups = 4; downs = 3; score = 3; }); // down votes have a slight effect

      suite("Test Interests module", tests.toArray());
    };
  };

};