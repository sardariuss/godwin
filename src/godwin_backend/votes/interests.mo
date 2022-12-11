import Types "../types";
//import Vote "vote";
import VoteRegister "voteRegister";

import Float "mo:base/Float";

module {

  // For convenience: from types module
  type B = Types.Interest;
  type A = Types.InterestAggregate;
  
//  public type Vote = Types.Vote<B, A>;
  public type Register = VoteRegister.Register<B, A>;
  // For convenience: from types module
  type Vote = Types.Vote<B, A>;

//  public func empty() : Register {
//    VoteRegister.empty();
//  };

//  public func get(register: Register, index: Nat) : Vote {
//    VoteRegister.get(register, index);
//  };
//
  public func find(register: Register, index: Nat) : ?Vote {
    VoteRegister.find(register, index);
  };

  public func newVote(register: Register, date: Int) : (Register, Vote) {
    VoteRegister.newVote(register, date, emptyAggregate());
  };
//
//  public func updateVote(register: Register, vote: Vote) : Register {
//    VoteRegister.updateVote(register, vote);
//  };
//
//  public func getBallot(register: Register, id: Nat, principal: Principal) : ?B {
//    VoteRegister.getBallot(register, id, principal);
//  };

  public func putBallot(register: Register, id: Nat, principal: Principal, ballot: B) : Register {
    VoteRegister.putBallot(register, id, principal, ballot, addToAggregate, removeFromAggregate);
  };

  public func removeBallot(register: Register, id: Nat, principal: Principal) : Register {
    VoteRegister.removeBallot(register, id, principal, addToAggregate, removeFromAggregate);
  };

  func emptyAggregate() : A {
    { ups = 0; downs = 0; score = 0; };
  };

  public func addToAggregate(aggregate: A, ballot: B) : A {
    var ups = aggregate.ups;
    var downs = aggregate.downs;
    switch(ballot){
      case(#UP){ ups := aggregate.ups + 1; };
      case(#DOWN){ downs := aggregate.downs + 1; };
    };
    { ups; downs; score = computeScore(ups, downs) };
  };

  public func removeFromAggregate(aggregate: A, ballot: B) : A {
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