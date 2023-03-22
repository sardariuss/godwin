import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";
import Utils "../../utils/Utils";
import BallotAggregator "BallotAggregator";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";
import Result "mo:base/Result";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;
  type Iter<T> = Iter.Iter<T>;
  type VoteId = Types.VoteId;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Buffer<T> = Buffer.Buffer<T>;

  type Map<K, V> = Map.Map<K, V>;

  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type PublicVote<T, A> = Types.PublicVote<T, A>;
  type GetBallotError = Types.GetBallotError;
  type PutBallotError = Types.PutBallotError;
  type GetVoteError = Types.GetVoteError;
  type UpdateBallotAuthorization = Types.UpdateBallotAuthorization;
  type BallotAggregator<T, A> = BallotAggregator.BallotAggregator<T, A>;

  // For convenience
  type WMap<K, V> = WMap.WMap<K, V>;

  public func toPublicVote<T, A>(vote: Vote<T, A>) : PublicVote<T, A> {
    {
      id = vote.id;
      status = vote.status;
      ballots = Utils.mapToArray(vote.ballots);
      aggregate = vote.aggregate;
    }
  };

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

  type Callback<A> = (Nat, ?A, ?A) -> ();

  public class Votes<T, A>(
    register_: WMap<Nat, Vote<T, A>>,
    ballot_aggregator_: BallotAggregator<T, A>,
    empty_aggregate_: A
  ) {

    // @todo: put in factory
    let observers_ = Buffer.Buffer<Callback<A>>(0);

    // Safe
    // @todo: should return the public vote and rename in revealVote
    public func getVote(id: Nat) : Result<Vote<T, A>, GetVoteError> {
      let vote = switch(register_.getOpt(id)){
        case(null) { return #err(#VoteNotFound); };
        case(?v) { v; };
      };
      if (vote.status == #OPEN){
        return #err(#VoteIsOpen);
      };
      #ok(vote);
    };

    // Safe
    public func getBallot(principal: Principal, id: Nat) : Result<Ballot<T>, GetBallotError> {
      let vote = switch(register_.getOpt(id)){
        case(null) { return #err(#VoteNotFound); };
        case(?v) { v; };
      };
      Result.fromOption(Map.get(vote.ballots, Map.phash, principal), #BallotNotFound);
    };

    // Safe
    public func putBallot(principal: Principal, id: Nat, ballot: Ballot<T>) : Result<(), PutBallotError> {
      // Verify the principal is not anonymous
      if (Principal.isAnonymous(principal)){
        return #err(#PrincipalIsAnonymous);
      };
      // Get the vote
      let vote = switch(register_.getOpt(id)){
        case(null) { return #err(#VoteNotFound); };
        case(?vote) { vote; };
      };
      // Put the ballot
      let old_aggregate = vote.aggregate;
      Result.mapOk<(A, A), (), PutBallotError>(ballot_aggregator_.putBallot(vote, principal, ballot), func(_) {
       callObs(vote.id, ?old_aggregate, ?vote.aggregate);
      });
    };

    // Bold
    public func newVote(id: Nat){
      if (register_.has(id)){
        Debug.trap("A vote already exists for this question and iteration");
      };
      let vote = {
        id;
        status = #OPEN;
        ballots = Map.new<Principal, Ballot<T>>();
        aggregate = empty_aggregate_; 
      };
      callObs(vote.id, null, ?vote.aggregate);
    };



    // Bold
    public func removeVote(id: Nat) : Vote<T, A> {
      switch(register_.remove(id)){
        case(null) { Debug.trap("The vote does not exist"); };
        case(?vote) {
          callObs(vote.id, ?vote.aggregate, null);
          vote;
        };
      };
    };

    public func addObs(callback: (Nat, ?A, ?A) -> ()) {
      observers_.add(callback);
    };

    func callObs(id: Nat, old: ?A, new: ?A) {
      for (obs_func in observers_.vals()){
        obs_func(id, old, new);
      };
    };

  };

};