import Types            "../../src/godwin_sub/model/questions/Types";
import QueriesFactory   "../../src/godwin_sub/model/questions/QueriesFactory";
import KeyConverter     "../../src/godwin_sub/model/questions/KeyConverter";

import Principals                               "common/Principals";
import { compare; optionalTestify; Testify; } = "common/Testify";

import Principal        "mo:base/Principal";
import Array            "mo:base/Array";

import { test; suite; } "mo:test";

suite("Opinions module test suite", func() {

  // For convenience: from types module
  type Question          = Types.Question;
  type OpenQuestionError = Types.OpenQuestionError;
  type StatusInfo        = Types.StatusInfo;
  type ScanLimitResult   = Types.ScanLimitResult;
  type QuestionQueries   = Types.QuestionQueries;

  let { toAuthorKey; toTextKey; toDateKey; toStatusKey; toInterestScoreKey; } = KeyConverter;

  // @todo: add tests on lower and upper bounds for the queryQuestions function
  // @todo: add tests on entries and entriesRev functions

 let principals = Principals.init();

  let questions : [(Question, StatusInfo, Float)] = [
    ({ id = 0; author = principals[0]; text = "Selfishness is the overriding drive in the human species, no matter the context."; date = 8493; }, { status = #CANDIDATE; iteration = 0; date = 6000; }, 87),
    ({ id = 1; author = principals[1]; text = "Patents should not exist.";                                                        date = 2432; }, { status = #OPEN;      iteration = 0; date = 3000; }, 40),
    ({ id = 2; author = principals[2]; text = "Marriage should be abolished.";                                                    date = 3132; }, { status = #OPEN;      iteration = 0; date = 2000; }, 38),
    ({ id = 3; author = principals[3]; text = "It is necessary to massively invest in research to improve productivity.";         date = 4213; }, { status = #CANDIDATE; iteration = 0; date = 4000; }, 23),
    ({ id = 4; author = principals[4]; text = "Insurrection is necessary to deeply change society.";                              date = 9711; }, { status = #OPEN;      iteration = 0; date = 5000; }, 77),
  ];

  let updated_status : [StatusInfo] = [
    { status = #CANDIDATE;             iteration = 0; date = 27;  },
    { status = #CLOSED;                iteration = 0; date = 454; },
    { status = #OPEN;                  iteration = 0; date = 968; },
    { status = #REJECTED(#TIMED_OUT);  iteration = 0; date = 516; },
    { status = #CLOSED;                iteration = 0; date = 959; },
  ];

  let updated_scores : [Float] = [165, 137, 232, 118, 183];

  let register = QueriesFactory.initRegister();
  QueriesFactory.addOrderBy(register, #TEXT);
  QueriesFactory.addOrderBy(register, #DATE);
  QueriesFactory.addOrderBy(register, #STATUS(#CANDIDATE));
  QueriesFactory.addOrderBy(register, #STATUS(#OPEN));
  QueriesFactory.addOrderBy(register, #STATUS(#CLOSED));
  QueriesFactory.addOrderBy(register, #STATUS(#REJECTED));
  QueriesFactory.addOrderBy(register, #INTEREST_SCORE);

  let queries = QueriesFactory.build(register);
  for ((question, status_info, score) in Array.vals(questions)){
    queries.add(toTextKey(question));
    queries.add(toDateKey(question));
    queries.add(toStatusKey(question.id, status_info.status, status_info.date));
    queries.add(toInterestScoreKey(question.id, score));
  };

  suite("Query initial questions", func() {
    test("#TEXT, null, null, #FWD, 2", func() {
      compare(
        queries.scan(#TEXT, null, null, #FWD, 2, null),
        { keys = [4, 3]; next = ?2; },
        Testify.scanLimitResult);
    });
    test("#TEXT, ?2  , null, #FWD, 2", func() {
      compare(
        queries.scan(#TEXT, ?2  , null, #FWD, 2, null),
        { keys = [2, 1]; next = ?0; },
        Testify.scanLimitResult);
    });
    test("#DATE, null, null, #BWD, 2", func() {
      compare(
        queries.scan(#DATE, null, null, #BWD, 2, null),
        { keys = [4, 0]; next = ?3; },
        Testify.scanLimitResult);
    });
    test("#DATE, null, ?3  , #BWD, 2", func() {
      compare(
        queries.scan(#DATE, null, ?3  , #BWD, 2, null),
        { keys = [3, 2]; next = ?1; },
        Testify.scanLimitResult);
    });
    test("#STATUS(#CANDIDATE), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#CANDIDATE), null, null, #FWD, 5, null),
        { keys = [3, 0]; next = null; },
        Testify.scanLimitResult);
    });
    test("#STATUS(#OPEN), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#OPEN), null, null, #FWD, 5, null),
        { keys = [2, 1, 4]; next = null; },
        Testify.scanLimitResult);
    });
    test("#INTEREST_SCORE, null, null, #BWD, 5", func() {
      compare(
        queries.scan(#INTEREST_SCORE, null, null, #BWD, 5, null),
        { keys = [0, 4, 1, 2, 3]; next = null; },
        Testify.scanLimitResult);
    });
  });

  // Update the status and score
  for ((question, status_info, score) in Array.vals(questions)){
    let update = updated_status[question.id];
    queries.replace(?toStatusKey(question.id, status_info.status, status_info.date), ?toStatusKey(question.id, update.status, update.date));
    queries.replace(?toInterestScoreKey(question.id, score), ?toInterestScoreKey(question.id, updated_scores[question.id]));
  };

  suite("Query after update of status and score", func() {
    test("#STATUS(#CANDIDATE), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#CANDIDATE), null, null, #FWD, 5, null),
        { keys = [0]; next = null; },
        Testify.scanLimitResult);
    });
    test("#STATUS(#OPEN), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#OPEN), null, null, #FWD, 5, null),
        { keys = [2]; next = null; },
        Testify.scanLimitResult);
    });
    test("#STATUS(#CLOSED), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#CLOSED), null, null, #FWD, 5, null),
        { keys = [1, 4]; next = null; },
        Testify.scanLimitResult);
    });
    test("#STATUS(#REJECTED), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#REJECTED), null, null, #FWD, 5, null),
        { keys = [3]; next = null; },
        Testify.scanLimitResult);
    });
    test("#INTEREST_SCORE, null, null, #FWD, 5", func() {
      compare(
        queries.scan(#INTEREST_SCORE, null, null, #FWD, 5, null),
        { keys = [3, 1, 0, 4, 2]; next = null; },
        Testify.scanLimitResult);
    });
  });

  // Remove a question
  let (question_3, status_info_3, score_3) = (questions[2].0, updated_status[2], updated_scores[2]);
  queries.remove(toTextKey(question_3));
  queries.remove(toDateKey(question_3));
  queries.remove(toStatusKey(question_3.id, status_info_3.status, status_info_3.date));
  queries.remove(toInterestScoreKey(question_3.id, score_3));

  suite("Query after removal of a question", func() {
    test("STATUS(#CANDIDATE), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#CANDIDATE), null, null, #FWD, 5, null),
        { keys = [0]; next = null; },
        Testify.scanLimitResult);
    });
    test("STATUS(#OPEN), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#OPEN), null, null, #FWD, 5, null),
        { keys = []; next = null; },
        Testify.scanLimitResult);
    });
    test("STATUS(#CLOSED), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#CLOSED), null, null, #FWD, 5, null),
        { keys = [1, 4]; next = null; },
        Testify.scanLimitResult);
    });
    test("STATUS(#REJECTED), null, null, #FWD, 5", func() {
      compare(
        queries.scan(#STATUS(#REJECTED), null, null, #FWD, 5, null),
        { keys = [3]; next = null; },
        Testify.scanLimitResult);
    });
    test("INTEREST_SCORE, null, null, #FWD, 5", func() {
      compare(
        queries.scan(#INTEREST_SCORE, null, null, #FWD, 5, null),
        { keys = [3, 1, 0, 4]; next = null; },
        Testify.scanLimitResult);
    });
  });

});