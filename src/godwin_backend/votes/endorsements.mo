import Types "../types";
import Votes "votes2";

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

    public func getUserEndorsements(principal: Principal) : Trie<Nat, Endorsement> {
      Votes.getUserBallots(endorsements_, principal);
    };

    public func getEndorsement(principal: Principal, question_id: Nat) : ?Endorsement {
      Votes.getBallot(endorsements_, principal, question_id);
    };

    public func putEndorsement(principal: Principal, question_id: Nat) {
      endorsements_ := Votes.putBallot(
        endorsements_,
        principal,
        question_id,
        #ENDORSE,
        emptyAggregate,
        addToAggregate,
        removeFromAggregate
      ).0;
    };

    public func removeEndorsement(principal: Principal, question_id: Nat) {
      endorsements_ := Votes.removeBallot(
        endorsements_,
        principal,
        question_id,
        removeFromAggregate
      ).0;
    };

    public func getTotalEndorsements(question_id: Nat) : Nat {
      switch(Votes.getAggregation(endorsements_, question_id)){
        case(null) { 0; };
        case(?aggregation) {
          aggregation.count;
        };
      };
    };

  };

  func emptyAggregate() : BallotCount {
    { count = 0; };
  };

  func addToAggregate(aggregate: BallotCount, new_ballot: Endorsement) : BallotCount {
    { count = aggregate.count + 1; };
  };

  func removeFromAggregate(aggregate: BallotCount, ballot: Endorsement) : BallotCount {
    { count = aggregate.count - 1; };
  };

};