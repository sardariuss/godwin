import Types "../types";
import Cursor "../representation/cursor";
import Polarization "../representation/polarization";
import Vote "vote";

import Trie "mo:base/Trie";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from types modules
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;

  // Ballot = Cursor
  // Aggregate = Polarization
  type Register = Vote.VoteRegister<Cursor, Polarization>;

  public func empty() : Opinions {
    Opinions(Vote.empty<Cursor, Polarization>());
  };

  public class Opinions(register: Register) {

    /// Members
    var register_ = register;

    public func share() : Register {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Cursor> {
      Vote.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Cursor {
      Vote.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, cursor: Cursor) {
      assert(Cursor.isValid(cursor));
      register_ := Vote.putBallot(register_, principal, question_id, cursor, Polarization.nil, Polarization.addCursor, Polarization.subCursor).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      register_ := Vote.removeBallot(register_, principal, question_id, Polarization.nil, Polarization.subCursor).0;
    };

    public func getAggregate(question_id: Nat) : Polarization {
      switch(Vote.getAggregate(register_, question_id)){
        case(?polarization) { return polarization;       };
        case(null)          { return Polarization.nil(); };
      };
    };

  };

};