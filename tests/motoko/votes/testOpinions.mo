import Types "../../../src/godwin_backend/types";
import Opinions "../../../src/godwin_backend/votes/opinions";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types modules
  type Opinion = Types.Opinion;
  // For convenience: from other modules
  type Opinions = Opinions.Opinions;

  func testOptItem<T>(item: ?T, to_text: T -> Text, equal: (T, T) -> Bool) : Testable.TestableItem<?T> {
    {
      display = func(item: ?T) : Text {
        switch(item){
          case(null) { "(null)"; };
          case(?item) { to_text(item); };
        };
      };
      equals = func (q1: ?T, q2: ?T) : Bool {
        switch(q1){
          case(null) {
            switch(q2){
              case(null) { true; };
              case(_) { false; };
            };
          };
          case(?item1) {
            switch(q2){
              case(null) { false; };
              case(?item2) { equal(item1, item2); };
            };
          };
        };
      };
      item = item;
    }
  };

  func toTextOpinion(opinion: Opinion) : Text {
    switch(opinion){
      case(#AGREE(conviction)){
        switch(conviction){
          case(#ABSOLUTE){"ABS_AGREE";};
          case(#MODERATE){"MOD_AGREE";};
        };
      };
      case(#NEUTRAL){"NEUTRAL";};
      case(#DISAGREE(conviction)){
        switch(conviction){
          case(#ABSOLUTE){"ABS_DISAGREE";};
          case(#MODERATE){"MOD_DISAGREE";};
        };
      };
    };
  };

  func equalOpinions(opinion1: Opinion, opinion2: Opinion) : Bool {
    Text.equal(toTextOpinion(opinion1), toTextOpinion(opinion2));
  };

  func testOptOpinion(opinion: ?Opinion) : Testable.TestableItem<?Opinion> {
    testOptItem(opinion, toTextOpinion, equalOpinions);
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
      opinions.put(principal_0, 0, #NEUTRAL);
      tests.add(test("Get user opinion", opinions.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptOpinion(?#NEUTRAL))));
      opinions.put(principal_0, 0, #DISAGREE(#MODERATE));
      tests.add(test("Get user opinion", opinions.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptOpinion(?#DISAGREE(#MODERATE)))));
      opinions.remove(principal_0, 0);
      tests.add(test("Get user opinion", opinions.getForUserAndQuestion(principal_0, 0), Matchers.equals(testOptOpinion(null))));
      
      // @todo: continue test
      
      suite("Test Opinions module", tests.toArray());
    };
  };

};