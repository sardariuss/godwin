import Votes "../../src/godwin_backend/model/votes/Votes";
import Cursor "../../src/godwin_backend/model/votes/representation/Cursor";
import Polarization "../../src/godwin_backend/model/votes/representation/Polarization";
import CursorMap "../../src/godwin_backend/model/votes/representation/CursorMap";
import PolarizationMap "../../src/godwin_backend/model/votes/representation/PolarizationMap";
import Queries "../../src/godwin_backend/model/QuestionQueries";
import Questions "../../src/godwin_backend/model/Questions";
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
  type InterestBallot = Types.InterestBallot;
  type OpinionBallot = Types.OpinionBallot;
  type CategorizationBallot = Types.CategorizationBallot;
  
  // For convenience: from queries module
  type ScanLimitResult = Queries.ScanLimitResult;

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

  public func question(question: Question) : Testable.TestableItem<Question> {
    { display = Questions.toText; equals = Questions.equal; item = question; };
  };

  public func optQuestion(question: ?Question) : Testable.TestableItem<?Question> {
    testOptItem(question, Questions.toText, Questions.equal);
  };

  public func optCursorMap(cursor_trie: ?CursorMap) : Testable.TestableItem<?CursorMap> {
    testOptItem(cursor_trie, CursorMap.toText, CursorMap.equal);
  };

  public func optInterestBallot(interest_ballot: ?InterestBallot) : Testable.TestableItem<?InterestBallot> {
    testOptItem(
      interest_ballot,
      func(b: InterestBallot) : Text { Votes.ballotToText(b, Cursor.toText); },
      func(b1: InterestBallot, b2: InterestBallot) : Bool { Votes.ballotsEqual(b1, b2, Cursor.equal); }
    );
  };

  public func optOpinionBallot(opinion_ballot: ?OpinionBallot) : Testable.TestableItem<?OpinionBallot> {
    testOptItem(
      opinion_ballot,
      func(b: OpinionBallot) : Text { Votes.ballotToText(b, Cursor.toText); },
      func(b1: OpinionBallot, b2: OpinionBallot) : Bool { Votes.ballotsEqual(b1, b2, Cursor.equal); }
    );
  };

  // @todo: unused
  public func optPolarization(polarization: ?Polarization) : Testable.TestableItem<?Polarization> {
    testOptItem(polarization, Polarization.toText, Polarization.equal);
  };

  public func optCategorizationBallot(categorization_ballot: ?CategorizationBallot) : Testable.TestableItem<?CategorizationBallot> {
    testOptItem(
      categorization_ballot,
      func(b: CategorizationBallot) : Text { Votes.ballotToText(b, CursorMap.toText); },
      func(b1: CategorizationBallot, b2: CategorizationBallot) : Bool { Votes.ballotsEqual(b1, b2, CursorMap.equal); }
    );
  };

  // @todo: unused
  public func optCategorizationAggregate(categorization_aggregate: ?PolarizationMap) : Testable.TestableItem<?PolarizationMap> {
    testOptItem(categorization_aggregate, PolarizationMap.toText, PolarizationMap.equal);
  };

  public func polarizationMap(polarization_map: PolarizationMap) : Testable.TestableItem<PolarizationMap> {
    { display = PolarizationMap.toText; equals = PolarizationMap.equal; item = polarization_map; };
  };

  public func categoryPolarizationTrie(polarization_trie: PolarizationMap) : Testable.TestableItem<PolarizationMap> {
    { display = PolarizationMap.toText; equals = PolarizationMap.equal; item = polarization_trie; };
  };

  // @todo: unused
  public func optCursor(cursor: ?Cursor) : Testable.TestableItem<?Cursor> {
    testOptItem(cursor, Cursor.toText, Cursor.equal);
  };

  // @todo: unused
  public func polarization(polarization: Polarization) : Testable.TestableItem<Polarization> {
    { display = Polarization.toText; equals = Polarization.equal; item = polarization; };
  };

  public func testScanLimitResult(result: ScanLimitResult) : Testable.TestableItem<ScanLimitResult> {
    {
      display = func (result) : Text {
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        buffer.add("keys = [");
        for (id in Array.vals(result.keys)) {
          buffer.add(Nat.toText(id) # ", ");
        };
        buffer.add("], next = ");
        switch(result.next){
          case(null){ buffer.add("null"); };
          case(?id) { buffer.add(Nat.toText(id)); };
        };
        Text.join("", buffer.vals());
      };
      equals = func (qr1: ScanLimitResult, qr2: ScanLimitResult) : Bool { 
        let equal_keys = Array.equal(qr1.keys, qr2.keys, func(id1: Nat, id2: Nat) : Bool {
          Nat.equal(id1, id2);
        });
        let equal_next = switch(qr1.next) {
          case(null) { 
            switch(qr2.next) {
              case(null) { true };
              case(_) { false; };
            };
          };
          case(?next1) {
            switch(qr2.next) {
              case(null) { false };
              case(?next2) { Nat.equal(next1, next2); };
            };
          };
        };
        equal_keys and equal_next;
      };
      item = result;
    };
  };

};