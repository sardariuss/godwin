import Types "../types";
import Votes "votes";

import Debug "mo:base/Debug";
import Trie "mo:base/Trie";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  type VoteRegister<B, A> = Votes.VoteRegister<B, A>;
  type Opinion = Types.Opinion;
  type OpinionTotals = {
    agree: Float;
    neutral: Float;
    disagree: Float;
  };

  public func empty() : Opinions {
    Opinions(Votes.empty<Opinion, OpinionTotals>());
  };

  public class Opinions(register: VoteRegister<Opinion, OpinionTotals>) {

    var endorsements_ = register;

    public func getForUser(principal: Principal) : Trie<Nat, Opinion> {
      Votes.getUserBallots(endorsements_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Opinion {
      Votes.getBallot(endorsements_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat, opinion: Opinion) {
      endorsements_ := Votes.putBallot(
        endorsements_,
        principal,
        question_id,
        opinion,
        emptyTotals,
        addToTotals,
        removeFromTotals
      ).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      endorsements_ := Votes.removeBallot(
        endorsements_,
        principal,
        question_id,
        removeFromTotals
      ).0;
    };

    public func getTotalsForQuestion(question_id: Nat) : ?OpinionTotals {
      Votes.getAggregation(endorsements_, question_id);
    };

  };

  func emptyTotals() : OpinionTotals {
    { agree = 0.0; neutral = 0.0; disagree = 0.0; };
  };

  func addToTotals(totals: OpinionTotals, opinion: Opinion) : OpinionTotals {
    switch(opinion){
      case(#AGREE(agreement)){
        switch(agreement){
          case(#ABSOLUTE){ { agree = totals.agree + 1.0; neutral = totals.neutral      ; disagree = totals.disagree      ; } };
          case(#MODERATE){ { agree = totals.agree + 0.5; neutral = totals.neutral + 0.5; disagree = totals.disagree      ; } };
        };
      };
      case(#NEUTRAL)     { { agree = totals.agree      ; neutral = totals.neutral + 1.0; disagree = totals.disagree      ; } };
      case(#DISAGREE(agreement)){
        switch(agreement){
          case(#MODERATE){ { agree = totals.agree      ; neutral = totals.neutral + 0.5; disagree = totals.disagree + 0.5; } };
          case(#ABSOLUTE){ { agree = totals.agree      ; neutral = totals.neutral      ; disagree = totals.disagree + 1.0; } };
        };
      };
    };
  };

  func removeFromTotals(totals: OpinionTotals, opinion: Opinion) : OpinionTotals {
    switch(opinion){
      case(#AGREE(agreement)){
        switch(agreement){
          case(#ABSOLUTE){ { agree = totals.agree - 1.0; neutral = totals.neutral      ; disagree = totals.disagree      ; } };
          case(#MODERATE){ { agree = totals.agree - 0.5; neutral = totals.neutral - 0.5; disagree = totals.disagree      ; } };
        };
      };
      case(#NEUTRAL)     { { agree = totals.agree      ; neutral = totals.neutral - 1.0; disagree = totals.disagree      ; } };
      case(#DISAGREE(agreement)){
        switch(agreement){
          case(#MODERATE){ { agree = totals.agree      ; neutral = totals.neutral - 0.5; disagree = totals.disagree - 0.5; } };
          case(#ABSOLUTE){ { agree = totals.agree      ; neutral = totals.neutral      ; disagree = totals.disagree - 1.0; } };
        };
      };
    };
  };

};