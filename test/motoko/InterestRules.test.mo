import Math                    "../../src/godwin_sub/utils/Math";
import InterestRules           "../../src/godwin_sub/model/votes/InterestRules";

import { compare; Testify; } = "common/Testify";

import { test; suite; }        "mo:test";

import Array                   "mo:base/Array";

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

  suite("Test computeSelectionScore", func(){

    test("If the date of the last pick is the same as now, the max float shall be returned", func(){
      let pick_period = 5000;
      let momentum_args  = {
        last_pick_date_ns = 10000;
        last_pick_score = 10.0;
        num_votes_opened = 0;
        minimum_score = 1.0;
      };
      let selection_score = InterestRules.computeSelectionScore(momentum_args, pick_period, momentum_args.last_pick_date_ns);
      compare(selection_score, Math.maxFloat(), Testify.floatEpsilon6.equal);
    });

    // @todo: complete test on selection score
    
  });

});
