import Types     "../../src/godwin_sub/model/questions/Types";
import Questions "../../src/godwin_sub/model/questions/Questions";

import Principals                               "common/Principals";
import { compare; optionalTestify; Testify; } = "common/Testify";

import Map       "mo:map/Map";
import Set       "mo:map/Set";

import Principal "mo:base/Principal";
import Array     "mo:base/Array";
import Nat       "mo:base/Nat";
import Iter      "mo:base/Iter";
import Text      "mo:base/Text";
import Blob      "mo:base/Blob";
import Debug     "mo:base/Debug";

import { test; suite; } "mo:test";

// @todo: implement a test on searchQuestions
suite("Questions module test suite", func() {

  // For convenience: from types module
  type Question          = Types.Question;
  type OpenQuestionError = Types.OpenQuestionError;
  type QuestionId        = Types.QuestionId;
  type Questions         = Questions.Questions;

  let principals = Principals.init();

  let array_questions : [Question] = [
    { id = 0; author = principals[0]; text = "question0"; date = 9000; },
    { id = 1; author = principals[1]; text = "question1"; date = 8493; },
    { id = 2; author = principals[2]; text = "question2"; date = 2432; },
    { id = 3; author = principals[3]; text = "question3"; date = 5123; },
    { id = 4; author = principals[4]; text = "question4"; date = 3132; },
    { id = 5; author = principals[5]; text = "question5"; date = 3132; },
    { id = 6; author = principals[6]; text = "question6"; date = 4213; },
    { id = 7; author = principals[7]; text = "question7"; date = 4213; },
    { id = 8; author = principals[8]; text = "question8"; date = 9711; },
    { id = 9; author = principals[9]; text = "question9"; date = 9711; }
  ];

  let max_num_characters : Nat = 140;

  let questions = Questions.Questions(Questions.initRegister(max_num_characters));

  suite("Test the created questions are faithfull to the original parameters", func() {
    for(question in Array.vals(array_questions)) {
      test("Create question " # Nat.toText(question.id), func() {
        compare(
          questions.createQuestion(question.author, question.date, question.text),
          question,
          Testify.question.equal);
      });
    };
  });
  suite("Test that every created question can be found", func() {
    for(question in Array.vals(array_questions)) {
      test("Find question " # Nat.toText(question.id), func() {
        compare(
          questions.findQuestion(question.id),
          ?question,
          optionalTestify(Testify.question.equal));
      });
    };
  });
  suite("Test that no other question can be found", func() {
    for(question in Array.vals(array_questions)) {
      test("Cannot find question " # Nat.toText(question.id), func() {
        compare(
          questions.findQuestion(question.id + array_questions.size()),
          null,
          optionalTestify(Testify.question.equal));
      });
    };
  });
  test("It shall not be possible to create a question anonymously", func() {
    compare(
      questions.canCreateQuestion(Principal.fromText("2vxsx-fae"), 0, "Hopefully this is a short enough question"),
      ?#PrincipalIsAnonymous,
      optionalTestify(Testify.openQuestionError.equal));
  });
  test("It shall not be possible to create a question that has more characters than maximum set", func() {
    compare(
      questions.canCreateQuestion(
        Principal.fromText("2ibo7-dia"),
        0,
        switch(Text.decodeUtf8(Blob.fromArray(Array.tabulate(max_num_characters + 1, func (i: Nat) : Nat8 { 0x61 })))){
          case(?t) { t };
          case(null) { Debug.trap("Cannot decode text"); };
        }
      ),
      ?#TextTooLong,
      optionalTestify(Testify.openQuestionError.equal));
  });
  suite("Test that retrieving the questions from the author works", func() {
    for(question in Array.vals(array_questions)) {
      test("Get author's question " # Nat.toText(question.id), func() {
        compare(
          Set.peekFront(questions.getQuestionIdsFromAuthor(principals[question.id])),
          ?question.id,
          optionalTestify(Testify.nat.equal));
      });
    };
  });
  suite("Test iterating on the questions", func() {
    for (question in questions.iter()){
      test("Can iter on question " # Nat.toText(question.id), func() {
        compare(
          question,
          array_questions[question.id],
          Testify.question.equal);
      });
    };
  });

});
