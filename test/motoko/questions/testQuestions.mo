import Types "../../../src/godwin_backend/types";
import Questions "../../../src/godwin_backend/questions/questions";
import Polarization "../../../src/godwin_backend/representation/polarization";
import CategoryPolarizationTrie "../../../src/godwin_backend/representation/categoryPolarizationTrie";
import Categories "../../../src/godwin_backend/categories";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types module
  type Question = Types.Question;
  // For convenience: from other modules
  type Questions = Questions.Questions;
  
  public class TestQuestions() = {

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

    let array_originals_ = [
      { id = 0; author = principal_0 ; title = "title0"; text = ""; date = 8493; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 8493; stage = #CREATED; }]; categorization_stage = [{ timestamp = 8493; stage = #PENDING; }]; },
      { id = 1; author = principal_1 ; title = "title1"; text = ""; date = 8493; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 8493; stage = #CREATED; }]; categorization_stage = [{ timestamp = 8493; stage = #PENDING; }]; },
      { id = 2; author = principal_2 ; title = "title2"; text = ""; date = 2432; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 2432; stage = #CREATED; }]; categorization_stage = [{ timestamp = 2432; stage = #PENDING; }]; },
      { id = 3; author = principal_3 ; title = "title3"; text = ""; date = 5123; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 5123; stage = #CREATED; }]; categorization_stage = [{ timestamp = 5123; stage = #PENDING; }]; },
      { id = 4; author = principal_4 ; title = "title4"; text = ""; date = 3132; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 3132; stage = #CREATED; }]; categorization_stage = [{ timestamp = 3132; stage = #PENDING; }]; },
      { id = 5; author = principal_5 ; title = "title5"; text = ""; date = 3132; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 3132; stage = #CREATED; }]; categorization_stage = [{ timestamp = 3132; stage = #PENDING; }]; },
      { id = 6; author = principal_6 ; title = "title6"; text = ""; date = 4213; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 4213; stage = #CREATED; }]; categorization_stage = [{ timestamp = 4213; stage = #PENDING; }]; },
      { id = 7; author = principal_7 ; title = "title7"; text = ""; date = 4213; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 4213; stage = #CREATED; }]; categorization_stage = [{ timestamp = 4213; stage = #PENDING; }]; },
      { id = 8; author = principal_8 ; title = "title8"; text = ""; date = 9711; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 9711; stage = #CREATED; }]; categorization_stage = [{ timestamp = 9711; stage = #PENDING; }]; },
      { id = 9; author = principal_9 ; title = "title9"; text = ""; date = 9711; aggregates = { interest = { ups = 0; downs = 0; score = 0; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 9711; stage = #CREATED; }]; categorization_stage = [{ timestamp = 9711; stage = #PENDING; }]; },
    ];

    let array_modified_ : [Question] = [
      { id = 0; author = principal_0; title = "title0"; text = ""; date = 8493; aggregates = { interest = { ups = 0; downs = 0; score = 13; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 8493; stage = #CREATED;}];                                               categorization_stage = [{ timestamp = 8493; stage = #PENDING;  }]; },
      { id = 1; author = principal_1; title = "title1"; text = ""; date = 6286; aggregates = { interest = { ups = 0; downs = 0; score = 12; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 6286; stage = #CREATED;}];                                               categorization_stage = [{ timestamp = 6286; stage = #PENDING;  }]; },
      { id = 2; author = principal_2; title = "title2"; text = ""; date = 2432; aggregates = { interest = { ups = 0; downs = 0; score = 32; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 2432; stage = #ARCHIVED({ left = 0.0; center = 10.0; right = 0.0; }) }]; categorization_stage = [{ timestamp = 2432; stage = #ONGOING;  }]; },
      { id = 3; author = principal_3; title = "title3"; text = ""; date = 1321; aggregates = { interest = { ups = 0; downs = 0; score = 2;  }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 1321; stage = #ARCHIVED({ left = 0.0; center = 10.0; right = 0.0; }) }]; categorization_stage = [{ timestamp = 1321; stage = #ONGOING;  }]; },
      { id = 4; author = principal_4; title = "title4"; text = ""; date = 7234; aggregates = { interest = { ups = 0; downs = 0; score = 43; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 7234; stage = #SELECTED;}];                                              categorization_stage = [{ timestamp = 7234; stage = #DONE([]); }]; },
      { id = 5; author = principal_5; title = "title5"; text = ""; date = 3132; aggregates = { interest = { ups = 0; downs = 0; score = 9;  }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 3132; stage = #SELECTED;}];                                              categorization_stage = [{ timestamp = 3132; stage = #DONE([]); }]; },
      { id = 6; author = principal_6; title = "title6"; text = ""; date = 4213; aggregates = { interest = { ups = 0; downs = 0; score = 75; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 4213; stage = #CREATED;}];                                               categorization_stage = [{ timestamp = 4213; stage = #PENDING;  }]; },
      { id = 7; author = principal_7; title = "title7"; text = ""; date = 3421; aggregates = { interest = { ups = 0; downs = 0; score = 21; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 3421; stage = #ARCHIVED({ left = 0.0; center = 10.0; right = 0.0; }) }]; categorization_stage = [{ timestamp = 3421; stage = #PENDING;  }]; },
      { id = 8; author = principal_8; title = "title8"; text = ""; date = 5431; aggregates = { interest = { ups = 0; downs = 0; score = 15; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 5431; stage = #SELECTED;}];                                              categorization_stage = [{ timestamp = 5431; stage = #DONE([]); }]; },
      { id = 9; author = principal_9; title = "title9"; text = ""; date = 9711; aggregates = { interest = { ups = 0; downs = 0; score = 20; }; opinion = Polarization.nil(); categorization = CategoryPolarizationTrie.nil([]); }; selection_stage = [{ timestamp = 9711; stage = #SELECTED;}];                                              categorization_stage = [{ timestamp = 9711; stage = #PENDING;  }]; },
    ];

    public func getSuite() : Suite.Suite {
      
      let tests = Buffer.Buffer<Suite.Suite>(array_originals_.size() * 4);
      let categories = Categories.Categories([]);
      let questions = Questions.empty(categories);
      
      // Test that created questions are equal to original questions
      for (index in Array.keys(array_originals_)){
        let question = array_originals_[index];
        tests.add(test(
          "Create question " # Nat.toText(index),
          ?questions.createQuestion(question.author, question.date, question.title, question.text),
          Matchers.equals(TestableItems.optQuestion(?question))));
      };
      
      // Test replacing the questions
      for (index in Array.keys(array_modified_)){
        questions.replaceQuestion(array_modified_[index]);
        tests.add(test(
          "Replace question " # Nat.toText(index),
          questions.findQuestion(index),
          Matchers.equals(TestableItems.optQuestion(?array_modified_[index]))));
      };
      
      // Test iterating on selection stage
      let iter_created_questions = questions.getInSelectionStage(#CREATED, #ENDORSEMENTS, #BWD);
      tests.add(test("Iter on created question (1)", Questions.nextQuestion(questions, iter_created_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[6]))));
      tests.add(test("Iter on created question (2)", Questions.nextQuestion(questions, iter_created_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[0]))));
      tests.add(test("Iter on created question (3)", Questions.nextQuestion(questions, iter_created_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[1]))));
      tests.add(test("Iter on created question (4)", Questions.nextQuestion(questions, iter_created_questions), Matchers.equals(TestableItems.optQuestion(null))));
      let iter_selected_questions = questions.getInSelectionStage(#SELECTED, #SELECTION_STAGE_DATE, #FWD);
      tests.add(test("Iter on selected question (1)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[5]))));
      tests.add(test("Iter on selected question (2)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[8]))));
      tests.add(test("Iter on selected question (3)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[4]))));
      tests.add(test("Iter on selected question (4)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[9]))));
      tests.add(test("Iter on selected question (5)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(TestableItems.optQuestion(null))));
      let iter_archived_questions = questions.getInSelectionStage(#ARCHIVED, #ID, #FWD);
      tests.add(test("Iter on archived question (1)", Questions.nextQuestion(questions, iter_archived_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[2]))));
      tests.add(test("Iter on archived question (2)", Questions.nextQuestion(questions, iter_archived_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[3]))));
      tests.add(test("Iter on archived question (3)", Questions.nextQuestion(questions, iter_archived_questions), Matchers.equals(TestableItems.optQuestion(?array_modified_[7]))));
      tests.add(test("Iter on archived question (4)", Questions.nextQuestion(questions, iter_archived_questions), Matchers.equals(TestableItems.optQuestion(null))));
      
      // Test iterating on categorization stage
      let iter_pending_categorization = questions.getInCategorizationStage(#PENDING, #ID, #FWD);
      tests.add(test("Iter on pending categorization (1)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[0]))));
      tests.add(test("Iter on pending categorization (2)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[1]))));
      tests.add(test("Iter on pending categorization (3)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[6]))));
      tests.add(test("Iter on pending categorization (4)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[7]))));
      tests.add(test("Iter on pending categorization (5)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[9]))));
      tests.add(test("Iter on pending categorization (6)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(TestableItems.optQuestion(null))));
      let iter_ongoing_categorization = questions.getInCategorizationStage(#ONGOING, #CATEGORIZATION_STAGE_DATE, #BWD);
      tests.add(test("Iter on ongoing categorization (1)", Questions.nextQuestion(questions, iter_ongoing_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[2]))));
      tests.add(test("Iter on ongoing categorization (2)", Questions.nextQuestion(questions, iter_ongoing_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[3]))));
      tests.add(test("Iter on ongoing categorization (6)", Questions.nextQuestion(questions, iter_ongoing_categorization), Matchers.equals(TestableItems.optQuestion(null))));
      let iter_done_categorization = questions.getInCategorizationStage(#DONE, #ID, #FWD);
      tests.add(test("Iter on done categorization (3)", Questions.nextQuestion(questions, iter_done_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[4]))));
      tests.add(test("Iter on done categorization (4)", Questions.nextQuestion(questions, iter_done_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[5]))));
      tests.add(test("Iter on done categorization (5)", Questions.nextQuestion(questions, iter_done_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[8]))));
      tests.add(test("Iter on done categorization (6)", Questions.nextQuestion(questions, iter_done_categorization), Matchers.equals(TestableItems.optQuestion(null))));
      
      suite("Test Questions module", tests.toArray());
    };
  };

};