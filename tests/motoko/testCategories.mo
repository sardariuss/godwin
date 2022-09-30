import Categories "../../src/godwin_backend/categories";
import Types "../../src/godwin_backend/types";
import Votes "../../src/godwin_backend/votes";
import Utils "../../src/godwin_backend/utils";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";

class TestCategories() = {

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
  type CategoriesDefinition = Types.CategoriesDefinition;
  type VoteRegister<B> = Types.VoteRegister<B>;

  type VerifyOrientedCategoryError = {
    #CategoryNotFound;
  };

  let principal_0 = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe");
  let principal_1 = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae");
  let principal_2 = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe");
  let principal_3 = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe");
  let principal_4 = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae");
  let principal_5 = Principal.fromText("lejdd-efwn5-h3qqe-4bunw-faabt-qwb7j-oiskz-c3dkg-3q5z5-ozrtn-dqe");
  let principal_6 = Principal.fromText("amerw-mz3nq-gfkbp-o3qgo-zldsl-upilh-zatjw-66nkr-527cf-m7hnq-pae");
  let principal_7 = Principal.fromText("gbvlf-igtmq-g5vs2-skrhr-txgij-4f2j3-v2jqy-re5cm-i6hsu-gpzcd-aae");
  let principal_8 = Principal.fromText("mrdr7-aufxf-oiq6j-hyib2-rxb5m-cqrnb-uzgyq-durnt-75u4x-rrvow-iae");
  let principal_9 = Principal.fromText("zoyw4-o2dcy-xajcf-e2nvu-436rg-ghrbs-35bzk-nakpb-mvs7t-x4byt-nqe");

  let definitions = [
    { category = "IDENTITY"; sides = { left = "CONSTRUCTIVISM"; right = "ESSENTIALISM"; } },
    { category = "COOPERATION"; sides = { left = "INTERNATIONALISM"; right = "NATIONALISM"; } },
    { category = "PROPERTY"; sides = { left = "COMMUNISM"; right = "CAPITALISM"; } }
  ];

  let aggregation_params = { direction_threshold = 0.65; category_threshold = 0.35; };

  func testableResult<Ok, Err>(result: Result<Ok, Err>) : Testable.TestableItem<Result<Ok, Err>> {
    {
      display = func (result: Result<Ok, Err>) : Text {
        switch(result){
          case(#ok(_)){"Ok";};
          case(#err(_)){"Err";};
        };
      };
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

  func testVerifyOrientedCategory(definitions: CategoriesDefinition, category: OrientedCategory) : TestableVerifyOrientedCategory {
    testableResult<(), VerifyOrientedCategoryError>(Utils.verifyOrientedCategory(definitions, category));
  };

  func testableAggregation(aggregation: [OrientedCategory]) : Testable.TestableItem<[OrientedCategory]> {
    {
      display = func (aggregation: [OrientedCategory]) : Text {
        var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(0);
        for (item in Array.vals(aggregation)) {
          buffer.add(item.category # ": ");
          switch(item.direction){
            case(#LR) { buffer.add("LR"); };
            case(#RL) { buffer.add("RL"); };
          };
          buffer.add(" - ");
        };
        Text.join("", buffer.vals());
      };
      equals = func (a1: [OrientedCategory], a2: [OrientedCategory]) : Bool { 
        Array.equal(a1, a2, func(a1: OrientedCategory, a2: OrientedCategory) : Bool {
          Text.equal(a1.category, a2.category) and a1.direction == a2.direction;
        });
      };
      item = aggregation;
    };
  };

  func testAggregationNoWinner(definitions: CategoriesDefinition, aggregation_params: AggregationParameters) : Testable.TestableItem<[OrientedCategory]> {
    var categories = Votes.empty<OrientedCategory>();
    categories := Votes.putBallot(categories, principal_0, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_1, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_2, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_3, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_4, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_5, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_6, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "COOPERATION"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_7, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "COOPERATION"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_8, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "PROPERTY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_9, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "PROPERTY"; direction = #RL; }).0;
    let aggregation = Categories.computeQuestionProfile(definitions, aggregation_params, categories, 0);
    testableAggregation(aggregation);
  };

  func testAggregationSingleWinner(definitions: CategoriesDefinition, aggregation_params: AggregationParameters) : Testable.TestableItem<[OrientedCategory]> {
    var categories = Votes.empty<OrientedCategory>();
    categories := Votes.putBallot(categories, principal_0, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_1, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_2, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_3, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_4, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_5, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_6, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "COOPERATION"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_7, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "COOPERATION"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_8, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "PROPERTY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_9, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "PROPERTY"; direction = #RL; }).0;
    let aggregation = Categories.computeQuestionProfile(definitions, aggregation_params, categories, 0);
    testableAggregation(aggregation);
  };

  func testAggregationTwoWinners(definitions: CategoriesDefinition, aggregation_params: AggregationParameters) : Testable.TestableItem<[OrientedCategory]> {
    var categories = Votes.empty<OrientedCategory>();
    categories := Votes.putBallot(categories, principal_0, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_1, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_2, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_3, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #LR; }).0;
    categories := Votes.putBallot(categories, principal_4, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_5, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "IDENTITY"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_6, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "COOPERATION"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_7, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "COOPERATION"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_8, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "COOPERATION"; direction = #RL; }).0;
    categories := Votes.putBallot(categories, principal_9, 0, Types.hashOrientedCategory, Types.equalOrientedCategory, { category = "COOPERATION"; direction = #LR; }).0;
    let aggregation = Categories.computeQuestionProfile(definitions, aggregation_params, categories, 0);
    testableAggregation(aggregation);
  };

  public let suiteVerifyOrientedCategory = suite("VerifyOrientedCategory", [
    test("OrientedCategory exists (1)", #ok, Matchers.equals(testVerifyOrientedCategory(definitions,{ category = "IDENTITY"; direction = #LR; }))),
    test("OrientedCategory exists (2)", #ok, Matchers.equals(testVerifyOrientedCategory(definitions,{ category = "IDENTITY"; direction = #RL; }))),
    test("OrientedCategory does not exist (1)", #err(#CategoryNotFound), Matchers.equals(testVerifyOrientedCategory(definitions,{ category = "JUSTICE"; direction = #LR; }))),
    test("OrientedCategory does not exist (2)", #err(#CategoryNotFound), Matchers.equals(testVerifyOrientedCategory(definitions,{ category = "JUSTICE"; direction = #RL; })))
  ]);

  public let suiteComputeCategoriesAggregation = suite("computeQuestionProfile", [
    test("no winner", [], Matchers.equals(testAggregationNoWinner(definitions, aggregation_params))),
    test("single winner", [{ category = "IDENTITY"; direction = #LR; }], Matchers.equals(testAggregationSingleWinner(definitions, aggregation_params))),
    test("two winners", [{ category = "IDENTITY"; direction = #LR; }, { category = "COOPERATION"; direction = #RL; }], Matchers.equals(testAggregationTwoWinners(definitions, aggregation_params)))
  ]);

};
