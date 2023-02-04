import Votes "../../src/godwin_backend/model/votes/Votes";
import Interest "../../src/godwin_backend/model/votes/representation/Interest";
import Appeal "../../src/godwin_backend/model/votes/representation/Appeal";
import Opinion "../../src/godwin_backend/model/votes/representation/Opinion";
import Categorization "../../src/godwin_backend/model/votes/representation/Categorization";
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

  public func question(question: Question) : Testable.TestableItem<Question> {
    { display = Questions.toText; equals = Questions.equal; item = question; };
  };

  public func optQuestion(question: ?Question) : Testable.TestableItem<?Question> {
    testOptItem(question, Questions.toText, Questions.equal);
  };

  public func optCursorMap(cursor_trie: ?CursorMap) : Testable.TestableItem<?CursorMap> {
    testOptItem(cursor_trie, CursorMap.toText, CursorMap.equal);
  };

  public func optInterestBallot(interest_ballot: ?Interest.Ballot) : Testable.TestableItem<?Interest.Ballot> {
    testOptItem(interest_ballot, Interest.ballotToText, Interest.ballotsEqual);
  };

  // @todo: unused
  public func optAppeal(appeal: ?Types.Appeal) : Testable.TestableItem<?Types.Appeal> {
    testOptItem(appeal, Appeal.toText, Appeal.equal);
  };

  public func appeal(appeal: Types.Appeal) : Testable.TestableItem<Types.Appeal> {
    { display = Appeal.toText; equals = Appeal.equal; item = appeal; };
  };

  public func optOpinionBallot(opinion_ballot: ?Opinion.Ballot) : Testable.TestableItem<?Opinion.Ballot> {
    testOptItem(opinion_ballot, Opinion.ballotToText, Opinion.ballotsEqual);
  };

  // @todo: unused
  public func optPolarization(polarization: ?Polarization) : Testable.TestableItem<?Polarization> {
    testOptItem(polarization, Polarization.toText, Polarization.equal);
  };

  public func optCategorizationBallot(categorization_ballot: ?Categorization.Ballot) : Testable.TestableItem<?Categorization.Ballot> {
    testOptItem(categorization_ballot, Categorization.ballotToText, Categorization.ballotsEqual);
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

  // @todo
//  public func testQueryQuestionsResult(query_result: QueryQuestionsResult) : Testable.TestableItem<QueryQuestionsResult> {
//    {
//      display = func (query_result) : Text {
//        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
//        buffer.add("ids = [");
//        for (id in Array.vals(query_result.ids)) {
//          buffer.add(Nat.toText(id) # ", ");
//        };
//        buffer.add("], next = ");
//        switch(query_result.next_id){
//          case(null){ buffer.add("null"); };
//          case(?id) { buffer.add(Nat.toText(id)); };
//        };
//        Text.join("", buffer.vals());
//      };
//      equals = func (qr1: QueryQuestionsResult, qr2: QueryQuestionsResult) : Bool { 
//        let equal_ids = Array.equal(qr1.ids, qr2.ids, func(id1: Nat, id2: Nat) : Bool {
//          Nat.equal(id1, id2);
//        });
//        let equal_next = switch(qr1.next_id) {
//          case(null) { 
//            switch(qr2.next_id) {
//              case(null) { true };
//              case(_) { false; };
//            };
//          };
//          case(?next_id1) {
//            switch(qr2.next_id) {
//              case(null) { false };
//              case(?next_id2) { Nat.equal(next_id1, next_id2); };
//            };
//          };
//        };
//        equal_ids and equal_next;
//      };
//      item = query_result;
//    };
//  };

};