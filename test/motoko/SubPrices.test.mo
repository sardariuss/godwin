import SubPrices        "../../src/godwin_sub/model/SubPrices";

import { test; suite; } "mo:test";

import Array            "mo:base/Array";

import { compare; optionalTestify; Testify; } = "common/Testify";

suite("Sub prices module test suite", func() {

  test("Test computing sub prices", func () {
    let test_sub_prices = [
      (
        { base_selection_period = #HOURS(30); open_vote_price_e9s = 900; reopen_vote_price_e9s = 300; interest_vote_price_e9s = 60; categorization_vote_price_e9s = 150; },
        { selection_period = #MINUTES(600); minimum_score = 1.0; }, // Minimum score is irrelevant for this test
        { open_vote_price_e9s = 300; reopen_vote_price_e9s = 100; interest_vote_price_e9s = 20; categorization_vote_price_e9s = 50; },
      ),
      (
        { base_selection_period = #DAYS(1); open_vote_price_e9s = 500; reopen_vote_price_e9s = 300; interest_vote_price_e9s = 200; categorization_vote_price_e9s = 200; },
        { selection_period = #DAYS(5); minimum_score = 1.0; }, // Minimum score is irrelevant for this test
        { open_vote_price_e9s = 2500; reopen_vote_price_e9s = 1500; interest_vote_price_e9s = 1000; categorization_vote_price_e9s = 1000; },
      )
    ];

    for ((base_price_params, selection_params, expected_price_register) in Array.vals(test_sub_prices)) {
      compare(SubPrices.computeSubPrices(base_price_params, selection_params), expected_price_register, Testify.priceRegister.equal);
    };
  });

});