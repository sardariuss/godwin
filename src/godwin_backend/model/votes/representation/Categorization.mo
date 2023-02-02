import Types "../../Types";
import Votes "../Votes";
import CursorMap "CursorMap";

module {

  public type Categorization = Types.CursorMap;
  public type Ballot = Types.Ballot<Categorization>;

  public func toText(categorization: Categorization) : Text {
    CursorMap.toText(categorization);
  };

  public func equal(categorization1: Categorization, categorization2: Categorization) : Bool {
    CursorMap.equal(categorization1, categorization2);
  };

  public func ballotToText(ballot: Ballot): Text {
    Votes.ballotToText(ballot, toText);
  };

  public func ballotsEqual(ballot1: Ballot, ballot2: Ballot): Bool {
    Votes.ballotsEqual(ballot1, ballot2, equal);
  };

};