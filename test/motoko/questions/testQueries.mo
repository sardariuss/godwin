import Types "../../../src/godwin_backend/model/Types";
import Polarization "../../../src/godwin_backend/model/votes/representation/Polarization";
import Queries "../../../src/godwin_backend/model/QuestionQueries";

import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";

module {
  
  type Polarization = Types.Polarization;
  type Trie<K, V> = Trie.Trie<K, V>;

  // @todo: add tests on lower and upper bounds for the queryQuestions function
  // @todo: add tests on entries and entriesRev functions
  public class TestQueries() = {

    // For convenience: from base module
    type Principal = Principal.Principal;
    // For convenience: from matchers module
    let { run;test;suite; } = Suite;
    // For convenience: from types module
    type Question = Types.Question;
    
    let testScanResult = TestableItems.testScanLimitResult;

    let question_0 :                        Question = { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Selfishness is the overriding drive in the human species, no matter the context."; text = ""; date = 8493; status = #INTEREST({ date = 8493; ballots = Trie.empty<Principal, Cursor>(); aggregate = { ups = 0; downs = 0; score = 13; }}); interests_history = []; vote_history = []; };
    let question_0_text_update :            Question = { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Above all is selfishness is the overriding drive in the human species";            text = ""; date = 8493; status = #INTEREST({ date = 8493; ballots = Trie.empty<Principal, Cursor>(); aggregate = { ups = 0; downs = 0; score = 13; }}); interests_history = []; vote_history = []; };
    let question_1 :                        Question = { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; date = 2432; status = #VOTING({ stage = #CATEGORIZATION; iteration = Iteration.openCategorization(Iteration.new(0), 2432, []) });                 interests_history = []; vote_history = []; };
    let question_1_date_update :            Question = { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; date = 5123; status = #VOTING({ stage = #CATEGORIZATION; iteration = Iteration.openCategorization(Iteration.new(0), 2432, []) });                 interests_history = []; vote_history = []; };
    let question_2 :                        Question = { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; date = 3132; status = #VOTING({ stage = #OPINION; iteration = Iteration.new(3132); });                                                            interests_history = []; vote_history = []; };
    let question_2_interests_update :       Question = { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; date = 3132; status = #VOTING({ stage = #OPINION; iteration = Iteration.new(3132); });                                                            interests_history = []; vote_history = []; };
    let question_3 :                        Question = { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; date = 4213; status = #INTEREST({ date = 4213; ballots = Trie.empty<Principal, Cursor>(); aggregate = { ups = 0; downs = 0; score = 21; }}); interests_history = []; vote_history = []; };
    let question_3_selection_stage_update : Question = { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; date = 4213; status = #VOTING({ stage = #CATEGORIZATION; iteration = Iteration.openCategorization(Iteration.new(0), 4213, []) });                 interests_history = []; vote_history = []; };
    let question_4 :                        Question = { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; date = 9711; status = #VOTING({ stage = #OPINION; iteration = Iteration.new(9711); });                                                            interests_history = []; vote_history = []; };
    let question_4_categorization_update :  Question = { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; date = 9711; status = #VOTING({ stage = #OPINION; iteration = Iteration.new(9711); });                                                            interests_history = []; vote_history = []; };

    public func getSuite() : Suite.Suite {
      let tests = Buffer.Buffer<Suite.Suite>(0);

      let queries = Queries.build(Queries.initRegister());

      // Add questions
      queries.add(question_0);
      queries.add(question_1);
      queries.add(question_2);
      queries.add(question_3);
      queries.add(question_4);
      tests.add(test("Query by #TITLE",                               { ids = [4, 3]; next_id = ?2;   }, Matchers.equals(testScanResult(queries.queryQuestions(#TITLE,                                null,                                        null,                                                #fwd, 2 )))));
      tests.add(test("Query by #TITLE",                               { ids = [2, 1]; next_id = ?0;   }, Matchers.equals(testScanResult(queries.queryQuestions(#TITLE,                                Queries.initQuestionKey(question_2, #TITLE), null,                                                #fwd, 2 )))));
      tests.add(test("Query by #CREATION_DATE",                       { ids = [4, 0]; next_id = ?3;   }, Matchers.equals(testScanResult(queries.queryQuestions(#CREATION_DATE,                        null,                                        null,                                                #bwd, 2 )))));
      tests.add(test("Query by #CREATION_DATE",                       { ids = [3, 2]; next_id = ?1;   }, Matchers.equals(testScanResult(queries.queryQuestions(#CREATION_DATE,                        null,                                        Queries.initQuestionKey(question_3, #CREATION_DATE), #bwd, 2 )))));
      tests.add(test("Query by #INTEREST",                            { ids = [3, 0]; next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#INTEREST,                             null,                                        null,                                                #bwd, 5 )))));
      tests.add(test("Query by #STATUS(#OPEN)",        { ids = [2, 4]; next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#STATUS(#OPEN),         null,                                        null,                                                #fwd, 5 )))));
      tests.add(test("Query by #STATUS(#VOTING(#CATEGORIZATION))", { ids = [1];    next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#STATUS(#VOTING(#CATEGORIZATION)),  null,                                        null,                                                #fwd, 5 )))));
      
      // Replace questions
      queries.replace(question_0, question_0_text_update);
      queries.replace(question_1, question_1_date_update);
      queries.replace(question_2, question_2_interests_update);
      queries.replace(question_3, question_3_selection_stage_update);
      queries.replace(question_4, question_4_categorization_update);
      tests.add(test("Query by #TITLE (after replace)",                               { ids = [0, 4, 3];    next_id = ?2;   }, Matchers.equals(testScanResult(queries.queryQuestions(#TITLE,                               null, null, #fwd, 3 )))));
      tests.add(test("Query by #CREATION_DATE (after replace)",                       { ids = [4, 0, 1, 3]; next_id = ?2;   }, Matchers.equals(testScanResult(queries.queryQuestions(#CREATION_DATE,                       null, null, #bwd, 4 )))));
      tests.add(test("Query by #INTEREST (after replace)",                            { ids = [0];          next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#INTEREST,                            null, null, #bwd, 5 )))));
      tests.add(test("Query by #STATUS(#OPEN) (after replace)",        { ids = [2, 4];       next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#STATUS(#OPEN),        null, null, #fwd, 5 )))));
      tests.add(test("Query by #STATUS(#VOTING(#CATEGORIZATION)) (after replace)", { ids = [1, 3];       next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#STATUS(#VOTING(#CATEGORIZATION)), null, null, #fwd, 5 )))));

      // Remove questions
      queries.remove(question_0_text_update);
      queries.remove(question_1_date_update);
      tests.add(test("Query by #TITLE (after remove)",                               { ids = [4, 3, 2]; next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#TITLE,                               null, null, #fwd, 3 )))));
      tests.add(test("Query by #CREATION_DATE (after remove)",                       { ids = [4, 3, 2]; next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#CREATION_DATE,                       null, null, #bwd, 4 )))));
      tests.add(test("Query by #INTEREST (after remove)",                            { ids = [];        next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#INTEREST,                            null, null, #bwd, 5 )))));
      tests.add(test("Query by #STATUS(#OPEN) (after remove)",        { ids = [2, 4];    next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#STATUS(#OPEN),        null, null, #fwd, 4 )))));
      tests.add(test("Query by #STATUS(#VOTING(#CATEGORIZATION)) (after remove)", { ids = [3];       next_id = null; }, Matchers.equals(testScanResult(queries.queryQuestions(#STATUS(#VOTING(#CATEGORIZATION)), null, null, #fwd, 4 )))));

      suite("Test Queries module", Buffer.toArray(tests));
    };

  };

};