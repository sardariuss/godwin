import Types     "../../src/godwin_sub/utils/Types";
import Math      "../../src/godwin_sub/utils/Math";

import { compare; Testify; } = "common/Testify";

import Array     "mo:base/Array";
import Float     "mo:base/Float";

import { test; suite; } "mo:test";

suite("Math module test suite", func() {

  type RealNumber = Types.RealNumber;

  let logit_values : [(Float, RealNumber)] = [
    (0.0,  #NEGATIVE_INFINITY      ),
    (0.1 , #NUMBER(-2.197224577336)),
    (0.3 , #NUMBER(-0.847297860387)),
    (0.5 , #NUMBER( 0.0           )),
    (0.55, #NUMBER( 0.200670695462)),
    (0.75, #NUMBER( 1.098612288668)),
    (0.95, #NUMBER( 2.944438979166)),
    (1.0,  #POSITIVE_INFINITY      )
  ];

  let log_base10_values = [
    (0.1 , -1.0          ),
    (0.3 , -0.52287874528),
    (0.5 , -0.30102999566),
    (1.0,   0.0          ),
    (2.0,   0.30102999566),
    (10.0,  1.0          ),
    (300.0, 2.47712125472)
  ];

  let erf_values = [
    (-3.0, -0.999977909503),
    (-1.0, -0.842700792950),
    ( 0.0,  0.0           ),
    ( 0.5,  0.520499877813),
    ( 2.1,  0.997020533344),
  ];

  // Values retrieved with desmos.com/calculator
  let normal_pdf_values = [
    ({ sigma = 0.5; mu = 0.0; }, 0.0,  0.0             ),
    ({ sigma = 0.5; mu = 0.0; }, 0.2,  0.106796086088  ),
    ({ sigma = 0.5; mu = 0.0; }, 0.5,  3.19153824321   ),
    ({ sigma = 0.5; mu = 0.0; }, 0.7,  0.903959308058  ),
    ({ sigma = 0.8; mu = 1.0; }, 0.1,  0.00188471572615),
    ({ sigma = 0.8; mu = 1.0; }, 0.33, 0.230786741725  ),
    ({ sigma = 0.8; mu = 1.0; }, 0.85, 2.56575091421   ),
    ({ sigma = 0.8; mu = 1.0; }, 1.0,  0.0             ),
  ];

  // Values retrieved with desmos.com/calculator
  let normal_cdf_values = [
    ({ sigma = 0.5; mu =  0.0; }, 0.0, 0.0                ),
    ({ sigma = 0.5; mu =  0.0; }, 0.1, 0.00000555269958702),
    ({ sigma = 0.5; mu =  0.0; }, 0.4, 0.208702873384     ),
    ({ sigma = 0.5; mu =  0.0; }, 0.7, 0.954923930295     ),
    ({ sigma = 4.5; mu = -3.0; }, 0.1, 0.57079343087      ),
    ({ sigma = 4.5; mu = -3.0; }, 0.5, 0.747507462453     ),
    ({ sigma = 4.5; mu = -3.0; }, 0.8, 0.835153412226     ),
    ({ sigma = 4.5; mu = -3.0; }, 1.0, 1.0                ),
  ];

  test("Verify min and max floats are actual numbers", func() {
    compare(Float.isNaN(Math.minFloat()), false, Testify.bool.equal);
    compare(Float.isNaN(Math.maxFloat()), false, Testify.bool.equal);
  });

  test("Test logit", func() {
    for ((x, y) in Array.vals(logit_values)) {
      compare(Math.parametrizedLogit(x, null), y, Testify.realNumber.equal);
    };
  });

  test("Test log base 10", func() {
    for ((x, y) in Array.vals(log_base10_values)) {
      compare(Math.logBase10(x), y, Testify.floatEpsilon9.equal);
    };
  });

  test("Test erf", func() {
    for ((x, y) in Array.vals(erf_values)) {
      // According to https://www.johndcook.com/blog/2009/01/19/stand-alone-error-function-erf/, 
      // the maximum error is below 1.5 × 10-7
      compare(Math.erf(x), y, Testify.floatEpsilon6.equal);
    };
  });

  test("Test logit normal PDF", func() {
    for ((params, x, y) in Array.vals(normal_pdf_values)) {
      compare(Math.logitNormalPDF(x, params, null), y, Testify.floatEpsilon9.equal);
    };
  });

  test("Test logit normal CDF", func() {
    for ((params, x, y) in Array.vals(normal_cdf_values)) {
      // Implementation of CDF uses the ERF approximation, so use epsilon 6
      compare(Math.logitNormalCDF(x, params, null), y, Testify.floatEpsilon6.equal);
    };
  });

});
