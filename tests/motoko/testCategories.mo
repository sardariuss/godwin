import Categories "../../src/godwin_backend/categories";
import Types "../../src/godwin_backend/types";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Result "mo:base/Result";

// For convenience: from base module
type Trie<K, V> = Trie.Trie<K, V>;
type Result<Ok, Err> = Result.Result<Ok, Err>;
// For convenience: from matchers module
let { run;test;suite; } = Suite;
// For convenience: from types module
type Category = Types.Category;
type Sides = Types.Sides;
type OrientedCategory = Types.OrientedCategory;
type AggregationParameters = Types.AggregationParameters;

type VerifyOrientedCategoryError = {
  #CategoryNotFound;
};

var political_categories = Trie.empty<Category, Sides>();
political_categories := Trie.put(political_categories, Types.keyText("IDENTITY"), Text.equal, { left = "CONSTRUCTIVISM"; right = "ESSENTIALISM"; }).0;
political_categories := Trie.put(political_categories, Types.keyText("COOPERATION"), Text.equal, { left = "INTERNATIONALISM"; right = "NATIONALISM"; }).0;
political_categories := Trie.put(political_categories, Types.keyText("PROPERTY"), Text.equal, { left = "COMMUNISM"; right = "CAPITALISM"; }).0;

func testableResult<Ok, Err>(result: Result<Ok, Err>) : Testable.TestableItem<Result<Ok, Err>> {
  {
    display = func (result: Result<Ok, Err>) : Text = "@todo";
    equals = func (r1: Result<Ok, Err>, r2: Result<Ok, Err>) : Bool { Result.equal(
      func(ok1: Ok, ok2: Ok) : Bool { return true; },
      func(err1: Err, err2: Err) : Bool { return true; },
      r1,
      r2
    );};
    item = result;
  };
};

type TestableVerifyOrientedCategory = Testable.TestableItem<Result<(), VerifyOrientedCategoryError>>;

func testVerifyOrientedCategory(political_categories: Trie<Category, Sides>, category: OrientedCategory) : TestableVerifyOrientedCategory {
  testableResult<(), VerifyOrientedCategoryError>(Categories.verifyOrientedCategory(political_categories, category));
};

let suiteCategories = suite("Categories", [
  test("OrientedCategory exists (1)", #ok, Matchers.equals(testVerifyOrientedCategory(political_categories,{ category = "IDENTITY"; direction = #LR; }))),
  test("OrientedCategory exists (2)", #ok, Matchers.equals(testVerifyOrientedCategory(political_categories,{ category = "IDENTITY"; direction = #RL; }))),
  test("OrientedCategory does not exist (1)", #err(#CategoryNotFound), Matchers.equals(testVerifyOrientedCategory(political_categories,{ category = "JUSTICE"; direction = #LR; }))),
  test("OrientedCategory does not exist (2)", #err(#CategoryNotFound), Matchers.equals(testVerifyOrientedCategory(political_categories,{ category = "JUSTICE"; direction = #RL; })))
]);

run(suiteCategories);