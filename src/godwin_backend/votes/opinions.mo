import Types "../types";
import Votes "votes";

import Debug "mo:base/Debug";
import Trie "mo:base/Trie";
import Float "mo:base/Float";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from types modules
  type Opinion = Types.Opinion;
  type OpinionsTotal = Types.OpinionsTotal;

  type OpinionsRegister = Votes.VoteRegister<Opinion, OpinionsTotal>;

  public func verifyOpinion(opinion: Opinion) : ?Opinion {
    if (opinion >= -1.0 and opinion <= 1.0){
      return ?opinion;
    } else {
      return null;
    };
  };

  public func empty() : Opinions {
    Opinions(Votes.empty<Opinion, OpinionsTotal>());
  };

  public class Opinions(register: OpinionsRegister) {

    /// Members
    var register_ = register;

    public func share() : OpinionsRegister {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Opinion> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Opinion {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, opinion: Opinion) {
      assert(verifyOpinion(opinion) != null);
      register_ := Votes.putBallot(register_, principal, question_id, opinion, emptyTotal, addToTotal, removeFromTotal).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      register_ := Votes.removeBallot(register_, principal, question_id, removeFromTotal).0;
    };

    public func getTotalForQuestion(question_id: Nat) : OpinionsTotal {
      switch(Votes.getAggregate(register_, question_id)){
        case(?opinions_total) { return opinions_total; };
        case(null) { return emptyTotal(); };
      };
    };

  };

  func emptyTotal() : OpinionsTotal {
    { 
      cursor = 0.0;
      confidence = 0.0;
      total = 0; 
    };
  };

  func addToTotal(total: OpinionsTotal, opinion: Float) : OpinionsTotal {
    { 
      cursor = total.cursor + opinion;
      confidence = total.confidence + Float.abs(opinion);
      total = total.total + 1; 
    };
  };

  func removeFromTotal(total: OpinionsTotal, opinion: Opinion) : OpinionsTotal {
    { 
      cursor = total.cursor - opinion;
      confidence = total.confidence - Float.abs(opinion);
      total = total.total - 1; 
    };
  };

};