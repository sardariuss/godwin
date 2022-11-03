import Types "../../../src/godwin_backend/types";
import Questions "../../../src/godwin_backend/questions/questions";
import TestableItemExtension "../testableItemExtension";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
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

    func questionToText(question: Question) : Text {
      var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
      buffer.add("id: " # Nat.toText(question.id) # ", ");
      buffer.add("author: " # Principal.toText(question.author) # ", ");
      buffer.add("title: " # question.title # ", ");
      buffer.add("text: " # question.text # ", ");
      buffer.add("date: " # Int.toText(question.date) # ", ");
      buffer.add("endorsements: " # Nat.toText(question.endorsements) # ", ");
      // buffer.add(.toText(question.selection_stage)); // @todo
      // buffer.add(.toText(question.categorization_stage)); // @todo
      Text.join("", buffer.vals());
    };
    
    func questionEqual(q1: Question, q2: Question) : Bool {
      return Nat.equal(q1.id, q2.id)
         and Principal.equal(q1.author, q2.author)
         and Text.equal(q1.title, q2.title)
         and Text.equal(q1.text, q2.text)
         and Int.equal(q1.date, q2.date)
         and Nat.equal(q1.endorsements, q2.endorsements);
         // @todo
    };

    func testOptQuestion(question: ?Question) : Testable.TestableItem<?Question> {
      TestableItemExtension.testOptItem(question, questionToText, questionEqual);
    };

    let array_originals_ = [
      { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Sexual orientation is a social construct";   text = ""; date = 8493; endorsements = 0; selection_stage = [{ timestamp = 8493; stage = #CREATED; }]; categorization_stage = [{ timestamp = 8493; stage = #PENDING; }]; },
      { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Borders should eventually be abolished.";    text = ""; date = 8493; endorsements = 0; selection_stage = [{ timestamp = 8493; stage = #CREATED; }]; categorization_stage = [{ timestamp = 8493; stage = #PENDING; }]; },
      { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "A good citizen is a patriot.";               text = ""; date = 2432; endorsements = 0; selection_stage = [{ timestamp = 2432; stage = #CREATED; }]; categorization_stage = [{ timestamp = 2432; stage = #PENDING; }]; },
      { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "The labor market enslaves workers.";         text = ""; date = 5123; endorsements = 0; selection_stage = [{ timestamp = 5123; stage = #CREATED; }]; categorization_stage = [{ timestamp = 5123; stage = #PENDING; }]; },
      { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "We should be retiring earlier.";             text = ""; date = 3132; endorsements = 0; selection_stage = [{ timestamp = 3132; stage = #CREATED; }]; categorization_stage = [{ timestamp = 3132; stage = #PENDING; }]; },
      { id = 5; author = Principal.fromText("lejdd-efwn5-h3qqe-4bunw-faabt-qwb7j-oiskz-c3dkg-3q5z5-ozrtn-dqe"); title = "Marriage should be abolished.";              text = ""; date = 3132; endorsements = 0; selection_stage = [{ timestamp = 3132; stage = #CREATED; }]; categorization_stage = [{ timestamp = 3132; stage = #PENDING; }]; },
      { id = 6; author = Principal.fromText("amerw-mz3nq-gfkbp-o3qgo-zldsl-upilh-zatjw-66nkr-527cf-m7hnq-pae"); title = "Euthanasia should be authorized.";           text = ""; date = 4213; endorsements = 0; selection_stage = [{ timestamp = 4213; stage = #CREATED; }]; categorization_stage = [{ timestamp = 4213; stage = #PENDING; }]; },
      { id = 7; author = Principal.fromText("gbvlf-igtmq-g5vs2-skrhr-txgij-4f2j3-v2jqy-re5cm-i6hsu-gpzcd-aae"); title = "We must fight against global warming.";      text = ""; date = 4213; endorsements = 0; selection_stage = [{ timestamp = 4213; stage = #CREATED; }]; categorization_stage = [{ timestamp = 4213; stage = #PENDING; }]; },
      { id = 8; author = Principal.fromText("mrdr7-aufxf-oiq6j-hyib2-rxb5m-cqrnb-uzgyq-durnt-75u4x-rrvow-iae"); title = "Exploitation of fossil fuels is necessary."; text = ""; date = 9711; endorsements = 0; selection_stage = [{ timestamp = 9711; stage = #CREATED; }]; categorization_stage = [{ timestamp = 9711; stage = #PENDING; }]; },
      { id = 9; author = Principal.fromText("zoyw4-o2dcy-xajcf-e2nvu-436rg-ghrbs-35bzk-nakpb-mvs7t-x4byt-nqe"); title = "The police should be armed.";                text = ""; date = 9711; endorsements = 0; selection_stage = [{ timestamp = 9711; stage = #CREATED; }]; categorization_stage = [{ timestamp = 9711; stage = #PENDING; }]; },
    ];

    let array_modified_ : [Question] = [
      { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Sexual orientation is a social construct";   text = ""; date = 8493; endorsements = 13; selection_stage = [{ timestamp = 8493; stage = #CREATED;                                                  }]; categorization_stage = [{ timestamp = 8493; stage = #PENDING;  }]; },
      { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Borders should eventually be abolished.";    text = ""; date = 6286; endorsements = 12; selection_stage = [{ timestamp = 6286; stage = #CREATED;                                                  }]; categorization_stage = [{ timestamp = 6286; stage = #PENDING;  }]; },
      { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "A good citizen is a patriot.";               text = ""; date = 2432; endorsements = 32; selection_stage = [{ timestamp = 2432; stage = #ARCHIVED({ cursor = 0.0; confidence = 0.5; total = 10; }) }]; categorization_stage = [{ timestamp = 2432; stage = #ONGOING;  }]; },
      { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "The labor market enslaves workers.";         text = ""; date = 1321; endorsements = 2;  selection_stage = [{ timestamp = 1321; stage = #ARCHIVED({ cursor = 0.0; confidence = 0.5; total = 10; }) }]; categorization_stage = [{ timestamp = 1321; stage = #ONGOING;  }]; },
      { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "We should be retiring earlier.";             text = ""; date = 7234; endorsements = 43; selection_stage = [{ timestamp = 7234; stage = #SELECTED;                                                 }]; categorization_stage = [{ timestamp = 7234; stage = #DONE([]); }]; },
      { id = 5; author = Principal.fromText("lejdd-efwn5-h3qqe-4bunw-faabt-qwb7j-oiskz-c3dkg-3q5z5-ozrtn-dqe"); title = "Marriage should be abolished.";              text = ""; date = 3132; endorsements = 9;  selection_stage = [{ timestamp = 3132; stage = #SELECTED;                                                 }]; categorization_stage = [{ timestamp = 3132; stage = #DONE([]); }]; },
      { id = 6; author = Principal.fromText("amerw-mz3nq-gfkbp-o3qgo-zldsl-upilh-zatjw-66nkr-527cf-m7hnq-pae"); title = "Euthanasia should be authorized.";           text = ""; date = 4213; endorsements = 75; selection_stage = [{ timestamp = 4213; stage = #CREATED;                                                  }]; categorization_stage = [{ timestamp = 4213; stage = #PENDING;  }]; },
      { id = 7; author = Principal.fromText("gbvlf-igtmq-g5vs2-skrhr-txgij-4f2j3-v2jqy-re5cm-i6hsu-gpzcd-aae"); title = "We must fight against global warming.";      text = ""; date = 3421; endorsements = 21; selection_stage = [{ timestamp = 3421; stage = #ARCHIVED({ cursor = 0.0; confidence = 0.5; total = 10; }) }]; categorization_stage = [{ timestamp = 3421; stage = #PENDING;  }]; },
      { id = 8; author = Principal.fromText("mrdr7-aufxf-oiq6j-hyib2-rxb5m-cqrnb-uzgyq-durnt-75u4x-rrvow-iae"); title = "Exploitation of fossil fuels is necessary."; text = ""; date = 5431; endorsements = 15; selection_stage = [{ timestamp = 5431; stage = #SELECTED;                                                 }]; categorization_stage = [{ timestamp = 5431; stage = #DONE([]); }]; },
      { id = 9; author = Principal.fromText("zoyw4-o2dcy-xajcf-e2nvu-436rg-ghrbs-35bzk-nakpb-mvs7t-x4byt-nqe"); title = "The police should be armed.";                text = ""; date = 9711; endorsements = 20; selection_stage = [{ timestamp = 9711; stage = #SELECTED;                                                 }]; categorization_stage = [{ timestamp = 9711; stage = #PENDING;  }]; },
    ];

    public func getSuite() : Suite.Suite {
      
      let tests = Buffer.Buffer<Suite.Suite>(array_originals_.size() * 4);
      let questions = Questions.empty();
      
      // Test that created questions are equal to original questions
      for (index in Array.keys(array_originals_)){
        let question = array_originals_[index];
        tests.add(test(
          "Create question " # Nat.toText(index),
          ?questions.createQuestion(question.author, question.date, question.title, question.text),
          Matchers.equals(testOptQuestion(?question))));
      };
      
      // Test replacing the questions
      for (index in Array.keys(array_modified_)){
        questions.replaceQuestion(array_modified_[index]);
        tests.add(test(
          "Replace question " # Nat.toText(index),
          questions.findQuestion(index),
          Matchers.equals(testOptQuestion(?array_modified_[index]))));
      };
      
      // Test iterating on selection stage
      let iter_created_questions = questions.getInSelectionStage(#CREATED, #ENDORSEMENTS, #BWD);
      tests.add(test("Iter on created question (1)", Questions.nextQuestion(questions, iter_created_questions), Matchers.equals(testOptQuestion(?array_modified_[6]))));
      tests.add(test("Iter on created question (2)", Questions.nextQuestion(questions, iter_created_questions), Matchers.equals(testOptQuestion(?array_modified_[0]))));
      tests.add(test("Iter on created question (3)", Questions.nextQuestion(questions, iter_created_questions), Matchers.equals(testOptQuestion(?array_modified_[1]))));
      tests.add(test("Iter on created question (4)", Questions.nextQuestion(questions, iter_created_questions), Matchers.equals(testOptQuestion(null))));
      let iter_selected_questions = questions.getInSelectionStage(#SELECTED, #SELECTION_STAGE_DATE, #FWD);
      tests.add(test("Iter on selected question (1)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(testOptQuestion(?array_modified_[5]))));
      tests.add(test("Iter on selected question (2)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(testOptQuestion(?array_modified_[8]))));
      tests.add(test("Iter on selected question (3)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(testOptQuestion(?array_modified_[4]))));
      tests.add(test("Iter on selected question (4)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(testOptQuestion(?array_modified_[9]))));
      tests.add(test("Iter on selected question (5)", Questions.nextQuestion(questions, iter_selected_questions), Matchers.equals(testOptQuestion(null))));
      let iter_archived_questions = questions.getInSelectionStage(#ARCHIVED, #ID, #FWD);
      tests.add(test("Iter on archived question (1)", Questions.nextQuestion(questions, iter_archived_questions), Matchers.equals(testOptQuestion(?array_modified_[2]))));
      tests.add(test("Iter on archived question (2)", Questions.nextQuestion(questions, iter_archived_questions), Matchers.equals(testOptQuestion(?array_modified_[3]))));
      tests.add(test("Iter on archived question (3)", Questions.nextQuestion(questions, iter_archived_questions), Matchers.equals(testOptQuestion(?array_modified_[7]))));
      tests.add(test("Iter on archived question (4)", Questions.nextQuestion(questions, iter_archived_questions), Matchers.equals(testOptQuestion(null))));
      
      // Test iterating on categorization stage
      let iter_pending_categorization = questions.getInCategorizationStage(#PENDING, #ID, #FWD);
      tests.add(test("Iter on pending categorization (1)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(testOptQuestion(?array_modified_[0]))));
      tests.add(test("Iter on pending categorization (2)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(testOptQuestion(?array_modified_[1]))));
      tests.add(test("Iter on pending categorization (3)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(testOptQuestion(?array_modified_[6]))));
      tests.add(test("Iter on pending categorization (4)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(testOptQuestion(?array_modified_[7]))));
      tests.add(test("Iter on pending categorization (5)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(testOptQuestion(?array_modified_[9]))));
      tests.add(test("Iter on pending categorization (6)", Questions.nextQuestion(questions, iter_pending_categorization), Matchers.equals(testOptQuestion(null))));
      let iter_ongoing_categorization = questions.getInCategorizationStage(#ONGOING, #CATEGORIZATION_STAGE_DATE, #BWD);
      tests.add(test("Iter on ongoing categorization (1)", Questions.nextQuestion(questions, iter_ongoing_categorization), Matchers.equals(testOptQuestion(?array_modified_[2]))));
      tests.add(test("Iter on ongoing categorization (2)", Questions.nextQuestion(questions, iter_ongoing_categorization), Matchers.equals(testOptQuestion(?array_modified_[3]))));
      tests.add(test("Iter on ongoing categorization (6)", Questions.nextQuestion(questions, iter_ongoing_categorization), Matchers.equals(testOptQuestion(null))));
      let iter_done_categorization = questions.getInCategorizationStage(#DONE, #ID, #FWD);
      tests.add(test("Iter on done categorization (3)", Questions.nextQuestion(questions, iter_done_categorization), Matchers.equals(testOptQuestion(?array_modified_[4]))));
      tests.add(test("Iter on done categorization (4)", Questions.nextQuestion(questions, iter_done_categorization), Matchers.equals(testOptQuestion(?array_modified_[5]))));
      tests.add(test("Iter on done categorization (5)", Questions.nextQuestion(questions, iter_done_categorization), Matchers.equals(testOptQuestion(?array_modified_[8]))));
      tests.add(test("Iter on done categorization (6)", Questions.nextQuestion(questions, iter_done_categorization), Matchers.equals(testOptQuestion(null))));
      
      suite("Test Questions module", tests.toArray());
    };
  };

};