import Types  "Types";

import Float  "mo:base/Float";
import Debug  "mo:base/Debug";
import Option "mo:base/Option";

module {

  type LogitNormalParams = Types.LogitNormalParams;
  type RealNumber        = Types.RealNumber;
  type LogitParameters   = Types.LogitParameters;

  let EPSILON = 1e-12;
  let DEFAULT_LOGIT_PARAMETERS : LogitParameters = { k = 1.0; l = 0.0; };

  public func minFloat() : Float {
    return -340282346638528859811704183484516925440.0; 
  };
  
  public func maxFloat() : Float {
    return  340282346638528859811704183484516925440.0; 
  };

  public func parametrizedLogit(x: Float, logit_parameters: ?LogitParameters) : RealNumber {

    let { k; l; } = Option.get(logit_parameters, DEFAULT_LOGIT_PARAMETERS);
    
    // Handle the limit cases
    if (Float.equalWithin(x, -l/k, EPSILON)){
      return #NEGATIVE_INFINITY;
    };
    if (Float.equalWithin(x, 1.0/k, EPSILON)){
      return #POSITIVE_INFINITY;
    };
    
    // Compute the inner expression
    let y = (k * x + l) / (1.0 - k * x);
    
    if (y < 0.0){
      Debug.trap("Cannot compute the log of a negative number");
    };

    // Return the full logit result
    #NUMBER(Float.log(y));
  };

  public func logBase10(x: Float) : Float {
    Float.log(x) / 2.30258509299;
  };

  // Error function, adapted from https://www.johndcook.com/blog/cpp_erf/
  public func erf(x: Float) : Float {
    // Constants
    let a1 =  0.254829592;
    let a2 = -0.284496736;
    let a3 =  1.421413741;
    let a4 = -1.453152027;
    let a5 =  1.061405429;
    let p  =  0.3275911;
    
    // Save the sign of x
    let sign = if (x < 0.0) { -1.0; } else { 1.0; };
    let abs_x = Float.abs(x);
    
    // A&S formula 7.1.26
    let t = 1.0 / (1.0 + p * abs_x);
    let y = 1.0 - (((((a5 * t + a4) * t) + a3) * t + a2) * t + a1) * t * Float.exp(-abs_x * abs_x);
    
    sign * y;
  };

  public func logitNormalPDF(x: Float, params: LogitNormalParams, logit_parameters: ?LogitParameters) : Float {

    let { sigma; mu; } = params;

    // Verify the parameters
    if (sigma <= 0.0){
      Debug.trap("LogitNormalParams: sigma must be positive");
    };

    switch(parametrizedLogit(x, logit_parameters)){
      // Handle the limit cases
      case (#NEGATIVE_INFINITY) return 0.0;
      case (#POSITIVE_INFINITY) return 0.0;
      // Compute the PDF
      case (#NUMBER(logit)){
        1.0 / (sigma * Float.sqrt(2.0 * Float.pi)) * Float.exp(-0.5 * Float.pow((logit - mu) / sigma, 2.0)) / (x * (1.0 - x));
      };
    };
  };

  public func logitNormalCDF(x: Float, params: LogitNormalParams, logit_parameters: ?LogitParameters) : Float {

    let { sigma; mu; } = params;
    
    // Verify the parameters
    if (sigma <= 0.0){
      Debug.trap("LogitNormalParams: sigma must be positive");
    };

    switch(parametrizedLogit(x, logit_parameters)){
      // Handle the limit cases
      case (#NEGATIVE_INFINITY) return 0.0;
      case (#POSITIVE_INFINITY) return 1.0;
      // Compute the CDF
      case (#NUMBER(logit)){
        0.5 * (1.0 + erf((logit - mu) / (sigma * Float.sqrt(2.0))));
      };
    };
  };

};