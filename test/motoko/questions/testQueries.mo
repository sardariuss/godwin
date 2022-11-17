import Types "../../../src/godwin_backend/types";
import StageHistory "../../../src/godwin_backend/stageHistory";
import Queries "../../../src/godwin_backend/questions/queries";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";

module {
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

    let question_0 =                           { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Selfishness is the overriding drive in the human species, no matter the context."; text = ""; date = 8493; endorsements = 13; selection_stage = [{ timestamp = 8493; stage = #CREATED;                                              }]; categorization_stage = [{ timestamp = 1283; stage = #PENDING;  }]; };
    let question_0_text_update =               { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Above all is selfishness is the overriding drive in the human species";            text = ""; date = 8493; endorsements = 13; selection_stage = [{ timestamp = 8493; stage = #CREATED;                                              }]; categorization_stage = [{ timestamp = 1283; stage = #PENDING;  }]; };
    let question_1 =                           { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; date = 2432; endorsements = 2;  selection_stage = [{ timestamp = 2432; stage = #ARCHIVED { left = 0.0; center = 10.0; right = 0.0; }; }]; categorization_stage = [{ timestamp = 9372; stage = #ONGOING;  }]; };
    let question_1_date_update =               { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; date = 5123; endorsements = 2;  selection_stage = [{ timestamp = 2432; stage = #ARCHIVED { left = 0.0; center = 10.0; right = 0.0; }; }]; categorization_stage = [{ timestamp = 9372; stage = #ONGOING;  }]; };
    let question_2 =                           { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; date = 3132; endorsements = 43; selection_stage = [{ timestamp = 3132; stage = #SELECTED;                                             }]; categorization_stage = [{ timestamp = 3610; stage = #DONE([]); }]; };
    let question_2_endorsements_update =       { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; date = 3132; endorsements = 9;  selection_stage = [{ timestamp = 3132; stage = #SELECTED;                                             }]; categorization_stage = [{ timestamp = 3610; stage = #DONE([]); }]; };
    let question_3 =                           { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; date = 4213; endorsements = 21; selection_stage = [{ timestamp = 4213; stage = #CREATED;                                              }]; categorization_stage = [{ timestamp = 4721; stage = #PENDING;  }]; };
    let question_3_selection_stage_update =    { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; date = 4213; endorsements = 21; selection_stage = [{ timestamp = 4213; stage = #ARCHIVED { left = 0.0; center = 10.0; right = 0.0; }; }]; categorization_stage = [{ timestamp = 4721; stage = #PENDING;  }]; };
    let question_4 =                           { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; date = 9711; endorsements = 20; selection_stage = [{ timestamp = 9711; stage = #SELECTED;                                             }]; categorization_stage = [{ timestamp = 9473; stage = #DONE([]); }]; };
    let question_4_categorization_update =     { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; date = 9711; endorsements = 20; selection_stage = [{ timestamp = 9711; stage = #SELECTED;                                             }]; categorization_stage = [{ timestamp = 9473; stage = #PENDING;  }]; };

    public func getSuite() : Suite.Suite {
      let tests = Buffer.Buffer<Suite.Suite>(0);

      var rbts = Queries.init();
      rbts := Queries.addOrderBy(rbts, #TITLE);
      rbts := Queries.addOrderBy(rbts, #ENDORSEMENTS);
      rbts := Queries.addOrderBy(rbts, #CREATION_DATE);
      rbts := Queries.addOrderBy(rbts, #SELECTION_STAGE_DATE);
      rbts := Queries.addOrderBy(rbts, #CATEGORIZATION_STAGE_DATE);
      
      // Add questions
      rbts := Queries.add(rbts, question_0);
      rbts := Queries.add(rbts, question_1);
      rbts := Queries.add(rbts, question_2);
      rbts := Queries.add(rbts, question_3);
      rbts := Queries.add(rbts, question_4);
      tests.add(test("Query by #ID",                        { ids = [0, 1, 2, 3, 4]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #ID,                        null, null, #fwd, 10)))));
      tests.add(test("Query by #TITLE",                     { ids = [4, 3, 2];       next_id = ?1;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #TITLE,                     null, null, #fwd, 3 )))));
      tests.add(test("Query by #CREATION_DATE",             { ids = [4, 0, 3, 2];    next_id = ?1;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #CREATION_DATE,             null, null, #bwd, 4 )))));
      tests.add(test("Query by #ENDORSEMENTS",              { ids = [2, 3, 4, 0, 1]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #ENDORSEMENTS,              null, null, #bwd, 5 )))));
      tests.add(test("Query by #SELECTION_STAGE_DATE",      { ids = [3, 0, 2, 4];    next_id = ?1;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #SELECTION_STAGE_DATE,      null, null, #fwd, 4 )))));
      tests.add(test("Query by #CATEGORIZATION_STAGE_DATE", { ids = [0, 3, 1, 2];    next_id = ?4;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #CATEGORIZATION_STAGE_DATE, null, null, #fwd, 4 )))));
      
      // Replace questions      
      var rbts_replaced = Queries.replace(rbts, question_0, question_0_text_update);
      rbts_replaced := Queries.replace(rbts_replaced, question_1, question_1_date_update);
      rbts_replaced := Queries.replace(rbts_replaced, question_2, question_2_endorsements_update);
      rbts_replaced := Queries.replace(rbts_replaced, question_3, question_3_selection_stage_update);
      rbts_replaced := Queries.replace(rbts_replaced, question_4, question_4_categorization_update);
      tests.add(test("Query by #ID (after replace)",                        { ids = [0, 1, 2, 3, 4]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #ID,                        null, null, #fwd, 10)))));
      tests.add(test("Query by #TITLE (after replace)",                     { ids = [0, 4, 3];       next_id = ?2;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #TITLE,                     null, null, #fwd, 3 )))));
      tests.add(test("Query by #CREATION_DATE (after replace)",             { ids = [4, 0, 1, 3];    next_id = ?2;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #CREATION_DATE,             null, null, #bwd, 4 )))));
      tests.add(test("Query by #ENDORSEMENTS (after replace)",              { ids = [3, 4, 0, 2, 1]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #ENDORSEMENTS,              null, null, #bwd, 5 )))));
      tests.add(test("Query by #SELECTION_STAGE_DATE (after replace)",      { ids = [0, 2, 4, 1];    next_id = ?3;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #SELECTION_STAGE_DATE,      null, null, #fwd, 4 )))));
      tests.add(test("Query by #CATEGORIZATION_STAGE_DATE (after replace)", { ids = [0, 3, 4, 1];    next_id = ?2;   }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_replaced, #CATEGORIZATION_STAGE_DATE, null, null, #fwd, 4 )))));
      
      // Remove questions
      var rbts_removed = Queries.remove(rbts, question_0);
      rbts_removed := Queries.remove(rbts_removed, question_1);
      tests.add(test("Query by #ID (after remove)",                        { ids = [2, 3, 4]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #ID,                        null, null, #fwd, 10)))));
      tests.add(test("Query by #TITLE (after remove)",                     { ids = [4, 3, 2]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #TITLE,                     null, null, #fwd, 3 )))));
      tests.add(test("Query by #CREATION_DATE (after remove)",             { ids = [4, 3, 2]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #CREATION_DATE,             null, null, #bwd, 4 )))));
      tests.add(test("Query by #ENDORSEMENTS (after remove)",              { ids = [2, 3, 4]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #ENDORSEMENTS,              null, null, #bwd, 5 )))));
      tests.add(test("Query by #SELECTION_STAGE_DATE (after remove)",      { ids = [3, 2, 4]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #SELECTION_STAGE_DATE,      null, null, #fwd, 4 )))));
      tests.add(test("Query by #CATEGORIZATION_STAGE_DATE (after remove)", { ids = [3, 2, 4]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts_removed, #CATEGORIZATION_STAGE_DATE, null, null, #fwd, 4 )))));

      suite("Test Queries module", tests.toArray());
    };

  };

};