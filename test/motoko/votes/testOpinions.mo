import Types "../../../src/godwin_backend/types";
import Question "../../../src/godwin_backend/questions/question";
import Iteration "../../../src/godwin_backend/votes/iteration";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from other modules
  type Question = Types.Question;
  type Cursor = Types.Cursor;

  func unwrapOpinion(question: Question, principal: Principal) : ?Cursor {
    Trie.get<Principal, Cursor>(Question.unwrapIteration(question).opinion.ballots, Types.keyPrincipal(principal), Principal.equal);
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

      var question_0 : Question = { 
        id = 0; 
        author = principal_0;
        title = "";
        text = "";
        date = 0;
        status = #OPEN( { stage = #OPINION; iteration = Iteration.new(0); });
        interests_history = [];
        vote_history = []; 
      };

      var question_1 : Question = { 
        id = 1; 
        author = principal_0;
        title = "";
        text = "";
        date = 0;
        status = #OPEN( { stage = #OPINION; iteration = Iteration.new(0); });
        interests_history = [];
        vote_history = []; 
      };

      // Test put/remove
      Result.iterate(Question.putOpinion(question_0, principal_0, 0.0), func(q: Question) { question_0 := q; });
      tests.add(test("Add ballot", unwrapOpinion(question_0, principal_0), Matchers.equals(TestableItems.optCursor(?0.0))));
      Result.iterate(Question.putOpinion(question_0, principal_0, 1.0), func(q: Question) { question_0 := q; });
      tests.add(test("Update ballot", unwrapOpinion(question_0, principal_0), Matchers.equals(TestableItems.optCursor(?1.0))));
      Result.iterate(Question.removeOpinion(question_0, principal_0), func(q: Question) { question_0 := q; });
      tests.add(test("Remove ballot", unwrapOpinion(question_0, principal_0), Matchers.equals(TestableItems.optCursor(null))));
      
      // Test aggregate
      Result.iterate(Question.putOpinion(question_1, principal_0,  1.0), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_1,  0.5), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_2,  0.5), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_3,  0.5), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_4,  0.5), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_5,  0.5), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_6,  0.0), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_7,  0.0), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_8, -1.0), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putOpinion(question_1, principal_9, -1.0), func(q: Question) { question_1 := q; });
      tests.add(test(
        "Opinion aggregate",
        Question.unwrapIteration(question_1).opinion.aggregate,
        Matchers.equals(TestableItems.polarization({left = 2.0; center = 4.5; right = 3.5;}))));

      suite("Test Opinions module", tests.toArray());
    };
  };

};