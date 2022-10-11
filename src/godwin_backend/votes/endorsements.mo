import Types "../types";
import Votes "votes";

import Debug "mo:base/Debug";
import Trie "mo:base/Trie";

module {
  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  type VoteRegister<B, A> = Votes.VoteRegister<B, A>;
  type Endorsement = Types.Endorsement;
  type BallotCount = {
    count: Nat;
  };

  public func empty() : Endorsements {
    Endorsements(Votes.empty<Endorsement, BallotCount>());
  };

  public class Endorsements(register: VoteRegister<Endorsement, BallotCount>) {

    var endorsements_ = register;

    public func getForUser(principal: Principal) : Trie<Nat, Endorsement> {
      Votes.getUserBallots(endorsements_, principal);
    };

    public func getForUserAndQuestion(principal: Principal, question_id: Nat) : ?Endorsement {
      Votes.getBallot(endorsements_, principal, question_id);
    };

    public func put(principal: Principal, question_id: Nat) {
      endorsements_ := Votes.putBallot(
        endorsements_,
        principal,
        question_id,
        #ENDORSE,
        emptyBallotCount,
        addToBallotCount,
        removeFromBallotCount
      ).0;
    };

    public func remove(principal: Principal, question_id: Nat) {
      endorsements_ := Votes.removeBallot(
        endorsements_,
        principal,
        question_id,
        removeFromBallotCount
      ).0;
    };

    public func getTotalForQuestion(question_id: Nat) : Nat {
      switch(Votes.getAggregation(endorsements_, question_id)){
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