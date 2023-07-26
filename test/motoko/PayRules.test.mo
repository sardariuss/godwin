import PayRules                "../../src/godwin_sub/model/PayRules";

import { compare; Testify; } = "common/Testify";

import { test; suite; }        "mo:test";

import Array                   "mo:base/Array";

suite("Pay rules module test suite", func() {

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

});