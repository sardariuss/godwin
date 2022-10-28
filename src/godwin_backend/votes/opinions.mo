import Types "../types";
import Votes "votes";

import Debug "mo:base/Debug";
import Trie "mo:base/Trie";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from types modules
  type Opinion = Types.Opinion;
  type OpinionsTotal = Types.OpinionsTotal;
  // For convenience: from other modules
  type VoteRegister<B, A> = Votes.VoteRegister<B, A>;


  public func emptyRegister() : VoteRegister<Opinion, OpinionsTotal> {
    Votes.empty<Opinion, OpinionsTotal>();
  };

  public func empty() : Opinions {
    Opinions(emptyRegister());
  };

  public class Opinions(register: VoteRegister<Opinion, OpinionsTotal>) {

    var register_ = register;

    public func getRegister() : VoteRegister<Opinion, OpinionsTotal> {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Opinion> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Opinion {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, opinion: Opinion) {
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
    { agree = 0.0; neutral = 0.0; disagree = 0.0; };
  };

  func addToTotal(total: OpinionsTotal, opinion: Opinion) : OpinionsTotal {
    switch(opinion){
      case(#AGREE(agreement)){
        switch(agreement){
          case(#ABSOLUTE){ { agree = total.agree + 1.0; neutral = total.neutral      ; disagree = total.disagree      ; } };
          case(#MODERATE){ { agree = total.agree + 0.5; neutral = total.neutral + 0.5; disagree = total.disagree      ; } };
        };
      };
      case(#NEUTRAL)     { { agree = total.agree      ; neutral = total.neutral + 1.0; disagree = total.disagree      ; } };
      case(#DISAGREE(agreement)){
        switch(agreement){
          case(#MODERATE){ { agree = total.agree      ; neutral = total.neutral + 0.5; disagree = total.disagree + 0.5; } };
          case(#ABSOLUTE){ { agree = total.agree      ; neutral = total.neutral      ; disagree = total.disagree + 1.0; } };
        };
      };
    };
  };

  func removeFromTotal(total: OpinionsTotal, opinion: Opinion) : OpinionsTotal {
    switch(opinion){
      case(#AGREE(agreement)){
        switch(agreement){
          case(#ABSOLUTE){ { agree = total.agree - 1.0; neutral = total.neutral      ; disagree = total.disagree      ; } };
          case(#MODERATE){ { agree = total.agree - 0.5; neutral = total.neutral - 0.5; disagree = total.disagree      ; } };
        };
      };
      case(#NEUTRAL)     { { agree = total.agree      ; neutral = total.neutral - 1.0; disagree = total.disagree      ; } };
      case(#DISAGREE(agreement)){
        switch(agreement){
          case(#MODERATE){ { agree = total.agree      ; neutral = total.neutral - 0.5; disagree = total.disagree - 0.5; } };
          case(#ABSOLUTE){ { agree = total.agree      ; neutral = total.neutral      ; disagree = total.disagree - 1.0; } };
        };
      };
    };
  };

};