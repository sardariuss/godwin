import Cursor "../../src/godwin_backend/representation/cursor";
import Polarization "../../src/godwin_backend/representation/polarization";
import CategoryCursorTrie "../../src/godwin_backend/representation/categoryCursorTrie";
import CategoryPolarizationTrie "../../src/godwin_backend/representation/categoryPolarizationTrie";
import Question "../../src/godwin_backend/questions/question";
import Types "../../src/godwin_backend/types";

import Testable "mo:matchers/Testable";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;

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

  public func optCategoryCursorTrie(cursor_trie: ?CategoryCursorTrie) : Testable.TestableItem<?CategoryCursorTrie> {
    testOptItem(cursor_trie, CategoryCursorTrie.toText, CategoryCursorTrie.equal);
  };

  public func categoryPolarizationTrie(polarization_trie: CategoryPolarizationTrie) : Testable.TestableItem<CategoryPolarizationTrie> {
    {
      display = CategoryPolarizationTrie.toText;
      equals = CategoryPolarizationTrie.equal;
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

};