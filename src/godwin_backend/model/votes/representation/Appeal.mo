import Types "../../Types";

import Float "mo:base/Float";
import Nat "mo:base/Nat";
import Int "mo:base/Int";

module {

  // For convenience: from types module
  type Interest = Types.Interest;
  type Appeal = Types.Appeal;

  public func toText(appeal: Appeal) : Text {
    "ups: " # Nat.toText(appeal.ups) 
      #", evens: " # Nat.toText(appeal.evens) 
      # ", downs: " # Nat.toText(appeal.downs) 
      # ", score: " # Int.toText(appeal.score);
  };

  public func equal(appeal1: Appeal, appeal2: Appeal) : Bool {
    Nat.equal(appeal1.ups, appeal2.ups)
      and Nat.equal(appeal1.evens, appeal2.evens)
      and Nat.equal(appeal1.downs, appeal2.downs)
      and Int.equal(appeal1.score, appeal2.score);
  };

  public func init() : Appeal {
    { ups = 0; evens = 0;  downs = 0; score = 0; };
  };

  public func add(appeal: Appeal, interest: Interest) : Appeal {
    var ups = appeal.ups;
    var evens = appeal.evens;
    var downs = appeal.downs;
    switch(interest){
      case(#UP){ ups := appeal.ups + 1; };
      case(#EVEN){ evens := appeal.evens + 1; };
      case(#DOWN){ downs := appeal.downs + 1; };
    };
    { ups; downs; evens; score = computeScore(ups, downs); };
  };

  public func remove(appeal: Appeal, interest: Interest) : Appeal {
    var ups = appeal.ups;
    var evens = appeal.evens;
    var downs = appeal.downs;
    switch(interest){
      case(#UP){ ups := appeal.ups - 1; };
      case(#EVEN){ evens := appeal.evens - 1; };
      case(#DOWN){ downs := appeal.downs - 1; };
    };
    { ups; downs; evens; score = computeScore(ups, downs); };
  };

  // @todo: weight score with evens ?
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