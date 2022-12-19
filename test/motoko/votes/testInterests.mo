import Types "../../../src/godwin_backend/types";
import Interests "../../../src/godwin_backend/votes/interests";
import Question "../../../src/godwin_backend/questions/question";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import Result "mo:base/Result";


module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from other modules
  type Interest = Types.Interest;
  type Question = Types.Question;

  let testOptInterestAggregate = TestableItems.testOptInterestAggregate;
  let testOptInterest = TestableItems.testOptInterest;

  func unwrapBallot(question: Question, principal: Principal) : ?Interest {
    Trie.get<Principal, Interest>(Question.unwrapInterest(question).ballots, Types.keyPrincipal(principal), Principal.equal);
  };

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

      var question_0 : Question = { 
        id = 0;
        author = principal_0;
        title = "";
        text = "";
        date = 0;
        status = #CANDIDATE({ date = 0; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; });
        interests_history = [];
        vote_history = [];
      };

      var question_1 : Question = { 
        id = 1;
        author = principal_0;
        title = "";
        text = "";
        date = 0;
        status = #CANDIDATE({ date = 0; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; });
        interests_history = [];
        vote_history = [];
      };

      // Test put/remove
      Result.iterate(Question.putInterest(question_0, principal_0, #UP), func(q: Question) { question_0 := q; });
      tests.add(test("Get user interest", unwrapBallot(question_0, principal_0), Matchers.equals(testOptInterest(?#UP))));
      Result.iterate(Question.putInterest(question_0, principal_0, #DOWN), func(q: Question) { question_0 := q; });
      tests.add(test("Get user interest", unwrapBallot(question_0, principal_0), Matchers.equals(testOptInterest(?#DOWN))));
      Result.iterate(Question.removeInterest(question_0, principal_0), func(q: Question) { question_0 := q; });
      tests.add(test("Get user interest", unwrapBallot(question_0, principal_0), Matchers.equals(testOptInterest(null))));

      // Test only ups ( 10 VS 0 )
      Result.iterate(Question.putInterest(question_1, principal_0, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_1, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_2, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_3, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_4, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_5, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_6, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_7, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_8, #UP), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_9, #UP), func(q: Question) { question_1 := q; });
      assert(Question.unwrapInterest(question_1).aggregate == { ups = 10; downs = 0; score = 10; });

      // Test only downs ( 0 VS 10 )
      Result.iterate(Question.putInterest(question_1, principal_0, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_1, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_2, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_3, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_4, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_5, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_6, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_7, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_8, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_9, #DOWN), func(q: Question) { question_1 := q; });
      assert(Question.unwrapInterest(question_1).aggregate == { ups = 0; downs = 10; score = -10; });

      // Test as many ups than downs ( 5 VS 5 )
      Result.iterate(Question.putInterest(question_1, principal_0, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_1, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_2, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_3, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_4, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_5, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_6, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_7, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_8, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_9, #DOWN), func(q: Question) { question_1 := q; });
      assert(Question.unwrapInterest(question_1).aggregate == { ups = 5; downs = 5; score = 0; });

      // Test almost only ups ( 9 VS 1 )
      Result.iterate(Question.putInterest(question_1, principal_0, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_1, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_2, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_3, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_4, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_5, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_6, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_7, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_8, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_9, #DOWN), func(q: Question) { question_1 := q; });
      assert(Question.unwrapInterest(question_1).aggregate == { ups = 9; downs = 1; score = 9; }); // down votes have no effect

      // Test slight majority of ups ( 4 VS 3 )
      Result.iterate(Question.putInterest(question_1, principal_0, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_1, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_2, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_3, #UP),   func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_4, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_5, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.putInterest(question_1, principal_6, #DOWN), func(q: Question) { question_1 := q; });
      Result.iterate(Question.removeInterest(question_1, principal_7),     func(q: Question) { question_1 := q; });
      Result.iterate(Question.removeInterest(question_1, principal_8),     func(q: Question) { question_1 := q; });
      Result.iterate(Question.removeInterest(question_1, principal_9),     func(q: Question) { question_1 := q; });
      assert(Question.unwrapInterest(question_1).aggregate == { ups = 4; downs = 3; score = 3; }); // down votes have a slight effect

      suite("Test Interests module", tests.toArray());
    };
  };

};