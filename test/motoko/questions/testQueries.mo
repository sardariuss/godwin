import Types "../../../src/godwin_backend/types";
import Polarization "../../../src/godwin_backend/representation/polarization";
import Iteration "../../../src/godwin_backend/votes/iteration";

import Queries "../../../src/godwin_backend/questions/queries";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";


module {
  
  type Interest = Types.Interest;
  type Polarization = Types.Polarization;

  // @todo: add tests on lower and upper bounds for the queryQuestions function
  // @todo: add tests on entries and entriesRev functions
  public class TestQueries() = {

    // For convenience: from base module
    type Principal = Principal.Principal;
    // For convenience: from matchers module
    let { run;test;suite; } = Suite;
    // For convenience: from types module
    type Question = Types.Question;
    // For convenience: from queries module
    type QuestionRBTs = Queries.QuestionRBTs;
    
    let testQuery = TestableItems.testQueryQuestionsResult;

    let question_0 :                        Question = { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Selfishness is the overriding drive in the human species, no matter the context."; text = ""; date = 8493; status = #CANDIDATE({ date = 8493; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 13; }}); interests_history = []; vote_history = []; };
    let question_0_text_update :            Question = { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Above all is selfishness is the overriding drive in the human species";            text = ""; date = 8493; status = #CANDIDATE({ date = 8493; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 13; }}); interests_history = []; vote_history = []; };
    let question_1 :                        Question = { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; date = 2432; status = #OPEN({ stage = #CATEGORIZATION; iteration = Iteration.new(0, 2432) });                                                   interests_history = []; vote_history = []; };
    let question_1_date_update :            Question = { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; date = 5123; status = #OPEN({ stage = #CATEGORIZATION; iteration = Iteration.new(0, 2432) });                                                   interests_history = []; vote_history = []; };
    let question_2 :                        Question = { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; date = 3132; status = #OPEN({ stage = #OPINION; iteration = Iteration.new(3132, 0); });                                                         interests_history = []; vote_history = []; };
    let question_2_interests_update :       Question = { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; date = 3132; status = #OPEN({ stage = #OPINION; iteration = Iteration.new(3132, 0); });                                                         interests_history = []; vote_history = []; };
    let question_3 :                        Question = { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; date = 4213; status = #CANDIDATE({ date = 4213; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 21; }}); interests_history = []; vote_history = []; };
    let question_3_selection_stage_update : Question = { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; date = 4213; status = #OPEN({ stage = #CATEGORIZATION; iteration = Iteration.new(0, 4213) });                                                   interests_history = []; vote_history = []; };
    let question_4 :                        Question = { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; date = 9711; status = #OPEN({ stage = #OPINION; iteration = Iteration.new(9711, 0); });                                                         interests_history = []; vote_history = []; };
    let question_4_categorization_update :  Question = { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; date = 9711; status = #OPEN({ stage = #OPINION; iteration = Iteration.new(9711, 0); });                                                         interests_history = []; vote_history = []; };

    public func getSuite() : Suite.Suite {
      let tests = Buffer.Buffer<Suite.Suite>(0);

      var rbts = Queries.init();
      rbts := Queries.addOrderBy(rbts, #TITLE);
      rbts := Queries.addOrderBy(rbts, #CREATION_DATE);
      rbts := Queries.addOrderBy(rbts, #INTEREST);
      rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#OPEN(#OPINION)));
      rbts := Queries.addOrderBy(rbts, #STATUS_DATE(#OPEN(#CATEGORIZATION)));

      // Add questions
      rbts := Queries.add(rbts, question_0);
      rbts := Queries.add(rbts, question_1);
      rbts := Queries.add(rbts, question_2);
      rbts := Queries.add(rbts, question_3);
      rbts := Queries.add(rbts, question_4);
      tests.add(test("Query by #TITLE",                               { ids : [Nat32] = [4, 3, 2];       next_id : ?Nat32 = ?1;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #TITLE,                                null, null, #fwd, 3 )))));
      tests.add(test("Query by #CREATION_DATE",                       { ids : [Nat32] = [4, 0, 3, 2];    next_id : ?Nat32 = ?1;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #CREATION_DATE,                        null, null, #bwd, 4 )))));
      tests.add(test("Query by #INTEREST",                            { ids : [Nat32] = [3, 0];          next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #INTEREST,                             null, null, #bwd, 5 )))));
      tests.add(test("Query by #STATUS_DATE(#OPEN(#OPINION))",        { ids : [Nat32] = [2, 4];          next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #STATUS_DATE(#OPEN(#OPINION)),         null, null, #fwd, 5 )))));
      tests.add(test("Query by #STATUS_DATE(#OPEN(#CATEGORIZATION))", { ids : [Nat32] = [1];             next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #STATUS_DATE(#OPEN(#CATEGORIZATION)),  null, null, #fwd, 5 )))));
      
      // Replace questions
      var rbts_replaced = Queries.replace(rbts, question_0, question_0_text_update);
      rbts_replaced := Queries.replace(rbts_replaced, question_1, question_1_date_update);
      rbts_replaced := Queries.replace(rbts_replaced, question_2, question_2_interests_update);
      rbts_replaced := Queries.replace(rbts_replaced, question_3, question_3_selection_stage_update);
      rbts_replaced := Queries.replace(rbts_replaced, question_4, question_4_categorization_update);
      tests.add(test("Query by #TITLE (after replace)",                               { ids : [Nat32] = [0, 4, 3];    next_id : ?Nat32 = ?2;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #TITLE,                               null, null, #fwd, 3 )))));
      tests.add(test("Query by #CREATION_DATE (after replace)",                       { ids : [Nat32] = [4, 0, 1, 3]; next_id : ?Nat32 = ?2;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #CREATION_DATE,                       null, null, #bwd, 4 )))));
      tests.add(test("Query by #INTEREST (after replace)",                            { ids : [Nat32] = [0];          next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #INTEREST,                            null, null, #bwd, 5 )))));
      tests.add(test("Query by #STATUS_DATE(#OPEN(#OPINION)) (after replace)",        { ids : [Nat32] = [2, 4];       next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #STATUS_DATE(#OPEN(#OPINION)),        null, null, #fwd, 5 )))));
      tests.add(test("Query by #STATUS_DATE(#OPEN(#CATEGORIZATION)) (after replace)", { ids : [Nat32] = [1, 3];       next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #STATUS_DATE(#OPEN(#CATEGORIZATION)), null, null, #fwd, 5 )))));

      // Remove questions
      var rbts_removed = Queries.remove(rbts, question_0);
      rbts_removed := Queries.remove(rbts_removed, question_1);
      tests.add(test("Query by #TITLE (after remove)",                               { ids : [Nat32] = [4, 3, 2]; next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #TITLE,                               null, null, #fwd, 3 )))));
      tests.add(test("Query by #CREATION_DATE (after remove)",                       { ids : [Nat32] = [4, 3, 2]; next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #CREATION_DATE,                       null, null, #bwd, 4 )))));
      tests.add(test("Query by #INTEREST (after remove)",                            { ids : [Nat32] = [3];       next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #INTEREST,                            null, null, #bwd, 5 )))));
      tests.add(test("Query by #STATUS_DATE(#OPEN(#OPINION)) (after remove)",        { ids : [Nat32] = [2, 4];    next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #STATUS_DATE(#OPEN(#OPINION)),        null, null, #fwd, 4 )))));
      tests.add(test("Query by #STATUS_DATE(#OPEN(#CATEGORIZATION)) (after remove)", { ids : [Nat32] = [];        next_id : ?Nat32 = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #STATUS_DATE(#OPEN(#CATEGORIZATION)), null, null, #fwd, 4 )))));

      suite("Test Queries module", tests.toArray());
    };

  };

};