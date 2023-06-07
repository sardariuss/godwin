import Types      "Types";
import VotePolicy "VotePolicy";
import PayToVote  "PayToVote";
import PayTypes   "../token/Types";

import Utils      "../../utils/Utils";
import UtilsTypes "../../utils/Types";

import Map        "mo:map/Map";
import Set        "mo:map/Set";

import Principal  "mo:base/Principal";
import Result     "mo:base/Result";
import Debug      "mo:base/Debug";
import Nat        "mo:base/Nat";
import Int        "mo:base/Int";
import Option     "mo:base/Option";
import Nat32      "mo:base/Nat32";
import Array      "mo:base/Array";
import Prim       "mo:prim";


module {

  // For convenience: from base module
  type Principal          = Principal.Principal;
  type Result <Ok, Err>   = Result.Result<Ok, Err>;
    
  type Map<K, V>          = Map.Map<K, V>;
  type Set<K>             = Set.Set<K>;

  type VoteId             = Types.VoteId;
  type Ballot<T>          = Types.Ballot<T>;
  type RevealedBallot<T>  = Types.RevealedBallot<T>;
  type Vote<T, A>         = Types.Vote<T, A>;
  type GetVoteError       = Types.GetVoteError;
  type FindBallotError    = Types.FindBallotError;
  type RevealVoteError    = Types.RevealVoteError;
  type PutBallotError     = Types.PutBallotError;

  type ScanLimitResult<K> = UtilsTypes.ScanLimitResult<K>;
  type Direction          = UtilsTypes.Direction;
  
  type TransactionsRecord = PayTypes.TransactionsRecord;

  type VotePolicy<T, A>   = VotePolicy.VotePolicy<T, A>;
  type PayToVote<T, A>    = PayToVote.PayToVote<T, A>;

  public func ballotToText<T>(ballot: Ballot<T>, toText: (T) -> Text) : Text {
    "Ballot: { date = " # Int.toText(ballot.date) # "; answer = " # toText(ballot.answer) # "; }";
  };

  public func ballotsEqual<T>(ballot1: Ballot<T>, ballot2: Ballot<T>, equal: (T, T) -> Bool) : Bool {
    Int.equal(ballot1.date, ballot2.date) and equal(ballot1.answer, ballot2.answer);
  };

  public type Register<T, A> = {
    votes: Map<VoteId, Vote<T, A>>;
    voters_history: Map<Principal, Set<VoteId>>;
    var index: VoteId;
  };

  public func initRegister<T, A>() : Register<T, A> {
    {
      votes = Map.new<VoteId, Vote<T, A>>(Map.nhash);
      voters_history = Map.new<Principal, Set<VoteId>>(Map.phash);
      var index = 0;
    }
  };

  let pnhash: Map.HashUtils<(Principal, Nat)> = (
    // +% is the same as addWrap, meaning it wraps on overflow
    func(key: (Principal, Nat)) : Nat32 = (Prim.hashBlob(Prim.blobOfPrincipal(key.0)) +% Nat32.fromIntWrap(key.1)) & 0x3fffffff,
    func(a: (Principal, Nat), b: (Principal, Nat)) : Bool = a.0 == b.0 and a.1 == b.1,
    func() = (Principal.fromText("2vxsx-fae"), 0)
  );

  public func initVote<T, A>(vote_id: VoteId, empty_aggregate: A) : Vote<T, A> {
    {
      id = vote_id;
      var status = #OPEN;
      ballots = Map.new<Principal, Ballot<T>>(Map.phash);
      var aggregate = empty_aggregate; 
    };
  };

  public class Votes<T, A>(
    _register: Register<T, A>,
    _policy: VotePolicy<T, A>,
    _pay_to_vote: ?PayToVote<T, A>
  ) {

    let _ballot_locks = Set.new<(Principal, VoteId)>(pnhash);

    public func newVote() : VoteId {
      let index = _register.index;
      let vote : Vote<T, A> = initVote(index, _policy.emptyAggregate());
      Map.set(_register.votes, Map.nhash, index, vote);
      _register.index += 1;
      index;
    };

    public func closeVote(id: VoteId) : async*() {
      switch(Map.get(_register.votes, Map.nhash, id)){
        case(null) { Debug.trap("Could not find a vote with ID '" # Nat.toText(id) # "'"); };
        case(?vote) {
          // Check if the vote in not already closed
          if (vote.status == #CLOSED) {
            Debug.trap("The vote with ID '" # Nat.toText(id) # "' is already closed");
          };
          // Close the vote
          vote.status := #CLOSED;
          Map.set(_register.votes, Map.nhash, id, vote); // @todo: not required ?
          // Payout if any
          switch(_pay_to_vote){
            case(null) {};
            case(?pay_to_vote) { await* pay_to_vote.payout(vote); };
          };
        };
      };
    };

    public func putBallot(principal: Principal, id: VoteId, ballot: Ballot<T>) : async* Result<(), PutBallotError> {
      // Prevent reentry
      if (Set.has(_ballot_locks, pnhash, (principal, id))) {
        return #err(#VoteLocked);
      };
      
      ignore Set.put(_ballot_locks, pnhash, (principal, id));
      let result = await* _putBallot(principal, id, ballot);
      Set.delete(_ballot_locks, pnhash, (principal, id));
      result;
    };

    // @todo: it might be dangerous to check the condition before awaiting the payement, because the condition might have
    // changed after the await, and updating the state not working in consequence.
    // Right now it is not the case, it is just a Map.put
    func _putBallot(principal: Principal, id: VoteId, ballot: Ballot<T>) : async* Result<(), PutBallotError> {
      
      // Check if the user can put the ballot
      let vote = switch(_policy.canPutBallot(_register.votes, id, principal, ballot)){
        case(#err(err)) { return #err(err); };
        case(#ok(v)) { v; };
      };

      // Payin if any
      let result = switch(_pay_to_vote){
        case(null) { #ok(); };
        case(?pay_to_vote) { await* pay_to_vote.payin(id, principal); };
      };
      
      switch(result) {
        case(#err(err)){ #err(err); };
        case(#ok(_)){
          // Add the ballot
          let old_ballot = Map.put(vote.ballots, Map.phash, principal, ballot);
          // Update the aggregate
          vote.aggregate := _policy.updateAggregate(vote.aggregate, ?ballot, old_ballot);
          // Link the vote to the voter
          let history = Option.get(Map.get(_register.voters_history, Map.phash, principal), Set.new<VoteId>(Map.nhash));
          Set.add(history, Map.nhash, id);
          Map.set(_register.voters_history, Map.phash, principal, history);
          #ok;
        };
      };
      
    };

    public func findVote(id: VoteId) : Result<Vote<T, A>, GetVoteError> {
      Result.fromOption(Map.get(_register.votes, Map.nhash, id), #VoteNotFound);
    }; 

    public func getVote(id: VoteId) : Vote<T, A> {
      switch(Map.get(_register.votes, Map.nhash, id)){
        case(null) { Debug.trap("Could not find a vote with ID '" # Nat.toText(id) # "'"); };
        case(?vote) { vote; };
      };
    };

    public func findBallot(principal: Principal, id: VoteId) : Result<Ballot<T>, FindBallotError> {
      let vote = switch(findVote(id)){
        case(#err(err)) { return #err(err); };
        case(#ok(v)) { v; };
      };
      Result.fromOption(Map.get(vote.ballots, Map.phash, principal), #BallotNotFound);
    };

    // @todo: used to compute the convictions only
    public func getVoterBallots(principal: Principal) : Map<VoteId, Ballot<T>> {
      let vote_ids = Option.get(Map.get(_register.voters_history, Map.phash, principal), Set.new<VoteId>(Map.nhash));
      let voter_ballots = Map.new<VoteId, Ballot<T>>(Map.nhash);
      for (vote_id in Set.keys(vote_ids)){
        let vote = getVote(vote_id);
        switch(Map.get(vote.ballots, Map.phash, principal)){
          case(null) { Debug.trap("Could not find a ballot for vote with ID '" # Nat.toText(vote_id) # "'"); };
          case(?ballot) { Map.set(voter_ballots, Map.nhash, vote_id, ballot); };
        };
      };
      voter_ballots;
    };

    public func revealVote(id: VoteId) : Result<Vote<T, A>, RevealVoteError> {
      Result.chain<Vote<T, A>, Vote<T, A>, RevealVoteError>(findVote(id), func(vote) {
        switch(vote.status){
          case(#OPEN) { #err(#VoteOpen); }; //@todo
          case(#CLOSED) { #ok(vote); };
        };
      });
    };

    public func revealBallot(caller: Principal, voter: Principal, vote_id: VoteId) : Result<RevealedBallot<T>, FindBallotError> {
      let vote = switch(findVote(vote_id)){
        case(#err(err)) { return #err(err); };
        case(#ok(v)) { v; };
      };
      let ballot = switch(Map.get(vote.ballots, Map.phash, voter)){
        case(null) { return #err(#BallotNotFound); };
        case(?b) { b; };
      };
      #ok({
        vote_id;
        date = ballot.date;
        answer = if (Principal.equal(caller, voter) or vote.status == #CLOSED) { ?ballot.answer; } else { null; };
        transactions_record = findBallotTransactions(voter, vote_id);
      });
    };

    public func revealBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : ScanLimitResult<RevealedBallot<T>> {
      let history_ids = Option.get(Map.get(_register.voters_history, Map.phash, voter), Set.new<VoteId>(Map.nhash));
      let filtered_ids = Utils.setScanLimit<VoteId>(history_ids, Map.nhash, direction, limit, previous_id);

      Utils.mapScanLimitResult<VoteId, RevealedBallot<T>>(filtered_ids, func(vote_id: VoteId) : RevealedBallot<T>{
        switch(revealBallot(caller, voter, vote_id)){
          case(#err(err)) { Debug.trap("@todo: error to text"); };
          case(#ok(ballot)) { ballot; };
        };
      });
    };

    public func findBallotTransactions(principal: Principal, id: VoteId) : ?TransactionsRecord {
      switch(_pay_to_vote){
        case(null) { null; };
        case(?pay_to_vote) { pay_to_vote.findTransactionsRecord(principal, id); };
      };
    };

  };

};