import Types "types";

import Float "mo:base/Float";
import Debug "mo:base/Debug";
import Option "mo:base/Option";

// @todo: remove optional decay ?
// @todo: be able to update decay (i.e. uncomment MutableDecayParams) ?
module {

  // For convenience: from types module
  type DecayParams = Types.DecayParams;
  //type MutableDecayParams = Types.MutableDecayParams;
  type Duration = Types.Duration;

  // The bigger positive number a float 64 can hold is 1.797693134e+308, which is approx. equal to exp(709)
  // The smaller positive number a float64 can hold is 4.940656458e-324, which is approx. equal to exp(-744)

  // To be able to make the exponential decay formula not underflow or overflow for the longest period of time, 
  // the oldest time value is shifted close to the lower bound (-700 is used here).

//  public func toVarDecay(decay_params: DecayParams) : MutableDecayParams {
//    {
//      var lambda = decay_params.lambda; var shift = decay_params.shift;
//    };
//  };
//
//  public func fromVarDecay(decay_params: MutableDecayParams) : DecayParams {
//    {
//      lambda = decay_params.lambda; shift = decay_params.shift;
//    };
//  };

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


//  public func toOptVarDecay(decay_params: ?DecayParams) : ?MutableDecayParams {
//    Option.chain(decay_params, func(decay: DecayParams) : ?MutableDecayParams { ?toVarDecay(decay); });
//  };
//
//  public func fromOptVarDecay(decay_params: ?MutableDecayParams) : ?DecayParams {
//    Option.chain(decay_params, func(decay: MutableDecayParams) : ?DecayParams { ?fromVarDecay(decay); });
//  };

  public func computeOptDecayParams(time_init: Int, opt_half_life: ?Types.Duration) : ?DecayParams {
    Option.chain(opt_half_life, func(half_life: Duration) : ?DecayParams { ?computeDecayParams(time_init, half_life); });
  };

};