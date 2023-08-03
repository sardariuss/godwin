import Math                    "../../src/godwin_sub/utils/Math";
import InterestRules           "../../src/godwin_sub/model/votes/InterestRules";

import { compare; Testify; } = "common/Testify";

import { test; suite; }        "mo:test";

import Array                   "mo:base/Array";
import Float                   "mo:base/Float";
import Iter                    "mo:base/Iter";
import Nat                     "mo:base/Nat";

suite("InterestRules module test suite", func() {

  let hotness_time_unit_ns : Nat = 86_400_000_000_000; // 24 hours in nanoseconds

  suite("Test computeScoreAndHotness with a fixed hot timestamp", func(){

    let hot_timestamp = InterestRules.computeHotTimestamp(1699958300000000000, hotness_time_unit_ns); // Some random timestamp

    test("0 votes shall result a score of 0, with a hotness equal to the timestamp", func() {
      let { score; hotness; } = InterestRules.computeScoreAndHotness(0, 0, hot_timestamp);
      compare(score,   0.0,           Testify.floatEpsilon6.equal);
      compare(hotness, hot_timestamp, Testify.floatEpsilon6.equal);
    });

    test("An equal number of up votes and down votes shall result a score of 0, and a hotness close to 0", func() {
      let { score; hotness; } = InterestRules.computeScoreAndHotness(42, 42, hot_timestamp);
      compare(score,   0.0,           Testify.floatEpsilon6.equal);
      // Hotness is not totally equal to the timestamp because the CDF is not exactly equal to 0 in x=0.5
      //compare(hotness, hot_timestamp, Testify.floatEpsilon3.equal); // @todo
    });

    test("Only down votes shall result in a positive score which absolute value is equal to the number of downvotes", func() {
      let { score; hotness; } = InterestRules.computeScoreAndHotness(100, 0, hot_timestamp);
      compare(score,   100.0,         Testify.floatEpsilon6.equal);
      compare(hotness, hot_timestamp, Testify.float.greaterThan);
    });

    test("Only down votes shall result in a negative score which absolute value is equal to the number of downvotes", func() {
      let { score; hotness; } = InterestRules.computeScoreAndHotness(0, 100, hot_timestamp);
      compare(score,   -100.0,        Testify.floatEpsilon6.equal);
      compare(hotness, hot_timestamp, Testify.float.lessThan);
    });

    test("The score shall be absolutly greater than the difference of ups and downs (1)", func() {
      let { score; hotness; } = InterestRules.computeScoreAndHotness(75, 50, hot_timestamp);
      // The score shall be absolutly greater than the diff, because with the logit effect the majority shall always win
      compare(score,   25.0,          Testify.float.greaterThan);
      compare(hotness, hot_timestamp, Testify.float.greaterThan);
    });

    test("The score shall be absolutly greater than the difference of ups and downs (2)", func() {
      let { score; hotness; } = InterestRules.computeScoreAndHotness(50, 25, hot_timestamp);
      // The score shall be absolutly greater than the diff, because with the logit effect the majority shall always win
      compare(score,   25.0,          Testify.float.greaterThan);
      compare(hotness, hot_timestamp, Testify.float.greaterThan);
    });

    test("The score shall be absolutly greater than the difference of ups and downs (3)", func() {
      let { score; hotness; } = InterestRules.computeScoreAndHotness(30, 31, hot_timestamp);
      compare(score,   -1.0,          Testify.float.lessThan);
      compare(hotness, hot_timestamp, Testify.float.lessThan);
    });

    test("The first 9 votes shall have the same weight as the next 99 votes ", func() {
      let hotness_1 = InterestRules.computeScoreAndHotness(9,    0, hot_timestamp).hotness;
      let hotness_2 = InterestRules.computeScoreAndHotness(99,   0, hot_timestamp).hotness;
      compare((hotness_1 - hot_timestamp) * 2, (hotness_2 - hot_timestamp), Testify.floatEpsilon6.equal);
    });

    test("The first 99 votes shall have the same weight as the next 9999 votes ", func() {
      let hotness_1 = InterestRules.computeScoreAndHotness(99,   0, hot_timestamp).hotness;
      let hotness_2 = InterestRules.computeScoreAndHotness(9999, 0, hot_timestamp).hotness;
      compare((hotness_1 - hot_timestamp) * 2, (hotness_2 - hot_timestamp), Testify.floatEpsilon6.equal);
    });

    test("A vote with a small minority that voted down (<33%) shall have a greater hotness than a vote with no minority at all", func() {
      let scores_1 = InterestRules.computeScoreAndHotness(70,  30, hot_timestamp);
      let scores_2 = InterestRules.computeScoreAndHotness(100, 0,  hot_timestamp);
      compare(scores_1.score,   scores_2.score,   Testify.float.lessThan   ); // The score with the smallest minority shall always be greater
      compare(scores_1.hotness, scores_2.hotness, Testify.float.greaterThan);
    });

    test("A vote with a big minority that voted down (>33%) shall have a smaller hotness than a vote with no minority at all", func() {
      let scores_1 = InterestRules.computeScoreAndHotness(65,  35, hot_timestamp);
      let scores_2 = InterestRules.computeScoreAndHotness(100,  0, hot_timestamp);
      compare(scores_1.score,   scores_2.score,   Testify.float.lessThan); // The score with the smallest minority shall always be greater
      compare(scores_1.hotness, scores_2.hotness, Testify.float.lessThan);
    });

    test("The hotness shall maximize at a ratio of approximatly 0.827 ups/total", func() {
      let hotness_1 = InterestRules.computeScoreAndHotness(827, 173, hot_timestamp).hotness;
      let hotness_2 = InterestRules.computeScoreAndHotness(829, 171, hot_timestamp).hotness;
      let hotness_3 = InterestRules.computeScoreAndHotness(825, 175, hot_timestamp).hotness;
      compare(hotness_1, hotness_2, Testify.float.greaterThan);
      compare(hotness_1, hotness_3, Testify.float.greaterThan);
    });
  });

  suite("Test computeScoreAndHotness with a fixed score", func(){
    
    let ups = 123; let downs = 343; // Some random votes
    
    test("Votes with timestamps separated by one time period shall have a hotness difference of 1", func() {
      let hotness_1 = InterestRules.computeScoreAndHotness(ups, downs, InterestRules.computeHotTimestamp(0,                        hotness_time_unit_ns)).hotness;
      let hotness_2 = InterestRules.computeScoreAndHotness(ups, downs, InterestRules.computeHotTimestamp(hotness_time_unit_ns,     hotness_time_unit_ns)).hotness;
      compare(hotness_1 + 1, hotness_2, Testify.floatEpsilon6.equal);
    });
    
    test("Votes with timestamps separated by two time periods shall have a hotness difference of 2", func() {
      let hotness_1 = InterestRules.computeScoreAndHotness(ups, downs, InterestRules.computeHotTimestamp(0,                        hotness_time_unit_ns)).hotness;
      let hotness_2 = InterestRules.computeScoreAndHotness(ups, downs, InterestRules.computeHotTimestamp(2 * hotness_time_unit_ns, hotness_time_unit_ns)).hotness;
      compare(hotness_1 + 2, hotness_2, Testify.floatEpsilon6.equal);
    });
  });

  suite("Test computeScoreAndHotness with a varying score and timestamp", func(){
  
    test("The hotness a second vote separated by a time period shall be equal to the first vote with 10 times a greater score", func() {
      let hotness_1 = InterestRules.computeScoreAndHotness(99,  0,     InterestRules.computeHotTimestamp(0,                        hotness_time_unit_ns)).hotness;
      let hotness_2 = InterestRules.computeScoreAndHotness(9,   0,     InterestRules.computeHotTimestamp(hotness_time_unit_ns,     hotness_time_unit_ns)).hotness;
      compare(hotness_1, hotness_2, Testify.floatEpsilon6.equal);
    });

  });

  suite("Test computeSelectionScore with", func(){

    let args  = {
      last_pick_date_ns = 10000;
      last_pick_score = 12.5;
      num_votes_opened = 0;
      minimum_score = 1.0;
      pick_period = 5000;
      current_time = 10000; // Same as last_pick_date
    };

    test("If the current date is the same as the last pick date, the max float shall be returned", func(){
      compare(
        InterestRules.computeSelectionScore(args),
        Math.maxFloat(),
        Testify.floatEpsilon9.equal);
    });

    test("If the current date is exactly one pick period after the last pick date, the score shall be equal to the last pick score", func(){
      compare(
        InterestRules.computeSelectionScore({args with current_time = args.last_pick_date_ns + args.pick_period}),
        args.last_pick_score,
        Testify.floatEpsilon9.equal);
    });

    test("If the computed score is smaller than the minimum score, the minimum score shall be returned", func(){
      // Use the same settings as the previous test, but raise the minimum score
      compare(
        InterestRules.computeSelectionScore({args with current_time = args.last_pick_date_ns + args.pick_period; minimum_score = 15.0;}),
        15.0,
        Testify.floatEpsilon9.equal);
    });

    test("Before one pick period, the greater the number of votes, the faster the score decays", func(){
      let current_time = args.last_pick_date_ns + args.pick_period / 2;
      compare(
        InterestRules.computeSelectionScore({ args with num_votes_opened = 10; current_time; }),
        InterestRules.computeSelectionScore({ args with num_votes_opened = 20; current_time; }),
        Testify.float.greaterThan);
    });

    test("After one pick period, the greater the number of votes, the slower the score decays", func(){
      let current_time = args.last_pick_date_ns + args.pick_period * 2;
      compare(
        InterestRules.computeSelectionScore({ args with num_votes_opened = 10; current_time; }),
        InterestRules.computeSelectionScore({ args with num_votes_opened = 20; current_time; }),
        Testify.float.lessThan);
    });

    // Values obtained via https://www.desmos.com/calculator/kschnspkyn
    let expected_values = [
      { num_votes_opened = 0;   x = 0.12;  y = 5.37211651988;   },
      { num_votes_opened = 0;   x = 2.0;   y = 0.433939720586;  },
      { num_votes_opened = 0;   x = 46.0;  y = 0.0108695652174; },
      { num_votes_opened = 0;   x = 46.0;  y = 0.0108695652174; },
      { num_votes_opened = 36;  x = 13.0;  y = 0.399969394845;  },
      { num_votes_opened = 930; x = 0.5;   y = 1.50026860058;   },
      { num_votes_opened = 470; x = 3.7;   y = 0.632277092765;  },
      { num_votes_opened = 470; x = 435.0; y = 0.200121475107;  },
    ];

    for(i in Iter.range(0, expected_values.size() - 1)){
      let {num_votes_opened; x; y;} = expected_values[i];
      let modified_args = { args with 
        num_votes_opened; 
        minimum_score = 0.0; 
        current_time = args.last_pick_date_ns + Float.toInt(Float.fromInt(args.pick_period) * x)
      };
      test("Test some values (" # Nat.toText(i + 1) # ")", func(){
        compare(
          InterestRules.computeSelectionScore(modified_args),
          modified_args.last_pick_score * y,
          Testify.floatEpsilon9.equal);
      });
    };

  });

});
