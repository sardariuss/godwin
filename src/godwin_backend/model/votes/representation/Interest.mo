import Types "../../Types";
import Votes "../Votes";

module {

  public type Interest = Types.Interest;
  public type Ballot = Types.Ballot<Interest>;

  public func toText(interest: Interest): Text {
    switch(interest) {
      case(#UP) { "UP"; };
      case(#DOWN) { "DOWN"; };
    };
  };

  public func equal(interest1: Interest, interest2: Interest): Bool {
    interest1 == interest2;
  };

  public func ballotToText(ballot: Ballot): Text {
    Votes.ballotToText(ballot, toText);
  };

  public func ballotsEqual(ballot1: Ballot, ballot2: Ballot): Bool {
    Votes.ballotsEqual(ballot1, ballot2, equal);
  };

};