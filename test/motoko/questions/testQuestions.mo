import Types "../../../src/godwin_backend/model/Types";
import Questions "../../../src/godwin_backend/model/Questions";
import Queries "../../../src/godwin_backend/model/QuestionQueries";

import TestableItems "../testableItems";
import Principals "../Principals";

import Map "mo:map/Map";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  
  public func run() {

    let principals = Principals.init();

    let array_originals : [Question] = [
      { id = 0; author = principals[0]; text = "question0"; date = 9000; status_info = { status = #CANDIDATE; iteration = 0; date = 9000; }; },
      { id = 1; author = principals[1]; text = "question1"; date = 8493; status_info = { status = #CANDIDATE; iteration = 0; date = 8493; }; },
      { id = 2; author = principals[2]; text = "question2"; date = 2432; status_info = { status = #CANDIDATE; iteration = 0; date = 2432; }; },
      { id = 3; author = principals[3]; text = "question3"; date = 5123; status_info = { status = #CANDIDATE; iteration = 0; date = 5123; }; },
      { id = 4; author = principals[4]; text = "question4"; date = 3132; status_info = { status = #CANDIDATE; iteration = 0; date = 3132; }; },
      { id = 5; author = principals[5]; text = "question5"; date = 3132; status_info = { status = #CANDIDATE; iteration = 0; date = 3132; }; },
      { id = 6; author = principals[6]; text = "question6"; date = 4213; status_info = { status = #CANDIDATE; iteration = 0; date = 2012; }; },
      { id = 7; author = principals[7]; text = "question7"; date = 4213; status_info = { status = #CANDIDATE; iteration = 0; date = 4213; }; },
      { id = 8; author = principals[8]; text = "question8"; date = 9711; status_info = { status = #CANDIDATE; iteration = 0; date = 9311; }; },
      { id = 9; author = principals[9]; text = "question9"; date = 9711; status_info = { status = #CANDIDATE; iteration = 0; date = 9711; }; }
    ];

    let array_modified : [Question] = [
      array_originals[0],
      array_originals[1],
      { array_originals[2] with status_info = { status = #OPEN; iteration = 0; date = 2432; } },
      array_originals[3],
      { array_originals[4] with status_info = { status = #OPEN; iteration = 0; date = 7234; } },
      { array_originals[5] with status_info = { status = #OPEN; iteration = 0; date = 3132; } },
      array_originals[6],
      array_originals[7],
      { array_originals[8] with status_info = { status = #OPEN; iteration = 0; date = 5431; } },
      { array_originals[9] with status_info = { status = #OPEN; iteration = 0; date = 9711; } }
    ];

    let tests = Buffer.Buffer<Suite.Suite>(array_originals.size() * 4);
    
    let questions = Questions.build(Map.new<Nat, Question>(Map.nhash), { var v : Nat = 0; });

    let queries = Queries.build(Queries.initRegister());
    
    // Test that created questions are equal to original questions
    for (new_question in Array.vals(array_originals)){
      tests.add(Suite.test(
        "Create question " # Nat.toText(new_question.id),
        questions.createQuestion(new_question.author, new_question.date, new_question.text), 
        Matchers.equals(TestableItems.question(new_question))
      ));
      queries.replace(null, ?Queries.toStatusEntry(new_question));
    };
    
    // Test udapting the status
    for (updated_question in Array.vals(array_modified)){
      questions.replaceQuestion(updated_question);
      tests.add(Suite.test(
        "Replace question " # Nat.toText(updated_question.id),
        questions.getQuestion(updated_question.id),
        Matchers.equals(TestableItems.question(updated_question))
      ));
      queries.replace(?Queries.toStatusEntry(array_originals[updated_question.id]), ?Queries.toStatusEntry(updated_question));
    };
    
    // Iter on interest status
    let iter_interest = Iter.map(queries.iter(#STATUS(#CANDIDATE), #FWD), func(id: Nat) : Question { questions.getQuestion(id); });
    tests.add(Suite.test("Iter on interest question (1)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[6]))));
    tests.add(Suite.test("Iter on interest question (2)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[7]))));
    tests.add(Suite.test("Iter on interest question (3)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[3]))));
    tests.add(Suite.test("Iter on interest question (4)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[1]))));
    tests.add(Suite.test("Iter on interest question (5)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[0]))));
    tests.add(Suite.test("Iter on interest question (6)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(null))));
    // Iter on opinion status
    let iter_opinion = Iter.map(queries.iter(#STATUS(#OPEN), #FWD), func(id: Nat) : Question { questions.getQuestion(id); });
    tests.add(Suite.test("Iter on opinioned question (1)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[2]))));
    tests.add(Suite.test("Iter on opinioned question (2)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[5]))));
    tests.add(Suite.test("Iter on opinioned question (3)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[8]))));
    tests.add(Suite.test("Iter on opinioned question (4)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[4]))));
    tests.add(Suite.test("Iter on opinioned question (4)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[9]))));
    tests.add(Suite.test("Iter on opinioned question (5)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(null))));

    Suite.run(Suite.suite("Test Questions module", Buffer.toArray(tests)));

  };

};