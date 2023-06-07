import Types "Types";

import Float "mo:base/Float";
import Nat   "mo:base/Nat";

module {

  type Interest = Types.Interest;
  type Appeal   = Types.Appeal;

  public func nil() : Appeal {
    { ups = 0; downs = 0; score = 0.0; };
  };

  public func addInterest(appeal: Appeal, interest: Interest) : Appeal {
    let { ups; downs; } = appeal;
    switch(interest){
      case(#UP)        { { appeal with ups   = Nat.add(ups, 1);   score = computeScore(ups + 1, downs    ); } };
      case(#NEUTRAL)   { appeal; };
      case(#DOWN)      { { appeal with downs = Nat.add(downs, 1); score = computeScore(ups    , downs + 1); } };
    };
  };

  public func subInterest(appeal: Appeal, interest: Interest) : Appeal {
    let { ups; downs; } = appeal;
    switch(interest){
      case(#UP)      { { appeal with ups   = Nat.sub(ups, 1);   score = computeScore(ups - 1, downs    ); } };
      case(#NEUTRAL) { appeal; };
      case(#DOWN)    { { appeal with downs = Nat.sub(downs, 1); score = computeScore(ups    , downs - 1); } };
    };
  };

  func computeScore(ups: Nat, downs: Nat) : Float {
    let total = Float.fromInt(ups + downs);
    if (total == 0.0) { return total; };
    let x = Float.fromInt(ups) / total;
    let growth_rate = 20.0;
    let mid_point = 0.5;
    // https://stackoverflow.com/a/3787645: this will underflow to 0 for large negative values of x,
    // but that may be OK depending on your context since the exact result is nearly zero in that case.
    let sigmoid = (2.0 / (1.0 + Float.exp(-1.0 * growth_rate * (x - mid_point)))) - 1.0;
    total * sigmoid;
  };
  
}