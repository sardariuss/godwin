import Types               "Types";

import Math                "../../utils/Math";

import Float               "mo:base/Float";
import Int                 "mo:base/Int";
import Debug               "mo:base/Debug";

module {

  let INTEREST_SCORE = {
    LOGIT_NORMAL_CDF = {
      sigma           = 0.5;
      mu              = 0.0;
    };
  };

  let HOTNESS = {
    TIME_REFERENCE = 1689432900000000000; // UTC time: Sat Jul 15 2023 14:55:00
    SCORE_MODIFIER = {
      LOGIT_NORMAL_PDF = {
        sigma         = 0.5;
        mu            = 1.4;
      };
      WEIGHT          = 0.095;
    };
  };

  let SELECTION_SCORE_DECAY = {
    WEIGHT            = 0.5;
    RESISTANCE        = 1.0;
  };

  type Time                      = Int;
  type ComputeSelectionScoreArgs = Types.ComputeSelectionScoreArgs;
  type ScoreAndHotness           = Types.ScoreAndHotness;

  public func computeHotTimestamp(date: Time, time_unit_ms: Time): Float {
    Float.fromInt(date - HOTNESS.TIME_REFERENCE) / Float.fromInt(time_unit_ms);
  };

  // https://www.desmos.com/calculator/13dnsvxt5u
  public func computeScoreAndHotness(ups: Nat, downs: Nat, hot_timestamp: Float) : ScoreAndHotness {
    let total = Float.fromInt(ups + downs);
    let x = Float.fromInt(ups) / total;

    // Compute the original score base on the logit CDF so that
    // a minority of up or down voters cannot influence the score too much
    let interest_coef = if (total == 0.0) { 0.0; } else {
      (2 * Math.logitNormalCDF(x, INTEREST_SCORE.LOGIT_NORMAL_CDF, null) - 1);
    };
    let score = total * interest_coef;

    // Compute the hot modifier based on the logit normal PDF, 
    // in order to increase the ranking of the question
    // if there is a small minority of down votes
    let hot_modifier = if (total == 0.0) { 0.0; } else {
      Math.logitNormalPDF(x, HOTNESS.SCORE_MODIFIER.LOGIT_NORMAL_PDF, null);
    };
    let modified_score = total * (interest_coef + HOTNESS.SCORE_MODIFIER.WEIGHT * hot_modifier);

    // Compute the hot ranking, see https://medium.com/hacking-and-gonzo/how-reddit-ranking-algorithms-work-ef111e33d0d9
    let order = Math.logBase10(Float.abs(modified_score) + 1.0);
    let sign = if (modified_score < 0.0) { -1.0; } else { 1.0; };
    let hotness = sign * order + hot_timestamp;

    // Return the scores
    { score; hotness; };
  };
  
  // https://www.desmos.com/calculator/eczg0vqgc7
  public func computeSelectionScore(args: ComputeSelectionScoreArgs): Float {
    let { last_pick_date_ns; last_pick_score; num_votes_opened; minimum_score; pick_period; current_time; } = args;

    if (current_time < last_pick_date_ns) { Debug.trap("The current date cannot be anterior than the date of the last selection score"); };
    
    // Avoid division by zero
    if (current_time == last_pick_date_ns) { return Math.maxFloat(); };

    // Get the difference of time between now and the last pick, in pick_period units
    let time_diff = Float.fromInt(current_time - last_pick_date_ns) / Float.fromInt(pick_period);

    // Compute the momentum, which is a combination of the invert function and exponential decay
    let momentum = (    
        (1 - SELECTION_SCORE_DECAY.WEIGHT) * (1.0 / time_diff)    
      +      SELECTION_SCORE_DECAY.WEIGHT  * Float.exp((-time_diff + 1) / (SELECTION_SCORE_DECAY.RESISTANCE * (Float.fromInt(num_votes_opened) + 1)))
    );

    // Multiply the momentum by the last pick score (the more recent the score is, the higher the resulting selection score)
    let selection_score = momentum * last_pick_score;

    // Return the selection score, or the minimum score if the selection score is lower
    if (selection_score > minimum_score) { selection_score; } else { minimum_score; };
  };

};