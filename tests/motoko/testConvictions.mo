import Types "../../src/godwin_backend/types";
import Convictions "../../src/godwin_backend/convictions";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Float "mo:base/Float";

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
      display = func (arrayConvictions: ArrayConvictions) : Text {
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (item in Array.vals(arrayConvictions)) {
          buffer.add(item.category 
            # ": (" # Float.toText(item.conviction.left) 
            # ", " # Float.toText(item.conviction.center) 
            # ", " # Float.toText(item.conviction.right) 
            # ") - ");
        };
        Text.join("", buffer.vals());
      };
      equals = func (a1: ArrayConvictions, a2: ArrayConvictions) : Bool { 
        Array.equal(a1, a2, func(a1: CategoryConviction, a2: CategoryConviction) : Bool {
          Text.equal(a1.category, a2.category) and a1.conviction == a2.conviction;
        });
      };
      item = arrayConvictions;
    };
  };

  // Same number of abs agree on both direction
  func addConvictions1() : Testable.TestableItem<ArrayConvictions> {
    var trie = Trie.empty<Category, Conviction>();
    // Identity shall result in left = 3 center = 0 and right = 3
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #RL; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #RL; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #RL; }, #AGREE(#ABSOLUTE), moderate_coef);
    testableArrayConvictions(Convictions.toArray(trie));
  };

  // Same number of abs agree and abs disagree in same direction
  func addConvictions2() : Testable.TestableItem<ArrayConvictions> {
    var trie = Trie.empty<Category, Conviction>();
    // Identity shall result in left = 3 center = 0 and right = 3
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #DISAGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #DISAGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #DISAGREE(#ABSOLUTE), moderate_coef);
    testableArrayConvictions(Convictions.toArray(trie));
  };

  // Same number of moderate agree on both direction
  func addConvictions3() : Testable.TestableItem<ArrayConvictions> {
    var trie = Trie.empty<Category, Conviction>();
    // Identity shall result in left = 1.5 center = 3 and right = 1.5
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #RL; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #RL; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #RL; }, #AGREE(#MODERATE), moderate_coef);
    testableArrayConvictions(Convictions.toArray(trie));
  };

  // Same number of MODERATE agree and abs disagree in same direction
  func addConvictions4() : Testable.TestableItem<ArrayConvictions> {
    var trie = Trie.empty<Category, Conviction>();
    // Identity shall result in left = 1.5 center = 3 and right = 1.5
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #DISAGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #DISAGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #DISAGREE(#MODERATE), moderate_coef);
    testableArrayConvictions(Convictions.toArray(trie));
  };

  // Random mix
  func addConvictions5() : Testable.TestableItem<ArrayConvictions> {
    var trie = Trie.empty<Category, Conviction>();
    // Identity shall result in left = 2.5 center = 3.5 and right = 1.0
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #AGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #NEUTRAL, moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #NEUTRAL, moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #DISAGREE(#MODERATE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "IDENTITY"; direction = #LR; }, #DISAGREE(#MODERATE), moderate_coef);
    // Cooperation shall result in left = 0.0 center = 1.0 and right = 1.0
    trie := Convictions.addConviction(trie, { category = "COOPERATION"; direction = #RL; }, #NEUTRAL, moderate_coef);
    trie := Convictions.addConviction(trie, { category = "COOPERATION"; direction = #LR; }, #DISAGREE(#ABSOLUTE), moderate_coef);
    // Property shall result in left = 1.5 center = 1.5 and right = 0.0
    trie := Convictions.addConviction(trie, { category = "PROPERTY"; direction = #LR; }, #AGREE(#ABSOLUTE), moderate_coef);
    trie := Convictions.addConviction(trie, { category = "PROPERTY"; direction = #RL; }, #NEUTRAL, moderate_coef);
    trie := Convictions.addConviction(trie, { category = "PROPERTY"; direction = #RL; }, #DISAGREE(#MODERATE), moderate_coef);
    testableArrayConvictions(Convictions.toArray(trie));
  };

  public let suiteAddConviction = suite("addConvictions", [
    test("addConvictions1", [{ category = "IDENTITY"; conviction = { left = 3.0; center = 0.0; right = 3.0; }}], Matchers.equals(addConvictions1())),
    test("addConvictions2", [{ category = "IDENTITY"; conviction = { left = 3.0; center = 0.0; right = 3.0; }}], Matchers.equals(addConvictions2())),
    test("addConvictions3", [{ category = "IDENTITY"; conviction = { left = 1.5; center = 3.0; right = 1.5; }}], Matchers.equals(addConvictions3())),
    test("addConvictions4", [{ category = "IDENTITY"; conviction = { left = 1.5; center = 3.0; right = 1.5; }}], Matchers.equals(addConvictions4())),
    test("addConvictions5", [
      { category = "IDENTITY"; conviction = { left = 2.5; center = 3.5; right = 1.0; }},
      { category = "COOPERATION"; conviction = { left = 0.0; center = 1.0; right = 1.0; }},
      { category = "PROPERTY"; conviction = { left = 1.5; center = 1.5; right = 0.0; }}], Matchers.equals(addConvictions5())),
  ]);

};