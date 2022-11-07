import Types "../types";
import Cursor "cursor";

import Float "mo:base/Float";
import Text "mo:base/Text";

module {

  // For convenience: from types module
  type Polarization = Types.Polarization;
  type Cursor = Types.Cursor;

  public func isValid(polarization: Polarization) : Bool {
    return Float.abs(polarization.left) >= 0.0
       and Float.abs(polarization.center) >= 0.0
       and Float.abs(polarization.right) >= 0.0;
  };

  public func nil() : Polarization {
    {
      left    = 0.0;
      center  = 0.0;
      right   = 0.0;
    };
  };

  public func isNil(polarization: Polarization) : Bool {
    equal(polarization, nil());
  };

  public func add(polarization_1: Polarization, polarization_2: Polarization) : Polarization {
    {
      left    = polarization_1.left + polarization_2.left;
      center  = polarization_1.center + polarization_2.center;
      right   = polarization_1.right + polarization_2.right;
    };
  };

  public func sub(polarization_1: Polarization, polarization_2: Polarization) : Polarization {
    {
      left    = polarization_1.left - polarization_2.left;
      center  = polarization_1.center - polarization_2.center;
      right   = polarization_1.right - polarization_2.right;
    };
  };

  public func mul(polarization: Polarization, coef: Float) : Polarization {
    {
      left    = polarization.left * coef;
      center  = polarization.center * coef;
      right   = polarization.right * coef;
    };
  };

  public func div(polarization: Polarization, divisor: Float) : Polarization {
    {
      left    = polarization.left / divisor;
      center  = polarization.center / divisor;
      right   = polarization.right / divisor;
    };
  };

  /// Warning: the polarizations are not normalized
  /// One could normalize before doing the comparison, but then comparing nil polarization
  /// would trap.
  public func equal(polarization_1: Polarization, polarization_2: Polarization) : Bool {
    polarization_1.left == polarization_2.left and 
    polarization_1.center == polarization_2.center and 
    polarization_1.right == polarization_2.right;
  };

  public func addCursor(polarization: Polarization, cursor: Cursor) : Polarization {
    add(polarization, Cursor.toPolarization(cursor));
  };

  public func subCursor(polarization: Polarization, cursor: Cursor) : Polarization {
    sub(polarization, Cursor.toPolarization(cursor));
  };

  // Warning: Many different polarizations can lead to the same cursor
  public func toCursor(polarization: Polarization) : Cursor {
    // A nil polarization cannot be represented by a cursor
    assert(not isNil(polarization));
    // Return the "normalized" cursor
    (polarization.right - polarization.left) / (polarization.left + polarization.center + polarization.right);
  };

  public func toText(polarization: Polarization) : Text {
    "{ left = " # Float.toText(polarization.left) #
    ", center = " # Float.toText(polarization.center) #
    ", right = " # Float.toText(polarization.right) #
    " }";
  };

  // @todo: it is probably a bad idea to normalize a polarization, because it can be nil ?
  // anyway it is not needed
//  func getNormalized(polarization: Polarization) : Polarization {
//    assert(isValid(polarization));
//    let sum = polarization.left + polarization.center + polarization.right;
//    if (sum == 0.0) {
//      polarization;
//    } else {
//      {
//        left    = polarization.left / sum;
//        center  = polarization.center / sum;
//        right   = polarization.right / sum;
//      };
//    };
//  };

};