import Types "types";

import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

module {

  // For convenience: from types module
  type Decay = Types.Decay;
  type Duration = Types.Duration;

  // The bigger positive number a float 64 can hold is 1.797693134e+308, which is approx. equal to exp(709)
  // The smaller positive number a float64 can hold is 4.940656458e-324, which is approx. equal to exp(-744)
  // To be able to make the exponential decay formula not underflow or overflow for the longest period of time, 
  // the oldest time value is shifted close to the lower bound (-700 is used here).
  public func computeDecay(time_init: Int, half_life: Duration) : Decay {
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

  public func computeOptDecay(time_init: Int, opt_half_life: ?Duration) : ?Decay {
    Option.chain(opt_half_life, func(half_life: Duration) : ?Decay { ?computeDecay(time_init, half_life); });
  };

};