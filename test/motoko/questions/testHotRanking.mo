import Types "../../../src/godwin_backend/types";
import Queries "../../../src/godwin_backend/questions/queries";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Map "mo:map/Map";
import RBT "mo:stableRBT/StableRBTree";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";

module {

  public class TestHotRanking() = {

    // For convenience: from base module
    type Principal = Principal.Principal;
    type Trie<K, V> = Trie.Trie<K, V>;
    // For convenience: from matchers module
    let { run;test;suite; } = Suite;
    // For convenience: from types module
    type Question = Types.Question;
    type Interest = Types.Interest;
    // For convenience: from queries module
    let testQuery = TestableItems.testQueryQuestionsResult;

    let question_0 :        Question = { id = 0; status = #CANDIDATE({ date = 10000; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0;    }}); date = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Selfishness is the overriding drive in the human species, no matter the context."; text = ""; interests_history = []; vote_history = []; };
    let question_0_update : Question = { id = 0; status = #CANDIDATE({ date = 0    ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 45;   }}); date = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Above all is selfishness is the overriding drive in the human species";            text = ""; interests_history = []; vote_history = []; };
    let question_1 :        Question = { id = 1; status = #CANDIDATE({ date = 8000 ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0;    }}); date = 0; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; interests_history = []; vote_history = []; };
    let question_1_update : Question = { id = 1; status = #CANDIDATE({ date = 0    ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 90;   }}); date = 0; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; interests_history = []; vote_history = []; };
    let question_2 :        Question = { id = 2; status = #CANDIDATE({ date = 6000 ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0;    }}); date = 0; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; interests_history = []; vote_history = []; };
    let question_2_update : Question = { id = 2; status = #CANDIDATE({ date = 0    ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 250;  }}); date = 0; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; interests_history = []; vote_history = []; };
    let question_3 :        Question = { id = 3; status = #CANDIDATE({ date = 4000 ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0;    }}); date = 0; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; interests_history = []; vote_history = []; };
    let question_3_update : Question = { id = 3; status = #CANDIDATE({ date = 0    ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 720;  }}); date = 0; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; interests_history = []; vote_history = []; };
    let question_4 :        Question = { id = 4; status = #CANDIDATE({ date = 2000 ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0;    }}); date = 0; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; interests_history = []; vote_history = []; };
    let question_4_update : Question = { id = 4; status = #CANDIDATE({ date = 0    ; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 1000; }}); date = 0; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; interests_history = []; vote_history = []; };

    public func getSuite() : Suite.Suite {
      let tests = Buffer.Buffer<Suite.Suite>(0);

      let register = Map.new<Queries.OrderBy, RBT.Tree<Queries.QuestionKey, ()>>();
      Queries.addOrderBy(register, #INTEREST_HOT);

      let queries = Queries.build(register);
      
      // Add questions
      queries.add(question_0);
      queries.add(question_1);
      queries.add(question_2);
      queries.add(question_3);
      queries.add(question_4);
      tests.add(test("Query by #INTEREST_HOT, interest 0", { ids = [4, 3, 2, 1, 0]; next_id = null; }, Matchers.equals(testQuery(queries.queryQuestions(#INTEREST_HOT, null, null, #fwd, 10)))));
      
      // Replace questions      
      queries.replace(question_0, question_0_update);
      queries.replace(question_1, question_1_update);
      queries.replace(question_2, question_2_update);
      queries.replace(question_3, question_3_update);
      queries.replace(question_4, question_4_update);
      tests.add(test("Query by #INTEREST_HOT, date 0", { ids = [0, 1, 2, 3, 4]; next_id = null; }, Matchers.equals(testQuery(queries.queryQuestions(#INTEREST_HOT, null, null, #fwd, 10)))));

      suite("Test Hot ranking", Buffer.toArray(tests));
    };

  };

};