import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";
import Observers "../../utils/Observers";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;
  type Iter<T> = Iter.Iter<T>;
  type VoteId = Types.VoteId;

  type Map<K, V> = Map.Map<K, V>;

  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;

  // For convenience
  type WMap<K, V> = WMap.WMap<K, V>;

  public let votehash: Map.HashUtils<VoteId> = (
    func(id: VoteId) : Nat = Nat32.toNat((Nat32.fromNat(id.0) +% Nat32.fromNat(id.1)) & 0x3fffffff),
    func(a: VoteId, b: VoteId) : Bool = a.0 == b.0 and a.1 == b.1
  );

  public func ballotToText<T>(ballot: Ballot<T>, toText: (T) -> Text) : Text {
    "Ballot: { date = " # Int.toText(ballot.date) # "; answer = " # toText(ballot.answer) # "; }";
  };

  public func ballotsEqual<T>(ballot1: Ballot<T>, ballot2: Ballot<T>, equal: (T, T) -> Bool) : Bool {
    Int.equal(ballot1.date, ballot2.date) and equal(ballot1.answer, ballot2.answer);
  };

  public class Votes<T, A>(
    register_: WMap<Nat, Vote<T, A>>,
    is_valid_answer: (T) -> Bool,
    empty_aggregate_: A,
    add_to_aggregate_: (A, T) -> A,
    remove_from_aggregate_: (A, T) -> A
  ) {

    let observers_ = Observers.Observers2<Vote<T, A>>();

    public func newVote(question_id: Nat){
      if (Option.isSome(register_.get(question_id))){
        Debug.trap("A vote already exists for this question and iteration");
      };
      let vote = {
        question_id;
        ballots = Map.new<Principal, Ballot<T>>();
        aggregate = empty_aggregate_; 
      };
      updateVote(question_id, vote);
    };

    public func findVote(question_id: Nat) : ?Vote<T, A> {
      register_.get(question_id);
    };

    public func getVote(question_id: Nat) : Vote<T, A> {
      switch(findVote(question_id)){
        case(null) { Debug.trap("The vote does not exist"); };
        case(?vote) { vote; };
      };
    };

    public func removeVote(question_id: Nat) : Vote<T, A> {
      switch(register_.remove(question_id)){
        case(null) { Debug.trap("The vote does not exist"); };
        case(?vote) { 
          observers_.callObs(?vote, null);
          vote;
        };
      };
    };

    public func findBallot(principal: Principal, question_id: Nat) : ?Ballot<T> {
      Map.get(getVote(question_id).ballots, Map.phash, principal);
    };

    public func getBallot(principal: Principal, question_id: Nat) : Ballot<T> {
      switch(findBallot(principal, question_id)){
        case(null) { Debug.trap("The ballot does not exist"); };
        case(?ballot) { ballot; };
      };
    };

    public func hasBallot(principal: Principal, question_id: Nat) : Bool {
      Map.has(getVote(question_id).ballots, Map.phash, principal);
    };

    public func putBallot(principal: Principal, question_id: Nat, ballot: Ballot<T>) {
      if (not isBallotValid(ballot)){
        Debug.trap("The ballot is not valid");
      };
      let vote = getVote(question_id);
      let old_ballot = Map.put(vote.ballots, Map.phash, principal, ballot);
      let aggregate = updateAggregate(vote.aggregate, ?ballot, old_ballot);
      updateVote(question_id, { vote with aggregate; });
    };

    public func removeBallot(principal: Principal, question_id: Nat) {
      let vote = getVote(question_id);
      let old_ballot = Map.remove(vote.ballots, Map.phash, principal);
      let aggregate = updateAggregate(vote.aggregate, null, old_ballot);
      updateVote(question_id, { vote with aggregate; });
    };

    public func isBallotValid(ballot: Ballot<T>) : Bool {
      is_valid_answer(ballot.answer);
    };

    public func addObs(callback: (?Vote<T, A>, ?Vote<T, A>) -> ()) {
      observers_.addObs(callback);
    };
  
    func updateAggregate(aggregate: A, new_ballot: ?Ballot<T>, old_ballot: ?Ballot<T>) : A {
      var new_aggregate = aggregate;
      // If there is a new ballot, add it to the aggregate
      Option.iterate(new_ballot, func(ballot: Ballot<T>) {
        new_aggregate := add_to_aggregate_(new_aggregate, ballot.answer);
      });
      // If there was an old ballot, remove it from the aggregate
      Option.iterate(old_ballot, func(ballot: Ballot<T>) {
        new_aggregate := remove_from_aggregate_(new_aggregate, ballot.answer);
      });
      new_aggregate;
    };

    func updateVote(question_id: Nat, new: Vote<T, A>) {
      let old = register_.put(question_id, new);
      observers_.callObs(old, ?new);
    };

  };

};