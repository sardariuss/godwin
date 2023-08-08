import Types "Types";

import Float "mo:base/Float";

module {

  // For convenience: from types module
  type Cursor       = Types.Cursor;
  type Polarization = Types.Polarization;

  let FLOAT_EPSILON = 1e-6;

  public func identity() : Cursor {
    0.0;
  };

  public func isValid(cursor: Cursor) : Bool {
    Float.abs(cursor) <= 1.0;
  };

  public func verifyIsValid(cursor: Cursor) : ?Cursor {
    if (isValid(cursor)) { ?cursor; }
    else                 { null;    };
  };

  public func mul(cursor1: Cursor, cursor2: Cursor) : Cursor {
    assert(isValid(cursor1));
    assert(isValid(cursor2));
    cursor1 * cursor2;
  };

  public func equal(cursor_1: Cursor, cursor_2: Cursor) : Bool {
    Float.equalWithin(cursor_1, cursor_2, FLOAT_EPSILON);
  };

  // A cursor can be transformed into a polarization by assuming
  // that the opposit side of the cursor is 0 and the rest is center
  public func toPolarization(cursor: Cursor) : Polarization {
    if (cursor >= 0.0) {
      {
        left    = 0;
        center  = 1.0 - cursor;
        right   = cursor;
      };
    } else {
      {
        left    = -cursor;
        center  = 1.0 + cursor;
        right   = 0;
      };
    };
  };

  public func toText(cursor: Cursor) : Text {
    Float.toText(cursor);
  };

};