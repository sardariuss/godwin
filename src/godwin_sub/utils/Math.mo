import Types "Types";

import Float "mo:base/Float";
import Debug "mo:base/Debug";

module {

  type LogitNormalParams = Types.LogitNormalParams;

  public func minFloat() : Float {
    return -340282346638528859811704183484516925440.0; 
  };
  
  public func maxFloat() : Float {
    return  340282346638528859811704183484516925440.0; 
  };

  let EPSILON = 1e-12;

  public func logit(x: Float) : Float {
    Float.log(x / (1.0 - x));
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

  public func logitNormalPDF(x: Float, params: LogitNormalParams) : Float {

    let { sigma; mu; } = params;

    // Verify the parameters
    if (sigma <= 0.0){
      Debug.trap("LogitNormalParams: sigma must be positive");
    };

    // Verify the input
    if (x < 0.0 or x > 1.0) {
      Debug.trap("LogitNormalPDF: x must be between 0 and 1");
    };

    // Handle the special cases
    if (Float.equalWithin(x, 0.0, EPSILON) or Float.equalWithin(x, 1.0, EPSILON)) {
      return 0.0;
    };

    // Compute the PDF
    1.0 / (sigma * Float.sqrt(2.0 * Float.pi)) * Float.exp(-0.5 * Float.pow((logit(x) - mu) / sigma, 2.0)) / (x * (1.0 - x));
  };

  public func logitNormalCDF(x: Float, params: LogitNormalParams) : Float {

    let { sigma; mu; } = params;
    
    // Verify the parameters
    if (sigma <= 0.0){
      Debug.trap("LogitNormalParams: sigma must be positive");
    };

    // Verify the input
    if (x < 0.0 or x > 1.0) {
      Debug.trap("LogitNormalCDF: x must be between 0 and 1");
    };

    // Handle the special cases
    if (Float.equalWithin(x, 0.0, EPSILON)){
      return 0.0;
    };
    if (Float.equalWithin(x, 1.0, EPSILON)) {
      return 1.0;
    };

    // Compute the CDF
    0.5 * (1.0 + erf((logit(x) - mu) / (sigma * Float.sqrt(2.0))));
  };

};