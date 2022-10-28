import Types "../types";
import Votes "votes";

import Debug "mo:base/Debug";
import Trie "mo:base/Trie";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from types module
  type Endorsement = Types.Endorsement;
  // For convenience: from other modules
  type VoteRegister<B, A> = Votes.VoteRegister<B, A>;
  
  public type EndorsementsTotal = Nat;

  public func emptyRegister() : VoteRegister<Endorsement, EndorsementsTotal> {
    Votes.empty<Endorsement, EndorsementsTotal>();
  };

  public func empty() : Endorsements {
    Endorsements(emptyRegister());
  };

  public class Endorsements(register: VoteRegister<Endorsement, EndorsementsTotal>) {

    var register_ = register;

    public func getRegister() : VoteRegister<Endorsement, EndorsementsTotal> {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Endorsement> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Endorsement {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat) {
      register_ := Votes.putBallot(register_, principal, question_id, #ENDORSE, emptyTotal, addToTotal, removeFromTotal).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      register_ := Votes.removeBallot(register_, principal, question_id, removeFromTotal).0;
    };

    public func getTotalForQuestion(question_id: Nat) : EndorsementsTotal {
      switch(Votes.getAggregate(register_, question_id)){
        case(null) { 0; };
        case(?total) { total; };
      };
    };

  };

  func emptyTotal() : EndorsementsTotal {
    0;
  };

  func addToTotal(total: EndorsementsTotal, new_ballot: Endorsement) : EndorsementsTotal {
    total + 1;
  };

  func removeFromTotal(total: EndorsementsTotal, ballot: Endorsement) : EndorsementsTotal {
    total - 1;
  };

};