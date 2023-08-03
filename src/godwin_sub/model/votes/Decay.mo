import Types      "Types";
import UtilsTypes "../../utils/Types";
import Duration   "../../utils/Duration";

import Float      "mo:base/Float";
import Debug      "mo:base/Debug";

module {
  type Time            = Int;

  type Duration        = UtilsTypes.Duration;
  type DecayParameters = Types.DecayParameters;

  // The bigger positive number a float 64 can hold is 1.797693134e+308, which is approx. equal to exp(709)
  // The smaller positive number a float64 can hold is 4.940656458e-324, which is approx. equal to exp(-744)
  // To be able to make the exponential decay formula not overflow for the longest period of time, 
  // the initial time value is shifted closer to the lower bound.
  // Choose -200 so that if the decay is squared (decay are multiplied in convictions computation) or multiplied 
  // further, it shall stay within the range of a float64 ( 10^-200 * 10^-200 = 10^-400 >> 10^-744)
  // @todo: not up to date, decay are devided not multiplied
  let SHIFT_EXP : Float = -200;

  public func computeDecay(params: DecayParameters, date: Time) : Float {
    Float.exp(params.lambda * Float.fromInt(date) - params.shift);
  };

  public func getDecayParameters(half_life: Duration, time_init: Time) : DecayParameters {
    let lambda = Float.log(2.0) / Float.fromInt(Duration.toTime(half_life));
    // The bigger positive number a float 64 can hold is 1.797693134e+308, which is approx. equal to exp(709)
    // The smaller positive number a float64 can hold is 4.940656458e-324, which is approx. equal to exp(-744)
    // To be able to make the exponential decay formula not underflow or overflow for the longest period of time, 
    // the oldest time value is shifted close to the lower bound.
    let shift = Float.fromInt(time_init) * lambda + SHIFT_EXP;
    { half_life; lambda; shift; };
  };

};