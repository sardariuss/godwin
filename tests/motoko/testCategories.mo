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
type Dimension = Types.Dimension;
type Sides = Types.Sides;
type Category = Types.Category;
type CategoryAggregationParameters = Types.CategoryAggregationParameters;

type VerifyCategoryError = {
  #CategoryNotFound;
};

var political_categories = Trie.empty<Dimension, Sides>();
political_categories := Trie.put(political_categories, Types.keyText("IDENTITY"), Text.equal, ("CONSTRUCTIVISM", "ESSENTIALISM")).0;
political_categories := Trie.put(political_categories, Types.keyText("COOPERATION"), Text.equal, ("INTERNATIONALISM", "NATIONALISM")).0;
political_categories := Trie.put(political_categories, Types.keyText("PROPERTY"), Text.equal, ("COMMUNISM", "CAPITALISM")).0;

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

type TestableVerifyCategory = Testable.TestableItem<Result<(), VerifyCategoryError>>;

func testVerifyCategory(political_categories: Trie<Dimension, Sides>, category: Category) : TestableVerifyCategory {
  testableResult<(), VerifyCategoryError>(Categories.verifyCategory(political_categories, category));
};

let suiteCategories = suite("Categories", [
  test("Category exists (1)", #ok, Matchers.equals(testVerifyCategory(political_categories,{ dimension = "IDENTITY"; direction = #LR; }))),
  test("Category exists (2)", #ok, Matchers.equals(testVerifyCategory(political_categories,{ dimension = "IDENTITY"; direction = #RL; }))),
  test("Category does not exist (1)", #err(#CategoryNotFound), Matchers.equals(testVerifyCategory(political_categories,{ dimension = "JUSTICE"; direction = #LR; }))),
  test("Category does not exist (2)", #err(#CategoryNotFound), Matchers.equals(testVerifyCategory(political_categories,{ dimension = "JUSTICE"; direction = #RL; })))
]);

run(suiteCategories);