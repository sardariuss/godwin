import Types "../../../src/godwin_backend/types";
import Users "../../../src/godwin_backend/users";
import Questions "../../../src/godwin_backend/questions/questions";
import Opinions "../../../src/godwin_backend/votes/opinions";
import User "../../../src/godwin_backend/user";
import Categories "../../../src/godwin_backend/categories";
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
      
      let categories = Categories.Categories([]);

      let questions = Questions.empty(categories);
      let question_0 = questions.createQuestion(principal_0, 0, "title0", "text0");
      let question_1 = questions.createQuestion(principal_0, 0, "title1", "text1");

      let users = Users.empty(categories);

      // Test put/remove
      Opinions.put(users, principal_0, questions, question_0.id, 0.0);
      tests.add(test("Add ballot", User.getOpinion(users.getUser(principal_0), question_0.id), Matchers.equals(TestableItems.optCursor(?0.0))));
      Opinions.put(users, principal_0, questions, question_0.id, 1.0);
      tests.add(test("Update ballot", User.getOpinion(users.getUser(principal_0), question_0.id), Matchers.equals(TestableItems.optCursor(?1.0))));
      Opinions.remove(users, principal_0, questions, question_0.id);
      tests.add(test("Remove ballot", User.getOpinion(users.getUser(principal_0), question_0.id), Matchers.equals(TestableItems.optCursor(null))));
      
      // Test aggregate
      Opinions.put(users, principal_0, questions, question_1.id,  1.0);
      Opinions.put(users, principal_1, questions, question_1.id,  0.5);
      Opinions.put(users, principal_2, questions, question_1.id,  0.5);
      Opinions.put(users, principal_3, questions, question_1.id,  0.5);
      Opinions.put(users, principal_4, questions, question_1.id,  0.5);
      Opinions.put(users, principal_5, questions, question_1.id,  0.5);
      Opinions.put(users, principal_6, questions, question_1.id,  0.0);
      Opinions.put(users, principal_7, questions, question_1.id,  0.0);
      Opinions.put(users, principal_8, questions, question_1.id, -1.0);
      Opinions.put(users, principal_9, questions, question_1.id, -1.0);
      tests.add(test(
        "Opinion aggregate",
        questions.getQuestion(question_1.id).aggregates.opinion,
        Matchers.equals(TestableItems.polarization({left = 2.0; center = 4.5; right = 3.5;}))));

      suite("Test Opinions module", tests.toArray());
    };
  };

};