import PayRules                "../../src/godwin_sub/model/PayRules";
import UtilsTypes              "../../src/godwin_sub/utils/Types";

import { test; suite; }        "mo:test";

import Array                   "mo:base/Array";
import Option                  "mo:base/Option";

import { compare; optionalTestify; Testify; } = "common/Testify";

import Debug                   "mo:base/Debug";
import Float                   "mo:base/Float";

suite("Pay rules module test suite", func() {

  type Duration = UtilsTypes.Duration;

  test("Test computing the interest distribution", func () {

    // Uncomment this test shall trap
//  test("Computing interest distribution with 0 votes shall trap", func() {
//    ignore PayRules.computeInterestDistribution({ ups = 0; downs = 0; });
//  });

    let equal = Testify.interestDistribution.equal;

    test("Computing interest distribution with only up votes shall return 100% of up shares, 0% reward ratio", func() {
      compare(PayRules.computeInterestDistribution({ ups = 1;  downs = 0; }), { shares = { up = 1.0;        down = 0.0; }; reward_ratio = 0.0; }, equal);
      compare(PayRules.computeInterestDistribution({ ups = 92; downs = 0; }), { shares = { up = 1.0 / 92.0; down = 0.0; }; reward_ratio = 0.0; }, equal);
      compare(PayRules.computeInterestDistribution({ ups = 82; downs = 0; }), { shares = { up = 1.0 / 82.0; down = 0.0; }; reward_ratio = 0.0; }, equal);
      compare(PayRules.computeInterestDistribution({ ups = 18; downs = 0; }), { shares = { up = 1.0 / 18.0; down = 0.0; }; reward_ratio = 0.0; }, equal);
    });

    test("Computing interest distribution with only down votes shall return 100% of down shares, 0% reward ratio", func() {
      compare(PayRules.computeInterestDistribution({ ups = 0; downs = 1;  }), { shares = { up = 0.0; down = 1.0;        }; reward_ratio = 0.0; }, equal);
      compare(PayRules.computeInterestDistribution({ ups = 0; downs = 86; }), { shares = { up = 0.0; down = 1.0 / 86.0; }; reward_ratio = 0.0; }, equal);
      compare(PayRules.computeInterestDistribution({ ups = 0; downs = 15; }), { shares = { up = 0.0; down = 1.0 / 15.0; }; reward_ratio = 0.0; }, equal);
      compare(PayRules.computeInterestDistribution({ ups = 0; downs = 67; }), { shares = { up = 0.0; down = 1.0 / 67.0; }; reward_ratio = 0.0; }, equal);
    });

    test("The share of the loosers shall always be smaller than the share of the winners: 12 up VS 11 downs", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 12; downs = 11; }).shares;
      Debug.print("up: " # Float.toText(up) # " down: " # Float.toText(down));
      compare(up, down, Testify.float.greaterThan);
    });

    test("The share of the loosers shall always be smaller than the share of the winners: 54 ups VS 5 downs", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 52; downs = 5; }).shares;
      // 5 / 52 < 0.10, so the share of the winner shall at least be greater than 10 times the share of the loosers
      compare(up, 10 * down, Testify.float.greaterThan);
    });

    test("The share of the loosers shall always be smaller than the share of the winners: 3 ups VS 11 downs", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 3; downs = 11; }).shares;
      compare(up, down, Testify.float.lessThan);
    });

    test("The share of the loosers shall always be smaller than the share of the winners: 64 ups VS 764 downs", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 64; downs = 764; }).shares;
      compare(up, down, Testify.float.lessThan);
    });

    test("Expected values for a majority of two thirds to one", func() {
      let { up; down; } = PayRules.computeInterestDistribution({ ups = 666_666; downs = 333_333; }).shares;
      compare(up,  1.25 / Float.fromInt(999_999), Testify.float.equal);
      compare(down, 0.5 / Float.fromInt(999_999),  Testify.float.equal);
    });

    test("The maximum winning distribution share shall be for a majority of two thirds to one", func() {
      let d1 = PayRules.computeInterestDistribution({ ups = 666_667; downs = 333_333; }).shares;
      let d2 = PayRules.computeInterestDistribution({ ups = 666_666; downs = 333_334; }).shares;
      let d3 = PayRules.computeInterestDistribution({ ups = 666_668; downs = 333_332; }).shares;
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
      ({ ups = 80; downs = 20;  }, { shares = { up = (1.0 + 0.1875) / 100.0; down = (1.0 - 0.75)   / 100.0; }; reward_ratio = 0.69445116006; }),
      ({ ups = 59; downs = 100; }, { shares = { up = (1.0 - 0.41)   / 159.0; down = (1.0 + 0.2419) / 159.0; }; reward_ratio = 1.71911336949; }),
    ];

    test("Test some values", func() {
      for ((input, expected) in Array.vals(distribution_values)) {
        compare(PayRules.computeInterestDistribution(input), expected, equal);
      };
    });
  });

  test("Test computation of opened question payout", func () {

    test("Test payout when the question has been censored", func () {
      compare(
        PayRules.computeQuestionAuthorPayout(#CENSORED, { score = 0.0; }),
        { refund_share = 0.0; reward = null; },
        Testify.rawPayout.equal
      );
    });

    test("Test payout when the question has timed-out", func () {
      compare(
        PayRules.computeQuestionAuthorPayout(#TIMED_OUT, { score = 0.0; }),
        { refund_share = 1.0; reward = null; },
        Testify.rawPayout.equal
      );
    });

    // Uncomment this test shall trap
//    test("Test payout below with a null or negative score shall trap", func() {
//      compare(
//        PayRules.computeQuestionAuthorPayout(#SELECTED, { score = 0.0; }),
//        { refund_share = 1.0; reward = ?0.0; },
//        Testify.rawPayout.equal
//      );
//    });

    test("Test few payouts when the question has been selected", func () {
      compare(
        PayRules.computeQuestionAuthorPayout(#SELECTED, {score = 1.0}),
        { refund_share = 1.0; reward = ?1.0; }, // sqrt(1) = 1
        Testify.rawPayout.equal
      );
      compare(
        PayRules.computeQuestionAuthorPayout(#SELECTED, {score = 9.0}), 
        { refund_share = 1.0; reward = ?3.0; }, // sqrt(9) = 3
        Testify.rawPayout.equal
      );
      compare(
        PayRules.computeQuestionAuthorPayout(#SELECTED, {score = 4.0}), 
        { refund_share = 1.0; reward = ?2.0; }, // sqrt(4) = 2
        Testify.rawPayout.equal
      );
      compare(
        PayRules.computeQuestionAuthorPayout(#SELECTED, {score = 144.0}), 
        { refund_share = 1.0; reward = ?12.0; }, // sqrt(144) = 12
        Testify.rawPayout.equal
      );
    });

  // @todo: To reactivate when the ratio is not hardcoded
//    test("Test that if the author's reward is null, the creator's reward is also null", func () {
//      for(ratio in Array.vals([0.1, 0.5, 0.9])) {
//        compare(
//          PayRules.deduceSubCreatorReward(ratio, { refund_share = 1.0; reward = null; }),
//          null,
//          optionalTestify(Testify.nat.equal));
//      };
//    });
//    test("Test that if the author's reward is not null, the creator get the right ratio of it", func () {
//      compare(
//        PayRules.deduceSubCreatorReward(0.1, { refund_share = 1.0; reward_tokens = 0.1; }),
//        ?0.01,
//        optionalTestify(Testify.nat.equal));
//      compare(
//        PayRules.deduceSubCreatorReward(0.25, { refund_share = 1.0; reward_tokens = 0.2; }),
//        ?0.05,
//        optionalTestify(Testify.nat.equal));
//      compare(
//        PayRules.deduceSubCreatorReward(0.5, { refund_share = 1.0; reward_tokens = 0.666; }),
//        ?0.333,
//        optionalTestify(Testify.nat.equal));
//    });

  });

  test("Test computation of interest vote question payout", func () {
   
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
          PayRules.computeInterestVotePayout({ shares; reward_ratio = 0.0; }, #UP),
          { refund_share = shares.up; reward = null; },
          Testify.rawPayout.equal
        );
        compare(
          PayRules.computeInterestVotePayout({ shares; reward_ratio = 0.0; }, #DOWN),
          { refund_share = shares.down; reward = null; },
          Testify.rawPayout.equal
        );
      };
    });

    test("Test that if the distribution reward is not 0, the voter gets a reward and the corresponding share", func () {
      for (shares in Array.vals(shares_array)){
        for (reward_ratio in Array.vals(reward_ratios)){
          do {
            let { refund_share; reward; } = PayRules.computeInterestVotePayout({ shares; reward_ratio; }, #UP);
            compare(refund_share, shares.up, Testify.float.equal);
            assert(Option.isSome(reward));
          }; 
          do {
            let { refund_share; reward; } = PayRules.computeInterestVotePayout({ shares; reward_ratio; }, #DOWN);
            compare(refund_share, shares.down, Testify.float.equal);
            assert(Option.isSome(reward));
          }; 
        };
      };
    });
  });

  // @todo: categorization payout
  // @todo: attenuation computation

});