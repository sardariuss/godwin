import Cursor "../../src/godwin_backend/representation/Cursor";
import Polarization "../../src/godwin_backend/representation/Polarization";
import CursorMap "../../src/godwin_backend/representation/CursorMap";
import PolarizationMap "../../src/godwin_backend/representation/PolarizationMap";
import Queries "../../src/godwin_backend/questions/queries";
import Question "../../src/godwin_backend/questions/question";
import Types "../../src/godwin_backend/model/Types";

import Testable "mo:matchers/Testable";

import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Int "mo:base/Int";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type Interest = Types.Interest;
  type Appeal = Types.Appeal;
  type Ballot<T> = Types.Ballot<T>;
  
  // For convenience: from queries module
  type QueryQuestionsResult = Queries.QueryQuestionsResult;

  public func testOptItem<T>(item: ?T, to_text: T -> Text, equal: (T, T) -> Bool) : Testable.TestableItem<?T> {
    {
      display = func(item: ?T) : Text {
        switch(item){
          case(null) { "(null)"; };
          case(?item) { to_text(item); };
        };
      };
      equals = func (q1: ?T, q2: ?T) : Bool {
        switch(q1){
          case(null) {
            switch(q2){
              case(null) { true; };
              case(_) { false; };
            };
          };
          case(?item1) {
            switch(q2){
              case(null) { false; };
              case(?item2) { equal(item1, item2); };
            };
          };
        };
      };
      item = item;
    }
  };

  public func optQuestion(question: ?Question) : Testable.TestableItem<?Question> {
    testOptItem(question, Question.toText, Question.equal);
  };

  public func optCursorMap(cursor_trie: ?CursorMap) : Testable.TestableItem<?CursorMap> {
    testOptItem(cursor_trie, CursorMap.toText, CursorMap.equal);
  };

  public func optInterestBallot(interest_ballot: ?Timestamp<Interest>) : Testable.TestableItem<?Timestamp<Interest>> {
    testOptItem(
      interest_ballot,
      func(interest_ballot: Timestamp<Interest>) : Text {
        toTextTimestamp(interest_ballot, toTextInterest);
      },
      func(a: Timestamp<Interest>, b: Timestamp<Interest>) : Bool {
        equalTimestamp(a, b, equalInterests);
      }
    );
  };

  public func optAppeal(interest_aggregate: ?Timestamp<Appeal>) : Testable.TestableItem<?Timestamp<Appeal>> {
    testOptItem(
      interest_aggregate,
      func(interest_aggregate: Timestamp<Appeal>) : Text {
        toTextTimestamp(interest_aggregate, toTextAppeal);
      },
      func(a: Timestamp<Appeal>, b: Timestamp<Appeal>) : Bool {
        equalTimestamp(a, b, equalAppeal);
      }
    );
  };

  public func optOpinionBallot(opinion_ballot: ?Timestamp<Cursor>) : Testable.TestableItem<?Timestamp<Cursor>> {
    testOptItem(
      opinion_ballot,
      func(opinion_ballot: Timestamp<Cursor>) : Text {
        toTextTimestamp(opinion_ballot, Cursor.toText);
      },
      func(a: Timestamp<Cursor>, b: Timestamp<Cursor>) : Bool {
        equalTimestamp(a, b, Cursor.equal);
      }
    );
  };

  public func optOpinionAggregate(opinion_aggregate: ?Timestamp<Polarization>) : Testable.TestableItem<?Timestamp<Polarization>> {
    testOptItem(
      opinion_aggregate,
      func(opinion_aggregate: Timestamp<Polarization>) : Text {
        toTextTimestamp(opinion_aggregate, Polarization.toText);
      },
      func(a: Timestamp<Polarization>, b: Timestamp<Polarization>) : Bool {
        equalTimestamp(a, b, Polarization.equal);
      }
    );
  };

  public func optCategorizationBallot(categorization_ballot: ?Timestamp<CursorMap>) : Testable.TestableItem<?Timestamp<CursorMap>> {
    testOptItem(
      categorization_ballot,
      func(categorization_ballot: Timestamp<CursorMap>) : Text {
        toTextTimestamp(categorization_ballot, CursorMap.toText);
      },
      func(a: Timestamp<CursorMap>, b: Timestamp<CursorMap>) : Bool {
        equalTimestamp(a, b, CursorMap.equal);
      }
    );
  };

  public func optCategorizationAggregate(categorization_aggregate: ?Timestamp<PolarizationMap>) : Testable.TestableItem<?Timestamp<PolarizationMap>> {
    testOptItem(
      categorization_aggregate,
      func(categorization_aggregate: Timestamp<PolarizationMap>) : Text {
        toTextTimestamp(categorization_aggregate, PolarizationMap.toText);
      },
      func(a: Timestamp<PolarizationMap>, b: Timestamp<PolarizationMap>) : Bool {
        equalTimestamp(a, b, PolarizationMap.equal);
      }
    );
  };

  public func categoryPolarizationTrie(polarization_trie: PolarizationMap) : Testable.TestableItem<PolarizationMap> {
    {
      display = PolarizationMap.toText;
      equals = PolarizationMap.equal;
      item = polarization_trie;
    };
  };

  public func optCursor(cursor: ?Cursor) : Testable.TestableItem<?Cursor> {
    testOptItem(cursor, Cursor.toText, Cursor.equal);
  };

  public func polarization(polarization: Polarization) : Testable.TestableItem<Polarization> {
    {
      display = Polarization.toText;
      equals = Polarization.equal;
      item = polarization;
    };
  };

  public func testQueryQuestionsResult(query_result: QueryQuestionsResult) : Testable.TestableItem<QueryQuestionsResult> {
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

  func toTextInterest(interest: Interest) : Text {
    switch(interest){ 
      case(#UP){ "UP"; };
      case(#DOWN){ "DOWN"; };
    };
  };

  func equalInterests(interest1: Interest, interest2: Interest) : Bool {
    Text.equal(toTextInterest(interest1), toTextInterest(interest2));
  };

  public func testOptInterest(interest: ?Interest) : Testable.TestableItem<?Interest> {
    testOptItem(interest, toTextInterest, equalInterests);
  };

  func toTextAppeal(total: Appeal) : Text {
    "{ ups = " # Nat.toText(total.ups) # "; downs = " # Nat.toText(total.downs) # " }";
  };

  func equalAppeal(t1: Appeal, t2: Appeal) : Bool {
    t1.ups == t2.ups and t1.downs == t2.downs;
  };

  public func testOptAppeal(total: ?Appeal) : Testable.TestableItem<?Appeal> {
    testOptItem(total, toTextAppeal, equalAppeal);
  };

  func toTextBallot<T>(timestamp : Ballot<T>, to_text_elem : (T) -> (Text)) : Text {
    "{ date = " # Int.toText(timestamp.date) # " (ns); elem = " # to_text_elem(timestamp.elem) # " }";
  };

  func equalBallot<T>(a : Ballot<T>, b : Ballot<T>, equal_elem : (T, T) -> (Bool)) : Bool {
    a.date == b.date and equal_elem(a.elem, b.elem);
  };

};