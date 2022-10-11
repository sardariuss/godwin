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
  
  type BallotCount = {
    count: Nat;
  };

  public func emptyRegister() : VoteRegister<Endorsement, BallotCount> {
    Votes.empty<Endorsement, BallotCount>();
  };

  public func empty() : Endorsements {
    Endorsements(emptyRegister());
  };

  public class Endorsements(register: VoteRegister<Endorsement, BallotCount>) {

    var register_ = register;

    public func getRegister() : VoteRegister<Endorsement, BallotCount> {
      register_;
    };

    public func getForUser(principal: Principal) : Trie<Nat, Endorsement> {
      Votes.getUserBallots(register_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Endorsement {
      Votes.getBallot(register_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat) {
      register_ := Votes.putBallot(
        register_,
        principal,
        question_id,
        #ENDORSE,
        emptyBallotCount,
        addToBallotCount,
        removeFromBallotCount
      ).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      register_ := Votes.removeBallot(
        register_,
        principal,
        question_id,
        removeFromBallotCount
      ).0;
    };

    public func getTotalForQuestion(question_id: Nat) : Nat {
      switch(Votes.getAggregation(register_, question_id)){
        case(null) { 0; };
        case(?aggregation) {
          aggregation.count;
        };
      };
    };

  };

  func emptyBallotCount() : BallotCount {
    { count = 0; };
  };

  func addToBallotCount(aggregate: BallotCount, new_ballot: Endorsement) : BallotCount {
    { count = aggregate.count + 1; };
  };

  func removeFromBallotCount(aggregate: BallotCount, ballot: Endorsement) : BallotCount {
    { count = aggregate.count - 1; };
  };

};