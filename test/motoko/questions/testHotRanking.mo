import Types "../../../src/godwin_backend/types";
import Queries "../../../src/godwin_backend/questions/queries";
import Question "../../../src/godwin_backend/questions/question";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";

module {

  public class TestHotRanking() = {

    // For convenience: from base module
    type Principal = Principal.Principal;
    // For convenience: from matchers module
    let { run;test;suite; } = Suite;
    // For convenience: from types module
    type Question = Types.Question;
    // For convenience: from queries module
    type QuestionRBTs = Queries.QuestionRBTs;
    let testQuery = TestableItems.testQueryQuestionsResult;

    let principal_0 = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe");
    let principal_1 = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae");
    let principal_2 = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe");
    let principal_3 = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe");
    let principal_4 = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae");

    let question_0 =        Question.createQuestion(0, principal_0, 10000, "title", "text", []);
    let question_0_update = Question.updateDate(Question.updateInterestAggregate(question_0, { ups = 0; downs = 0; score = 45;   }), 0);
    let question_1 =        Question.createQuestion(1, principal_1, 8000,  "title", "text", []);
    let question_1_update = Question.updateDate(Question.updateInterestAggregate(question_1, { ups = 0; downs = 0; score = 90;   }), 0);
    let question_2 =        Question.createQuestion(2, principal_2, 6000,  "title", "text", []);
    let question_2_update = Question.updateDate(Question.updateInterestAggregate(question_2, { ups = 0; downs = 0; score = 250;  }), 0);
    let question_3 =        Question.createQuestion(3, principal_3, 4000,  "title", "text", []);
    let question_3_update = Question.updateDate(Question.updateInterestAggregate(question_3, { ups = 0; downs = 0; score = 720;  }), 0);
    let question_4 =        Question.createQuestion(4, principal_4, 2000,  "title", "text", []);
    let question_4_update = Question.updateDate(Question.updateInterestAggregate(question_4, { ups = 0; downs = 0; score = 1000; }), 0);

    public func getSuite() : Suite.Suite {
      let tests = Buffer.Buffer<Suite.Suite>(0);

      var rbts = Queries.init();
      rbts := Queries.addOrderBy(rbts, #CREATION_HOT);
      
      // Add questions
      rbts := Queries.add(rbts, question_0);
      rbts := Queries.add(rbts, question_1);
      rbts := Queries.add(rbts, question_2);
      rbts := Queries.add(rbts, question_3);
      rbts := Queries.add(rbts, question_4);
      tests.add(test("Query by #CREATION_HOT, interest 0", { ids = [4, 3, 2, 1, 0]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #CREATION_HOT, null, null, #fwd, 10)))));
      
      // Replace questions      
      rbts := Queries.replace(rbts, question_0, question_0_update);
      rbts := Queries.replace(rbts, question_1, question_1_update);
      rbts := Queries.replace(rbts, question_2, question_2_update);
      rbts := Queries.replace(rbts, question_3, question_3_update);
      rbts := Queries.replace(rbts, question_4, question_4_update);
      tests.add(test("Query by #CREATION_HOT, date 0", { ids = [0, 1, 2, 3, 4]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #CREATION_HOT, null, null, #fwd, 10)))));

      // @todo: make a test where date and interest are different both different from 0

      suite("Test Hot ranking", tests.toArray());
    };

  };

};