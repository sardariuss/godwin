import Types "../../src/godwin_backend/types";
import Convictions "../../src/godwin_backend/convictions";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Array "mo:base/Array";

class TestConvictions() = {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types module
  type AgreementDegree = Types.AgreementDegree;
  type Opinion = Types.Opinion;
  type Conviction = Types.Conviction;
  type Direction = Types.Direction;
  type Category = Types.Category;
  type OrientedCategory = Types.OrientedCategory;
  type ArrayConvictions = Types.ArrayConvictions;
  type CategoryConviction = Types.CategoryConviction;

  let moderate_coef = 0.5;

  func testableArrayConvictions(arrayConvictions: ArrayConvictions) : Testable.TestableItem<ArrayConvictions> {
    {
      display = func (arrayConvictions: ArrayConvictions) : Text = "The two arrays are not equal";
      equals = func (a1: ArrayConvictions, a2: ArrayConvictions) : Bool { 
        Array.equal(a1, a2, func(a1: CategoryConviction, a2: CategoryConviction) : Bool {
          Text.equal(a1.category, a2.category) and a1.conviction == a2.conviction;
        });
      };
      item = arrayConvictions;
    };
  };

  func testAddConvictions() : Testable.TestableItem<ArrayConvictions> {
    var trie = Trie.empty<Category, Conviction>();
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    testableArrayConvictions(Convictions.toArray(trie));
  };

  public let suiteAddConviction = suite("addConvictions", [
    test("addConvictions", [{ category = "IDENTITY"; conviction = { left = 3.0; center = 0.0; right = 0.0; }}], Matchers.equals(testAddConvictions()))
  ]);

};