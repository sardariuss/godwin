import Types    "Types";
import Duration "../utils/Duration";

import Float    "mo:base/Float";
import Debug    "mo:base/Debug";

module {
  type Time     = Int;

  type Duration = Types.Duration;
  type DecayParameters = Types.DecayParameters;

  // The bigger positive number a float 64 can hold is 1.797693134e+308, which is approx. equal to exp(709)
  // The smaller positive number a float64 can hold is 4.940656458e-324, which is approx. equal to exp(-744)
  // To be able to make the exponential decay formula not overflow for the longest period of time, 
  // the initial time value is shifted closer to the lower bound.
  // Choose 360 so that if the decay is squared (decay are multiplied in convictions computation), it is 
  // still within the range of a float64 ( -360 * 2 = -720 > -744)
  let SHIFT_EXP : Float = -360;

  public func computeDecay(params: DecayParameters, date: Time) : Float {
    Float.exp(params.lambda * Float.fromInt(date) - params.shift);
  };

  public func initParameters(half_life: Duration, time_init: Time) : DecayParameters {
    // time_half_life = ln(2) / lambda
    let lambda = Float.log(2.0) / Float.fromInt(Duration.toTime(half_life));
    // The bigger positive number a float 64 can hold is 1.797693134e+308, which is approx. equal to exp(709)
    // The smaller positive number a float64 can hold is 4.940656458e-324, which is approx. equal to exp(-744)
    // To be able to make the exponential decay formula not underflow or overflow for the longest period of time, 
    // the oldest time value is shifted close to the lower bound.
    let shift = Float.fromInt(time_init) * lambda + SHIFT_EXP;
    { half_life; lambda; shift; };
  };

};