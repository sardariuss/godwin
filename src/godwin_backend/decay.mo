import Types "types";

import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

module {

  // For convenience: from types module
  type DecayParams = Types.DecayParams;
  type Duration = Types.Duration;

  // The bigger positive number a float 64 can hold is 1.797693134e+308, which is approx. equal to exp(709)
  // The smaller positive number a float64 can hold is 4.940656458e-324, which is approx. equal to exp(-744)

  // To be able to make the exponential decay formula not underflow or overflow for the longest period of time, 
  // the oldest time value is shifted close to the lower bound (-700 is used here).

  public func computeDecayParams(time_init: Int, half_life: Types.Duration) : DecayParams {
    switch(half_life){
      case(#DAYS(half_life_days)) {
        let lambda = Float.log(2.0) / Float.fromInt(24 * 60 * 60 * 1_000_000_000 * half_life_days);
        let shift = Float.fromInt(time_init) * lambda + 700.0;
        { lambda; shift; };
      };
      case(_) {
        Debug.trap("Half life must be expressed in days");
      };
    };
  };

  public func computeOptDecayParams(time_init: Int, opt_half_life: ?Types.Duration) : ?DecayParams {
    Option.chain(opt_half_life, func(half_life: Duration) : ?DecayParams { ?computeDecayParams(time_init, half_life); });
  };

};