import Types "../types";
import Vote "vote";

import Float "mo:base/Float";

module {

  // For convenience: from types module
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;

  func emptyAggregate() : InterestAggregate {
    { ups = 0; downs = 0; score = 0; };
  };

  public func addToAggregate(aggregate: InterestAggregate, ballot: Interest) : InterestAggregate {
    var ups = aggregate.ups;
    var downs = aggregate.downs;
    switch(ballot){
      case(#UP){ ups := aggregate.ups + 1; };
      case(#DOWN){ downs := aggregate.downs + 1; };
    };
    { ups; downs; score = computeScore(ups, downs) };
  };

  public func removeFromAggregate(aggregate: InterestAggregate, ballot: Interest) : InterestAggregate {
    var ups = aggregate.ups;
    var downs = aggregate.downs;
    switch(ballot){
      case(#UP){ ups := aggregate.ups - 1; };
      case(#DOWN){ downs := aggregate.downs - 1; };
    };
    { ups; downs; score = computeScore(ups, downs) };
  };

  func computeScore(ups: Nat, downs: Nat) : Int {
    if (ups + downs == 0) { return 0; };
    let f_ups = Float.fromInt(ups);
    let f_downs = Float.fromInt(downs);
    let x = f_ups / (f_ups + f_downs);
    let growth_rate = 20.0;
    let mid_point = 0.5;
    // https://stackoverflow.com/a/3787645: this will underflow to 0 for large negative values of x,
    // but that may be OK depending on your context since the exact result is nearly zero in that case.
    let sigmoid = 1.0 / (1.0 + Float.exp(-1.0 * growth_rate * (x - mid_point)));
    Float.toInt(Float.nearest(f_ups * sigmoid - f_downs * (1.0 - sigmoid)));
  };

};