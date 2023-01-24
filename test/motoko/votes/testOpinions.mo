import Types "../../../src/godwin_backend/Types";
import Votes "../../../src/godwin_backend/votes/Votes";
import Polarization "../../../src/godwin_backend/representation/Polarization";
import Opinion "../../../src/godwin_backend/votes/Opinions";
import TestableItems "../testableItems";

import Map "mo:map/Map";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Time = Int;
  type Map<K, V> = Map.Map<K, V>;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from other modules
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type Ballot<T> = Types.Ballot<T>;

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

      let votes = Opinion.build(
        Map.new<Principal, Map<Nat, Map<Nat, Timestamp<Cursor>>>>(),
        Map.new<Nat, Map<Nat, Timestamp<Polarization>>>()
      );

      // Question 0 : arbitrary question_id, iteration and date
      let question_0 : Nat = 0;
      let iteration_0 : Nat = 0;
      let date_0 : Time = 123456789;
      votes.newAggregate(question_0, iteration_0, date_0);

      // Test put/remove
      votes.putBallot(principal_0, question_0, iteration_0, date_0, 0.0);
      tests.add(test(
        "Add ballot",
        votes.getBallot(principal_0, question_0, iteration_0),
        Matchers.equals(TestableItems.optOpinionBallot(?{ elem = 0.0; date = date_0; }))
      ));
      votes.putBallot(principal_0, question_0, iteration_0, date_0, 1.0);
      tests.add(test(
        "Update ballot",
        votes.getBallot(principal_0, question_0, iteration_0),
        Matchers.equals(TestableItems.optOpinionBallot(?{ elem = 1.0; date = date_0; }))
      ));
      votes.removeBallot(principal_0, question_0, iteration_0);
      tests.add(test(
        "Remove ballot",
        votes.getBallot(principal_0, question_0, iteration_0),
        Matchers.equals(TestableItems.optOpinionBallot(null))
      ));

      // Question 1 : arbitrary question_id, iteration and date
      let question_1 : Nat = 1;
      let iteration_1 : Nat = 1;
      let date_1 : Time = 987654321;
      votes.newAggregate(question_1, iteration_1, date_1);
      
      // Test aggregate
      votes.putBallot(principal_0, question_1, iteration_1, date_1,  1.0);
      votes.putBallot(principal_1, question_1, iteration_1, date_1,  0.5);
      votes.putBallot(principal_2, question_1, iteration_1, date_1,  0.5);
      votes.putBallot(principal_3, question_1, iteration_1, date_1,  0.5);
      votes.putBallot(principal_4, question_1, iteration_1, date_1,  0.5);
      votes.putBallot(principal_5, question_1, iteration_1, date_1,  0.5);
      votes.putBallot(principal_6, question_1, iteration_1, date_1,  0.0);
      votes.putBallot(principal_7, question_1, iteration_1, date_1,  0.0);
      votes.putBallot(principal_8, question_1, iteration_1, date_1, -1.0);
      votes.putBallot(principal_9, question_1, iteration_1, date_1, -1.0);
      tests.add(test(
        "Opinion aggregate",
        votes.getAggregate(question_1, iteration_1),
        Matchers.equals(TestableItems.optOpinionAggregate(?{ date = date_1; elem = {left = 2.0; center = 4.5; right = 3.5;} }))));

      suite("Test Opinions module", Buffer.toArray(tests));
    };
  };

};