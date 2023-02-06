import Types "../../../src/godwin_backend/model/Types";
import Questions "../../../src/godwin_backend/model/Questions";
import StatusHelper "../../../src/godwin_backend/model/StatusHelper";
import Queries "../../../src/godwin_backend/model/QuestionQueries";
import Interests "../../../src/godwin_backend/model/votes/Interests";

import TestableItems "../testableItems";
import Principals "../Principals";

import Map "mo:map/Map";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  
  public func run() {

    let principals = Principals.init();

    let array_originals : [Question] = [
      { id = 0; author = principals[0]; title = "title0"; text = ""; date = 9000; status_info = StatusHelper.initStatusInfo(9000); },
      { id = 1; author = principals[1]; title = "title1"; text = ""; date = 8493; status_info = StatusHelper.initStatusInfo(8493); },
      { id = 2; author = principals[2]; title = "title2"; text = ""; date = 2432; status_info = StatusHelper.initStatusInfo(2432); },
      { id = 3; author = principals[3]; title = "title3"; text = ""; date = 5123; status_info = StatusHelper.initStatusInfo(5123); },
      { id = 4; author = principals[4]; title = "title4"; text = ""; date = 3132; status_info = StatusHelper.initStatusInfo(3132); },
      { id = 5; author = principals[5]; title = "title5"; text = ""; date = 3132; status_info = StatusHelper.initStatusInfo(3132); },
      { id = 6; author = principals[6]; title = "title6"; text = ""; date = 4213; status_info = StatusHelper.initStatusInfo(4213); },
      { id = 7; author = principals[7]; title = "title7"; text = ""; date = 4213; status_info = StatusHelper.initStatusInfo(4213); },
      { id = 8; author = principals[8]; title = "title8"; text = ""; date = 9711; status_info = StatusHelper.initStatusInfo(9711); },
      { id = 9; author = principals[9]; title = "title9"; text = ""; date = 9711; status_info = StatusHelper.initStatusInfo(9711); }
    ];

    let array_modified : [Question] = [
      array_originals[0],
      array_originals[1],
      StatusHelper.updateStatusInfo(array_originals[2], #VOTING(#CATEGORIZATION), 2432),
      StatusHelper.updateStatusInfo(array_originals[3], #VOTING(#CATEGORIZATION), 1321),
      StatusHelper.updateStatusInfo(array_originals[4], #VOTING(#OPINION),        7234),
      StatusHelper.updateStatusInfo(array_originals[5], #VOTING(#OPINION),        3132),
      array_originals[6],
      StatusHelper.updateStatusInfo(array_originals[7], #VOTING(#CATEGORIZATION), 4213),
      StatusHelper.updateStatusInfo(array_originals[8], #VOTING(#OPINION),        5431),
      StatusHelper.updateStatusInfo(array_originals[9], #VOTING(#OPINION),        9711)
    ];

    let tests = Buffer.Buffer<Suite.Suite>(array_originals.size() * 4);
    
    let questions = Questions.build(Map.new<Nat, Question>(), { var v : Nat = 0; });

    let interest_votes = Interests.build(Interests.initRegister());
    let queries = Queries.build(Queries.initRegister(), questions, interest_votes);
    
    // Test that created questions are equal to original questions
    for (new_question in Array.vals(array_originals)){
      tests.add(Suite.test(
        "Create question " # Nat.toText(new_question.id),
        questions.createQuestion(new_question.author, new_question.date, new_question.title, new_question.text), 
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
    let iter_interest = queries.entries(#STATUS(#VOTING(#INTEREST)), #FWD);
    tests.add(Suite.test("Iter on interest question (1)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[6]))));
    tests.add(Suite.test("Iter on interest question (2)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[1]))));
    tests.add(Suite.test("Iter on interest question (3)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[0]))));
    tests.add(Suite.test("Iter on interest question (4)", iter_interest.next(), Matchers.equals(TestableItems.optQuestion(null))));
    // Iter on opinion status
    let iter_opinion = queries.entries(#STATUS(#VOTING(#OPINION)), #FWD);
    tests.add(Suite.test("Iter on opinioned question (1)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[5]))));
    tests.add(Suite.test("Iter on opinioned question (2)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[8]))));
    tests.add(Suite.test("Iter on opinioned question (3)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[4]))));
    tests.add(Suite.test("Iter on opinioned question (4)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[9]))));
    tests.add(Suite.test("Iter on opinioned question (5)", iter_opinion.next(), Matchers.equals(TestableItems.optQuestion(null))));
    // Iter on categorization status
    let iter_categorization = queries.entries(#STATUS(#VOTING(#CATEGORIZATION)), #FWD);
    tests.add(Suite.test("Iter on categorized question (1)", iter_categorization.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[3]))));
    tests.add(Suite.test("Iter on categorized question (2)", iter_categorization.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[2]))));
    tests.add(Suite.test("Iter on categorized question (3)", iter_categorization.next(), Matchers.equals(TestableItems.optQuestion(?array_modified[7]))));
    tests.add(Suite.test("Iter on categorized question (4)", iter_categorization.next(), Matchers.equals(TestableItems.optQuestion(null))));

    Suite.run(Suite.suite("Test Questions module", Buffer.toArray(tests)));

  };

};