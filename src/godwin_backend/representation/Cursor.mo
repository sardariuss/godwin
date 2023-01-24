import Types "../Types";

import Float "mo:base/Float";

module {

  // For convenience: from types module
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;

  public func init() : Cursor {
    0.0;
  };

  public func isValid(cursor: Cursor) : Bool {
    Float.abs(cursor) <= 1.0;
  };

  public func verifyIsValid(cursor: Cursor) : ?Cursor {
    if (isValid(cursor)) { ?cursor; }
    else                 { null;    };
  };

  public func equal(cursor_1: Cursor, cursor_2: Cursor) : Bool {
    Float.equal(cursor_1, cursor_2);
  };

  // One cursor leads to only one *normalized* polarization by assuming
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