import Types "../../Types";
import Votes "../Votes";

import Float "mo:base/Float";

module {

  public type Opinion = Types.Cursor;
  public type Ballot = Types.Ballot<Opinion>;

  public func toText(opinion: Opinion) : Text {
    Float.toText(opinion);
  };

  public func equal(opinion1: Opinion, opinion2: Opinion) : Bool {
    Float.equal(opinion1, opinion2);
  };

  public func ballotToText(ballot: Ballot): Text {
    Votes.ballotToText(ballot, toText);
  };

  public func ballotsEqual(ballot1: Ballot, ballot2: Ballot): Bool {
    Votes.ballotsEqual(ballot1, ballot2, equal);
  };

};