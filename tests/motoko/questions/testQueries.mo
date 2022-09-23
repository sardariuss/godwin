import Types "../../../src/godwin_backend/types";
import Queries "../../../src/godwin_backend/questions/queries";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import RBT "mo:stableRBT/StableRBTree";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

// @todo: add tests on lower and upper bounds for the queryQuestions function
// @todo: add tests on entries and entriesRev functions
class TestQueries() = {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types module
  type Question = Types.Question;
  type OrderBy = Types.OrderBy;
  type QueryQuestionsResult = Types.QueryQuestionsResult;
  // For convenience: from queries module
  type QuestionRBTs = Queries.QuestionRBTs;

  type TestableQueryQuestionsResult = Testable.TestableItem<QueryQuestionsResult>;

  func testQueryQuestionsResult(query_result: QueryQuestionsResult) : TestableQueryQuestionsResult {
    {
      display = func (query_result) : Text {
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        buffer.add("ids = [");
        for (id in Array.vals(query_result.ids)) {
          buffer.add(Nat.toText(id) # ", ");
        };
        buffer.add("], next = ");
        switch(query_result.next_id){
          case(null){ buffer.add("null"); };
          case(?id) { buffer.add(Nat.toText(id)); };
        };
        Text.join("", buffer.vals());
      };
      equals = func (qr1: QueryQuestionsResult, qr2: QueryQuestionsResult) : Bool { 
        let equal_ids = Array.equal(qr1.ids, qr2.ids, func(id1: Nat, id2: Nat) : Bool {
          Nat.equal(id1, id2);
        });
        let equal_next = switch(qr1.next_id) {
          case(null) { 
            switch(qr2.next_id) {
              case(null) { true };
              case(_) { false; };
            };
          };
          case(?next_id1) {
            switch(qr2.next_id) {
              case(null) { false };
              case(?next_id2) { Nat.equal(next_id1, next_id2); };
            };
          };
        };
        equal_ids and equal_next;
      };
      item = query_result;
    };
  };

  let principal_0 = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe");
  let principal_1 = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae");
  let principal_2 = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe");
  let principal_3 = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe");
  let principal_4 = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae");

  let question_0 =                           { id = 0; author = principal_0; title = "Selfishness is the overriding drive in the human species, no matter the context."; text = ""; date = 8493; endorsements = 13; pool = { current = { date = 8493; pool = #SPAWN;};   history = []; }; categorization = { current = {date = 1283; categorization = #PENDING;};  history = []; }};
  let question_0_text_update =               { id = 0; author = principal_0; title = "Above all is selfishness is the overriding drive in the human species";            text = ""; date = 8493; endorsements = 13; pool = { current = { date = 8493; pool = #SPAWN;};   history = []; }; categorization = { current = {date = 1283; categorization = #PENDING;};  history = []; }};
  let question_1 =                           { id = 1; author = principal_1; title = "Patents should not exist.";                                                        text = ""; date = 2432; endorsements = 2;  pool = { current = { date = 2432; pool = #ARCHIVE;}; history = []; }; categorization = { current = {date = 9372; categorization = #ONGOING;};  history = []; }};
  let question_1_date_update =               { id = 1; author = principal_1; title = "Patents should not exist.";                                                        text = ""; date = 5123; endorsements = 2;  pool = { current = { date = 2432; pool = #ARCHIVE;}; history = []; }; categorization = { current = {date = 9372; categorization = #ONGOING;};  history = []; }};
  let question_2 =                           { id = 2; author = principal_2; title = "Marriage should be abolished.";                                                    text = ""; date = 3132; endorsements = 43; pool = { current = { date = 3132; pool = #REWARD;};  history = []; }; categorization = { current = {date = 3610; categorization = #DONE([]);}; history = []; }};
  let question_2_endorsements_update =       { id = 2; author = principal_2; title = "Marriage should be abolished.";                                                    text = ""; date = 3132; endorsements = 9;  pool = { current = { date = 3132; pool = #REWARD;};  history = []; }; categorization = { current = {date = 3610; categorization = #DONE([]);}; history = []; }};
  let question_3 =                           { id = 3; author = principal_3; title = "It is necessary to massively invest in research to improve productivity.";         text = ""; date = 4213; endorsements = 21; pool = { current = { date = 4213; pool = #SPAWN;};   history = []; }; categorization = { current = {date = 4721; categorization = #PENDING;};  history = []; }};
  let question_3_pool_update =               { id = 3; author = principal_3; title = "It is necessary to massively invest in research to improve productivity.";         text = ""; date = 4213; endorsements = 21; pool = { current = { date = 4213; pool = #ARCHIVE;}; history = []; }; categorization = { current = {date = 4721; categorization = #PENDING;};  history = []; }};
  let question_4 =                           { id = 4; author = principal_4; title = "Insurrection is necessary to deeply change society.";                              text = ""; date = 9711; endorsements = 20; pool = { current = { date = 9711; pool = #REWARD;};  history = []; }; categorization = { current = {date = 9473; categorization = #DONE([]);}; history = []; }};
  let question_4_categorization_update =     { id = 4; author = principal_4; title = "Insurrection is necessary to deeply change society.";                              text = ""; date = 9711; endorsements = 20; pool = { current = { date = 9711; pool = #REWARD;};  history = []; }; categorization = { current = {date = 9473; categorization = #PENDING;};  history = []; }};

  func addQuestions(_rbts: QuestionRBTs) : QuestionRBTs {
    var rbts = _rbts;
    rbts := Queries.add(rbts, question_0);
    rbts := Queries.add(rbts, question_1);
    rbts := Queries.add(rbts, question_2);
    rbts := Queries.add(rbts, question_3);
    rbts := Queries.add(rbts, question_4);
    rbts;
  };

  func replaceQuestions(_rbts: QuestionRBTs) : QuestionRBTs {
    var rbts = _rbts;
    rbts := Queries.replace(rbts, question_0, question_0_text_update);
    rbts := Queries.replace(rbts, question_1, question_1_date_update);
    rbts := Queries.replace(rbts, question_2, question_2_endorsements_update);
    rbts := Queries.replace(rbts, question_3, question_3_pool_update);
    rbts := Queries.replace(rbts, question_4, question_4_categorization_update);
    rbts;
  };

  func removeQuestions(_rbts: QuestionRBTs) : QuestionRBTs {
    var rbts = _rbts;
    rbts := Queries.remove(rbts, question_0);
    rbts := Queries.remove(rbts, question_1);
    rbts;
  };

  var rbts_ = Queries.init();
  rbts_ := Queries.addOrderBy(rbts_, #TITLE);
  rbts_ := Queries.addOrderBy(rbts_, #ENDORSEMENTS);
  rbts_ := Queries.addOrderBy(rbts_, #CREATION_DATE);
  rbts_ := Queries.addOrderBy(rbts_, #POOL_DATE);
  rbts_ := Queries.addOrderBy(rbts_, #CATEGORIZATION_DATE);
  let rbts_add_scenario_ = addQuestions(rbts_);
  let rbts_replace_scenario = replaceQuestions(rbts_add_scenario_);
  let rbts_remove_scenario = removeQuestions(rbts_add_scenario_);

  public let suiteAddQuestions = suite("Queries after questions have been added", [
    test("Query by #ID",                  { ids = [0, 1, 2, 3, 4]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_add_scenario_, #ID,                  null, null, #fwd, 10)))),
    test("Query by #TITLE",               { ids = [4, 3, 2];       next_id = ?1;   }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_add_scenario_, #TITLE,               null, null, #fwd, 3 )))),
    test("Query by #CREATION_DATE",       { ids = [4, 0, 3, 2];    next_id = ?1;   }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_add_scenario_, #CREATION_DATE,       null, null, #bwd, 4 )))),
    test("Query by #ENDORSEMENTS",        { ids = [2, 3, 4, 0, 1]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_add_scenario_, #ENDORSEMENTS,        null, null, #bwd, 5 )))),
    test("Query by #POOL_DATE",           { ids = [3, 0, 2, 4];    next_id = ?1;   }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_add_scenario_, #POOL_DATE,           null, null, #fwd, 4 )))),
    test("Query by #CATEGORIZATION_DATE", { ids = [0, 3, 1, 2];    next_id = ?4;   }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_add_scenario_, #CATEGORIZATION_DATE, null, null, #fwd, 4 )))),
  ]);

  public let suiteReplaceQuestions = suite("Queries after questions have been added and replaced", [
    test("Query by #ID",                  { ids = [0, 1, 2, 3, 4]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_replace_scenario, #ID,                  null, null, #fwd, 10)))),
    test("Query by #TITLE",               { ids = [0, 4, 3];       next_id = ?2;   }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_replace_scenario, #TITLE,               null, null, #fwd, 3 )))),
    test("Query by #CREATION_DATE",       { ids = [4, 0, 1, 3];    next_id = ?2;   }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_replace_scenario, #CREATION_DATE,       null, null, #bwd, 4 )))),
    test("Query by #ENDORSEMENTS",        { ids = [3, 4, 0, 2, 1]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_replace_scenario, #ENDORSEMENTS,        null, null, #bwd, 5 )))),
    test("Query by #POOL_DATE",           { ids = [0, 2, 4, 1];    next_id = ?3;   }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_replace_scenario, #POOL_DATE,           null, null, #fwd, 4 )))),
    test("Query by #CATEGORIZATION_DATE", { ids = [0, 3, 4, 1];    next_id = ?2;   }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_replace_scenario, #CATEGORIZATION_DATE, null, null, #fwd, 4 )))),
  ]);

  public let suiteRemoveQuestions = suite("Queries after questions have been added and some removed", [
    test("Query by #ID",                  { ids = [2, 3, 4]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_remove_scenario, #ID,                  null, null, #fwd, 10)))),
    test("Query by #TITLE",               { ids = [4, 3, 2]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_remove_scenario, #TITLE,               null, null, #fwd, 3 )))),
    test("Query by #CREATION_DATE",       { ids = [4, 3, 2]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_remove_scenario, #CREATION_DATE,       null, null, #bwd, 4 )))),
    test("Query by #ENDORSEMENTS",        { ids = [2, 3, 4]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_remove_scenario, #ENDORSEMENTS,        null, null, #bwd, 5 )))),
    test("Query by #POOL_DATE",           { ids = [3, 2, 4]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_remove_scenario, #POOL_DATE,           null, null, #fwd, 4 )))),
    test("Query by #CATEGORIZATION_DATE", { ids = [3, 2, 4]; next_id = null; }, Matchers.equals(testQueryQuestionsResult(Queries.queryQuestions(rbts_remove_scenario, #CATEGORIZATION_DATE, null, null, #fwd, 4 )))),
  ]);

};