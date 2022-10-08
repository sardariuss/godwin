import Types "../types";
import Votes "votes2";

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

  public func emptyOpinionTotals() : OpinionTotals {
    { agree = 0.0; neutral = 0.0; disagree = 0.0; };
  };

  public func empty() : Opinions {
    Opinions(Votes.empty<Opinion, OpinionTotals>());
  };

  public class Opinions(register: VoteRegister<Opinion, OpinionTotals>) {

    var endorsements_ = register;

    public func getUserOpinions(principal: Principal) : Trie<Nat, Opinion> {
      Votes.getUserBallots(endorsements_, principal);
    };

    public func getOpinion(principal: Principal, question_id: Nat) : ?Opinion {
      Votes.getBallot(endorsements_, principal, question_id);
    };

    public func putOpinion(principal: Principal, question_id: Nat, opinion: Opinion) {
      endorsements_ := Votes.putBallot(endorsements_, principal, question_id, Types.hashOpinion, Types.equalOpinion, opinion, addToAggregate).0;
    };

    public func removeOpinion(principal: Principal, question_id: Nat) {
      endorsements_ := Votes.removeBallot(endorsements_, principal, question_id, Types.hashOpinion, Types.equalOpinion, removeFromAggregate).0;
    };

    public func getOpinionTotals(question_id: Nat) : ?OpinionTotals {
      Votes.getAggregation(endorsements_, question_id);
    };

    func addToAggregate(opinion_totals: ?OpinionTotals, new_opinion: Opinion, old_opinion: ?Opinion) : OpinionTotals {
      switch(opinion_totals){
        case(null){
          switch(old_opinion){
            // It is the first ballot, initialize totals
            case(null){ addToTotals(emptyOpinionTotals(), new_opinion); };
            // It shall be impossible to have no aggregate and somebody already voted
            case(_){ Debug.trap("If an old ballot has been removed, the aggregate shall already exist."); };
          };
        };
        case(?totals){
          var new_totals = addToTotals(totals, new_opinion);
          switch(old_opinion){
            // No old opinion, nothing to do
            case(null){};
            // Old opinion, remove it
            case(?old){ new_totals := removeFromTotals(new_totals, old); };
          };
          new_totals;
        };
      };
    };

    func removeFromAggregate(opinion_totals: OpinionTotals, opinion: Opinion) : OpinionTotals {
      removeFromTotals(opinion_totals, opinion);
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

};