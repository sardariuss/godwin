import Cursor "Cursor";
import Types "../../Types";

import Float "mo:base/Float";
import Text "mo:base/Text";
import Option "mo:base/Option";

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
    // @todo: Should assert that the result is valid, i.e. polarization2 < polarization1
    {
      left    = polarization_1.left - polarization_2.left;
      center  = polarization_1.center - polarization_2.center;
      right   = polarization_1.right - polarization_2.right;
    };
  };

  public func addOpt(polarization_1: Polarization, polarization_2: ?Polarization) : Polarization {
    add(polarization_1, Option.get(polarization_2, nil()));
  };

  public func subOpt(polarization_1: Polarization, polarization_2: ?Polarization) : Polarization {
    sub(polarization_1, Option.get(polarization_2, nil()));
  };

  public func mul(polarization: Polarization, coef: Float) : Polarization {
    if (coef >= 0.0){
      {
        left    = polarization.left * coef;
        center  = polarization.center * coef;
        right   = polarization.right * coef;
      };
    } else {
      {
        left    = polarization.right * -coef;
        center  = polarization.center * -coef;
        right   = polarization.left * -coef;
      };
    }
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

  public func addOptCursor(polarization: Polarization, cursor: ?Cursor) : Polarization {
    add(polarization, Option.getMapped(cursor, Cursor.toPolarization, nil()));
  };

  public func subCursor(polarization: Polarization, cursor: Cursor) : Polarization {
    sub(polarization, Cursor.toPolarization(cursor));
  };

  public func subOptCursor(polarization: Polarization, cursor: ?Cursor) : Polarization {
    sub(polarization, Option.getMapped(cursor, Cursor.toPolarization, nil()));
  };

  // Many different polarizations can result in the same cursor.
  // Assumes a nil polarization yeilds to a neutral cursor.
  public func toCursor(polarization: Polarization) : Cursor {
    if (isNil(polarization)) {
      return Cursor.identity();
    };
    (polarization.right - polarization.left) / (polarization.left + polarization.center + polarization.right);
  };

  public func toText(polarization: Polarization) : Text {
    "{ left = " # Float.toText(polarization.left) #
    ", center = " # Float.toText(polarization.center) #
    ", right = " # Float.toText(polarization.right) #
    " }";
  };

};