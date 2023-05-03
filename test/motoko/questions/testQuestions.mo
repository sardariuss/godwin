import Types            "../../../src/godwin_backend/model/questions/Types";
import Questions        "../../../src/godwin_backend/model/questions/Questions";

import TestifyTypes     "testifyTypes";
import Principals       "../Principals";

import Map              "mo:map/Map";

import Testify          "mo:testing/Testify";
import SuiteState       "mo:testing/SuiteState";

import Principal        "mo:base/Principal";
import Array            "mo:base/Array";
import Nat              "mo:base/Nat";
import Iter             "mo:base/Iter";
import Text             "mo:base/Text";
import Blob             "mo:base/Blob";
import Debug            "mo:base/Debug";

// For convenience: from types module
type Question = Types.Question;
type OpenQuestionError = Types.OpenQuestionError;
type Questions = Questions.Questions;

type NamedTest<T> = SuiteState.NamedTest<T>;
type Test<T> = SuiteState.Test<T>;
type Suite<T> = SuiteState.Suite<T>;

let { testifyElement; optionalTestify; } = Testify;
let { describe; itp; equal; } = SuiteState;

let { testify_question; testify_open_question_error; } = TestifyTypes;

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

let questions = Questions.build(Map.new<Nat, Question>(Map.nhash), { var v : Nat = 0; }, { var v = max_num_characters; });

let s = SuiteState.Suite<Questions>(questions);

// Test the creation of questions 
await* s.run([
  describe("Test the created questions are faithfull to the original parameters", 
    Array.tabulate(array_questions.size(), func(index: Nat) : NamedTest<Questions.Questions> {
      let question = array_questions[index];
      itp(
        "Create question " # Nat.toText(index),
        equal(
          testifyElement(testify_question, question),
          func (questions: Questions) : Question { 
            questions.createQuestion(question.author, question.date, question.text) 
          }
        )
      );
    })
  ),
  describe("Test that every created question can be found", 
    Array.tabulate(array_questions.size(), func(index: Nat) : NamedTest<Questions.Questions> {
      let question = array_questions[index];
      itp(
        "Find question " # Nat.toText(index),
        equal(
          testifyElement(optionalTestify(testify_question), ?question),
          func (questions: Questions) : ?Question { 
            questions.findQuestion(question.id) ;
          }
        )
      );
    })
  ),
  describe("Test that no other question can be found", 
    Array.tabulate(10, func(index: Nat) : NamedTest<Questions.Questions> {
      let id = index + 10;
      itp(
        "Cannot find question " # Nat.toText(id),
        equal(
          testifyElement<?Question>(optionalTestify(testify_question), null),
          func (questions: Questions) : ?Question { 
            questions.findQuestion(id) ;
          }
        )
      );
    })
  ),
  describe("It shall not be possible to create a question anonymously", [
    itp(
      "Create question anonymously",
      equal(
        testifyElement<?OpenQuestionError>(optionalTestify(testify_open_question_error), ?#PrincipalIsAnonymous),
        func (questions: Questions) : ?OpenQuestionError { 
          questions.canCreateQuestion(Principal.fromText("2vxsx-fae"), 0, "Hopefully this is a short enough question");
        }
      )
    )
  ]),
  describe("It shall not be possible to create a question that has more characters than maximum set", [
    itp(
      "Create a long question",
      equal(
        testifyElement<?OpenQuestionError>(optionalTestify(testify_open_question_error), ?#TextTooLong),
        func (questions: Questions) : ?OpenQuestionError { 
          let text = switch(Text.decodeUtf8(Blob.fromArray(Array.tabulate(max_num_characters + 1, func (i: Nat) : Nat8 { 0x61 })))){
            case(?t) { t };
            case(null) { Debug.trap("Cannot decode text"); };
          };
          questions.canCreateQuestion(Principal.fromText("2ibo7-dia"), 0, text);
        }
      )
    )
  ])
]);

// @todo: for some reason the test on iteration does not work separatly (maybe because the questions class is put into the state?)
//await* s.run([
//  describe("Test iterating on the questions", 
//      Array.mapEntries(Iter.toArray(questions.iter()), func(question: Question, index: Nat) : NamedTest<Questions.Questions> {
//        itp(
//          "Can iter on question " # Nat.toText(array_questions[index].id),
//          equal(
//            testifyElement<Question>(testify_question, array_questions[index]),
//            func (questions: Questions) : Question { question }
//          )
//        );
//      })
//    ),
//]);

// @todo: implement a test on searchQuestions
