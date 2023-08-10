import PayRules                "../../src/godwin_sub/model/PayRules";
import UtilsTypes              "../../src/godwin_sub/utils/Types";

import { test; suite; }        "mo:test";

import Array                   "mo:base/Array";
import Option                  "mo:base/Option";

import { compare; optionalTestify; Testify; } = "common/Testify";

suite("Pay rules module test suite", func() {

  type Duration = UtilsTypes.Duration;

  test("Test computing the interest distribution", func () {

    // Uncomment this test shall trap
//  test("Computing interest distribution with 0 votes shall trap", func() {
//    ignore PayRules.computeInterestDistribution({ ups = 0; downs = 0; });
//  });

    test("Computing interest distribution with only up votes shall return 100% of up shares, 0% reward ratio", func() {
      let expected_distribution = { shares = { up = 1.0; down = 0.0; }; reward_ratio = 0.0; };
      compare(PayRules.computeInterestDistribution({ ups = 1;  downs = 0; }), expected_distribution, Testify.interestDistribution.equal);
      compare(PayRules.computeInterestDistribution({ ups = 92; downs = 0; }), expected_distribution, Testify.interestDistribution.equal);
      compare(PayRules.computeInterestDistribution({ ups = 82; downs = 0; }), expected_distribution, Testify.interestDistribution.equal);
      compare(PayRules.computeInterestDistribution({ ups = 18; downs = 0; }), expected_distribution, Testify.interestDistribution.equal);
    });

    test("Computing interest distribution with only down votes shall return 100% of down shares, 0% reward ratio", func() {
      let expected_distribution = { shares = { up = 0.0; down = 1.0; }; reward_ratio = 0.0; };
      compare(PayRules.computeInterestDistribution({ ups = 0; downs = 1;  }), expected_distribution, Testify.interestDistribution.equal);
      compare(PayRules.computeInterestDistribution({ ups = 0; downs = 86; }), expected_distribution, Testify.interestDistribution.equal);
      compare(PayRules.computeInterestDistribution({ ups = 0; downs = 15; }), expected_distribution, Testify.interestDistribution.equal);
      compare(PayRules.computeInterestDistribution({ ups = 0; downs = 67; }), expected_distribution, Testify.interestDistribution.equal);
    });

    test("The share of the loosers shall always be smaller than 1, the share of the winners shall always be greater than 1: 12 up VS 11 downs", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 12; downs = 11; }).shares;
      compare(down, 1.0, Testify.float.lessThan);
      compare(up,   1.0, Testify.float.greaterThan);
    });

    test("The share of the loosers shall always be smaller than 1, the share of the winners shall always be greater than 1: 54 ups VS 5 downs", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 54; downs = 5; }).shares;
      compare(down, 1.0, Testify.float.lessThan);
      compare(up,   1.0, Testify.float.greaterThan);
    });

    test("The share of the loosers shall always be smaller than 1, the share of the winners shall always be greater than 1: 3 ups VS 11 downs", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 3; downs = 11; }).shares;
      compare(down, 1.0, Testify.float.greaterThan);
      compare(up,   1.0, Testify.float.lessThan);
    });

    test("The share of the loosers shall always be smaller than 1, the share of the winners shall always be greater than 1: 64 ups VS 764 downs", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 64; downs = 764; }).shares;
      compare(down, 1.0, Testify.float.greaterThan);
      compare(up,   1.0, Testify.float.lessThan);
    });

    test("The maximum distribution share shall be for a majority of two thirds to one", func() {
      let d1 = PayRules.computeInterestDistribution({ ups = 67; downs = 33; }).shares;
      let d2 = PayRules.computeInterestDistribution({ ups = 66; downs = 34; }).shares;
      let d3 = PayRules.computeInterestDistribution({ ups = 68; downs = 32; }).shares;
      compare(d1.up, d2.up, Testify.float.greaterThan);
      compare(d1.up, d3.up, Testify.float.greaterThan);
    });

    test("The maximum reward ratio shall be for an even vote", func() {
      let d1 = PayRules.computeInterestDistribution({ ups = 50; downs = 50; }).reward_ratio;
      let d2 = PayRules.computeInterestDistribution({ ups = 51; downs = 49; }).reward_ratio;
      let d3 = PayRules.computeInterestDistribution({ ups = 49; downs = 51; }).reward_ratio;
      compare(d1, d2, Testify.float.greaterThan);
      compare(d1, d3, Testify.float.greaterThan);
    });

    // Obtained via www.desmos.com/calculator/lejulppdny
    let distribution_values = [
      ({ ups = 80; downs = 20;  }, { shares = { up = 1.0 + 0.1875; down = 1.0 - 0.75;   }; reward_ratio = 0.69445116006; }),
      ({ ups = 59; downs = 100; }, { shares = { up = 1.0 - 0.41;   down = 1.0 + 0.2419; }; reward_ratio = 1.71911336949; }),
    ];

    test("Test some values", func() {
      for ((input, expected) in Array.vals(distribution_values)) {
        compare(PayRules.computeInterestDistribution(input), expected, Testify.interestDistribution.equal);
      };
    });
  });

  test("Test computing sub prices", func () {
    let test_sub_prices = [
      (
        { base_selection_period = #HOURS(30); open_vote_price_e8s = 900; reopen_vote_price_e8s = 300; interest_vote_price_e8s = 60; categorization_vote_price_e8s = 150; },
        { selection_period = #MINUTES(600); minimum_score = 1.0; }, // Minimum score is irrelevant for this test
        { open_vote_price_e8s = 300; reopen_vote_price_e8s = 100; interest_vote_price_e8s = 20; categorization_vote_price_e8s = 50; },
      ),
      (
        { base_selection_period = #DAYS(1); open_vote_price_e8s = 500; reopen_vote_price_e8s = 300; interest_vote_price_e8s = 200; categorization_vote_price_e8s = 200; },
        { selection_period = #DAYS(5); minimum_score = 1.0; }, // Minimum score is irrelevant for this test
        { open_vote_price_e8s = 2500; reopen_vote_price_e8s = 1500; interest_vote_price_e8s = 1000; categorization_vote_price_e8s = 1000; },
      )
    ];

    for ((base_price_params, selection_params, expected_price_register) in Array.vals(test_sub_prices)) {
      compare(PayRules.computeSubPrices(base_price_params, selection_params), expected_price_register, Testify.priceRegister.equal);
    };
  });

  test("Test computation of opened question payout", func () {

    let empty_appeal = { ups = 0; downs = 0; score = 0.0; negative_score_date = null; hot_timestamp = 0.0; hotness = 0.0; };
   
    let price_register = {
      open_vote_price_e8s           = 2000;
      reopen_vote_price_e8s         = 1000;
      interest_vote_price_e8s       = 100;
      categorization_vote_price_e8s = 300;
    };

    test("Test payout when the question has been censored", func () {
      for (iteration in Array.vals([0, 1, 2])) { // The iteration shall not matter
        compare(
          PayRules.computeQuestionAuthorPayout(price_register, #CENSORED, iteration),
          { refund_share = 0.0; reward_tokens = null; },
          Testify.payoutArgs.equal
        );
      };
    });

    test("Test payout when the question has timed-out", func () {
      for (iteration in Array.vals([0, 1, 2])) { // The iteration shall not matter
        compare(
          PayRules.computeQuestionAuthorPayout(price_register, #TIMED_OUT, iteration),
          { refund_share = 1.0; reward_tokens = null; },
          Testify.payoutArgs.equal
        );
      };
    });

    // Uncomment this test shall trap
//    test("Test payout below the minimum score shall trap", func() {
//      compare(
//        PayRules.computeQuestionAuthorPayout(price_register, #SELECTED({score = 0.0}), 0), // @todo: minimum score should not be a magic number
//        { refund_share = 1.0; reward_tokens = ?0; },
//        Testify.payoutArgs.equal
//      );
//    });

    test("Test payout when the question has been selected, but the score is the minimum", func () {
      for (iteration in Array.vals([0, 1, 2])) { // The iteration shall not matter
        compare(
          PayRules.computeQuestionAuthorPayout(price_register, #SELECTED({score = 1.0}), iteration), // @todo: minimum score should not be a magic number
          { refund_share = 1.0; reward_tokens = ?0; },
          Testify.payoutArgs.equal
        );
      };
    });

    test("Test few payouts when the question has been selected for the first iteration", func () {
      compare(
        PayRules.computeQuestionAuthorPayout(price_register, #SELECTED({score = 9.0}), 0), 
        { refund_share = 1.0; reward_tokens = ?4000; }, // ((sqrt(9) - 1 * 2000) = 2 * 2000 = 4000
        Testify.payoutArgs.equal
      );
      compare(
        PayRules.computeQuestionAuthorPayout(price_register, #SELECTED({score = 4.0}), 0), 
        { refund_share = 1.0; reward_tokens = ?2000; }, // ((sqrt(4) - 1 * 2000) = 1 * 2000 = 2000
        Testify.payoutArgs.equal
      );
      compare(
        PayRules.computeQuestionAuthorPayout(price_register, #SELECTED({score = 144.0}), 0), 
        { refund_share = 1.0; reward_tokens = ?22000; }, // ((sqrt(144) - 1 * 2000) = 11 * 2000 = 22000
        Testify.payoutArgs.equal
      );
    });

    test("Test few payouts when the question has been reopened", func () {
      for (iteration in Array.vals([1, 2, 3])) {
        compare(
          PayRules.computeQuestionAuthorPayout(price_register, #SELECTED({score = 9.0}), iteration), 
          { refund_share = 1.0; reward_tokens = ?2000; }, // ((sqrt(9) - 1 * 2000) = 2 * 1000 = 2000
          Testify.payoutArgs.equal
        );
        compare(
          PayRules.computeQuestionAuthorPayout(price_register, #SELECTED({score = 4.0}), iteration), 
          { refund_share = 1.0; reward_tokens = ?1000; }, // ((sqrt(4) - 1 * 2000) = 1 * 1000 = 1000
          Testify.payoutArgs.equal
        );
        compare(
          PayRules.computeQuestionAuthorPayout(price_register, #SELECTED({score = 144.0}), iteration), 
          { refund_share = 1.0; reward_tokens = ?11000; }, // ((sqrt(144) - 1 * 2000) = 11 * 1000 = 11000
          Testify.payoutArgs.equal
        );
      };
    });

    test("Test that if the author's reward is null, the creator's reward is also null", func () {
      for(ratio in Array.vals([0.1, 0.5, 0.9])) {
        compare(
          PayRules.computeQuestionCreatorReward(ratio, { refund_share = 1.0; reward_tokens = null; }),
          null,
          optionalTestify(Testify.nat.equal));
      };
    });
    
    test("Test that if the author's reward is not null, the creator get the right ratio of it", func () {
      compare(
        PayRules.computeQuestionCreatorReward(0.1, { refund_share = 1.0; reward_tokens = ?1000; }),
        ?100,
        optionalTestify(Testify.nat.equal));
      compare(
        PayRules.computeQuestionCreatorReward(0.25, { refund_share = 1.0; reward_tokens = ?200; }),
        ?50,
        optionalTestify(Testify.nat.equal));
      compare(
        PayRules.computeQuestionCreatorReward(0.5, { refund_share = 1.0; reward_tokens = ?666; }),
        ?333,
        optionalTestify(Testify.nat.equal));
    });

  });

  test("Test computation of interest vote question payout", func () {
   
    let price_register = {
      open_vote_price_e8s           = 2000;
      reopen_vote_price_e8s         = 1000;
      interest_vote_price_e8s       = 100;
      categorization_vote_price_e8s = 300;
    };

    let { coef; } = PayRules.INTEREST_PAYOUT_PARAMS.REWARD_PARAMS;

    let shares_array = [
      { up = 0.5; down = 0.5; },
      { up = 0.0; down = 1.0; },
      { up = 1.0; down = 0.0; },
      { up = 0.9909; down = 0.0091; },
      { up = 39.6656; down = 16.9354 }
    ];

    let reward_ratios = [0.1, 0.5, 0.9, 1.0];

    test("Test that if the distribution reward is 0, the voter gets a null reward and the corresponding share", func () {
      for (shares in Array.vals(shares_array)){
        compare(
          PayRules.computeInterestVotePayout(price_register, { shares; reward_ratio = 0.0; }, #UP),
          { refund_share = shares.up; reward_tokens = null; },
          Testify.payoutArgs.equal
        );
        compare(
          PayRules.computeInterestVotePayout(price_register, { shares; reward_ratio = 0.0; }, #DOWN),
          { refund_share = shares.down; reward_tokens = null; },
          Testify.payoutArgs.equal
        );
      };
    });

    test("Test that if the distribution reward is not 0, the voter gets a reward and the corresponding share", func () {
      for (shares in Array.vals(shares_array)){
        for (reward_ratio in Array.vals(reward_ratios)){
          do {
            let { refund_share; reward_tokens } = PayRules.computeInterestVotePayout(price_register, { shares; reward_ratio; }, #UP);
            compare(refund_share, shares.up, Testify.float.equal);
            assert(Option.isSome(reward_tokens));
          }; 
          do {
            let { refund_share; reward_tokens } = PayRules.computeInterestVotePayout(price_register, { shares; reward_ratio; }, #DOWN);
            compare(refund_share, shares.down, Testify.float.equal);
            assert(Option.isSome(reward_tokens));
          }; 
        };
      };
    });
  });

  // @todo: categorization payout
  // @todo: attenuation computation

});