import Types         "Types";
import PayToVote     "PayToVote";
import PayTypes      "../token/Types";

import Utils         "../../utils/Utils";
import UtilsTypes    "../../utils/Types";

import Map           "mo:map/Map";
import Set           "mo:map/Set";

import Principal     "mo:base/Principal";
import Result        "mo:base/Result";
import Debug         "mo:base/Debug";
import Nat           "mo:base/Nat";
import Int           "mo:base/Int";
import Option        "mo:base/Option";
import Nat32         "mo:base/Nat32";
import Array         "mo:base/Array";
import Prim          "mo:prim";


module {

  // For convenience: from base module
  type Time                      = Int;
  type Principal                 = Principal.Principal;
  type Result <Ok, Err>          = Result.Result<Ok, Err>;
    
  type Map<K, V>                 = Map.Map<K, V>;
  type Set<K>                    = Set.Set<K>;

  type VoteId                    = Types.VoteId;
  type Ballot<T>                 = Types.Ballot<T>;
  type RevealableBallot<T>         = Types.RevealableBallot<T>;
  type Vote<T, A>                = Types.Vote<T, A>;
  type VoteStatus                = Types.VoteStatus;
  type GetVoteError              = Types.GetVoteError;
  type FindBallotError           = Types.FindBallotError;
  type RevealVoteError           = Types.RevealVoteError;
  type PutBallotError            = Types.PutBallotError;
  type IVotePolicy<T, A>         = Types.IVotePolicy<T, A>;
  type IVotersHistory            = Types.IVotersHistory;

  type ScanLimitResult<K>        = UtilsTypes.ScanLimitResult<K>;
  type Direction                 = UtilsTypes.Direction;
  
  type TransactionsRecord        = PayTypes.TransactionsRecord;

  type PayToVote<T, A>           = PayToVote.PayToVote<T, A>;

  public func ballotToText<T>(ballot: Ballot<T>, toText: (T) -> Text) : Text {
    "Ballot: { date = " # Int.toText(ballot.date) # "; answer = " # toText(ballot.answer) # "; }";
  };

  public func ballotsEqual<T>(ballot1: Ballot<T>, ballot2: Ballot<T>, equal: (T, T) -> Bool) : Bool {
    Int.equal(ballot1.date, ballot2.date) and equal(ballot1.answer, ballot2.answer);
  };

  public type Register<T, A> = {
    votes: Map<VoteId, Vote<T, A>>;
    var index: VoteId;
  };

  public func initRegister<T, A>() : Register<T, A> {
    {
      votes = Map.new<VoteId, Vote<T, A>>(Map.nhash);
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
    _voters_history: IVotersHistory,
    _policy: IVotePolicy<T, A>,
    _pay_to_vote: ?PayToVote<T, A>
  ) {

    let _ballot_locks = Set.new<(Principal, VoteId)>(pnhash);

    public func newVote(date: Time) : VoteId {
      let index = _register.index;
      let vote : Vote<T, A> = initVote(index, _policy.emptyAggregate(date));
      Map.set(_register.votes, Map.nhash, index, vote);
      _register.index += 1;
      index;
    };

    public func lockVote(id: VoteId, date: Time) {
      setStatus(id, date, #LOCKED);
    };

    public func closeVote(id: VoteId, date: Time) : async*() {
      setStatus(id, date, #CLOSED);
      // Payout if any
      switch(_pay_to_vote){
        case(null) {};
        case(?pay_to_vote) { await* pay_to_vote.payout(getVote(id)); };
      };
    };

    public func canVote(vote_id: VoteId, principal: Principal) : Result<(), PutBallotError> {
      
      let vote = getVote(vote_id);

      // Anonymous cannot vote
      if (Principal.isAnonymous(principal)){
        return #err(#PrincipalIsAnonymous);
      };
      // The vote must not be closed
      if (vote.status == #CLOSED){
        return #err(#VoteClosed);
      };
      // Verify if the user can vote according to the set policy
      switch(_policy.canVote(vote, principal)){
        case(#err(err)) { #err(err); };
        case(#ok(_)) { #ok; };
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

    func _putBallot(principal: Principal, vote_id: VoteId, ballot: Ballot<T>) : async* Result<(), PutBallotError> {

      // Verify the vote exists
      let vote = switch(findVote(vote_id)){
        case(#err(err)) { return #err(err); };
        case(#ok(v)) { v; };
      };

      // Verify the ballot is valid
      switch(_policy.isValidBallot(ballot)){
        case(#err(err)) { return #err(err); };
        case(#ok) {};
      };

      // Verify the user can vote
      switch(canVote(vote_id, principal)){
        case(#err(err)) { return #err(err); };
        case(#ok) {};
      };

      // Determine if the aggregate shall be updated before calling the async payin.
      // If done after the payin, it is possible that a user successfully puts a ballot
      // but that it does not change the result of the vote (in the case the vote closes 
      // during the payin). We want to prevent that.
      let update_aggregate = (vote.status == #OPEN);

      // Payin if any
      let result = switch(_pay_to_vote){
        case(null) { #ok; };
        case(?pay_to_vote) { await* pay_to_vote.payin(vote_id, principal); };
      };
      
      switch(result) {
        case(#err(err)){ #err(err); };
        case(#ok(_)){
          // Get the up-to-date vote (it is required to get it here because it might have changed during the async call)
          let updated_vote = getVote(vote_id);
          // Put the ballot
          let old_ballot = Map.put(updated_vote.ballots, Map.phash, principal, ballot);
          // Update the aggregate if applicable
          if(update_aggregate){
            updated_vote.aggregate := _policy.addToAggregate(updated_vote.aggregate, ballot, old_ballot);
          };
          // Add the vote to the voter's history
          _voters_history.addVote(principal, vote_id);
          #ok;
        };
      };
      
    };

    public func findVote(id: VoteId) : Result<Vote<T, A>, GetVoteError> {
      Result.fromOption(Map.get(_register.votes, Map.nhash, id), #VoteNotFound);
    }; 

    public func getVote(id: VoteId) : Vote<T, A> {
      switch(Map.get(_register.votes, Map.nhash, id)){
        case(null) { Debug.trap("Could not find a vote '" # Nat.toText(id) # "'"); };
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

    public func getVoterBallots(voter: Principal) : Map<VoteId, Ballot<T>> {
      let voter_ballots = Map.new<VoteId, Ballot<T>>(Map.nhash);
      for (vote_id in Array.vals(_voters_history.getVoterHistory(voter))){
        switch(Map.get(getVote(vote_id).ballots, Map.phash, voter)){
          case(null) { Debug.trap("Could not find a ballot for vote with ID '" # Nat.toText(vote_id) # "'"); };
          case(?ballot) { Map.set(voter_ballots, Map.nhash, vote_id, ballot); };
        };
      };
      voter_ballots;
    };

    public func hasBallot(principal: Principal, vote_id: VoteId) : Bool {
      Map.has(getVote(vote_id).ballots, Map.phash, principal);
    };

    public func revealVote(id: VoteId) : Result<Vote<T, A>, RevealVoteError> {
      Result.chain<Vote<T, A>, Vote<T, A>, RevealVoteError>(findVote(id), func(vote) {
        if(vote.status == #OPEN){
          #err(#VoteOpen); // @todo
        } else {
          #ok(vote);
        };
      });
    };

    public func revealBallot(caller: Principal, voter: Principal, vote_id: VoteId) : Result<RevealableBallot<T>, FindBallotError> {
      let vote = switch(findVote(vote_id)){
        case(#err(err)) { return #err(err); };
        case(#ok(v)) { v; };
      };
      let ballot = switch(Map.get(vote.ballots, Map.phash, voter)){
        case(null) { return #err(#BallotNotFound); };
        case(?b) { b; };
      };
      let answer = if(_policy.canRevealBallot(vote, caller, voter)) { #REVEALED(ballot.answer); } else { #HIDDEN; };
      let can_change = Result.isOk(canVote(vote_id, caller));
      #ok({ vote_id; date = ballot.date; can_change; answer; });
    };

    public func findBallotTransactions(principal: Principal, id: VoteId) : ?TransactionsRecord {
      switch(_pay_to_vote){
        case(null) { null; };
        case(?pay_to_vote) { pay_to_vote.findTransactionsRecord(principal, id); };
      };
    };

    func setStatus(vote_id: VoteId, date: Time, new: VoteStatus) {
      let vote = getVote(vote_id);
      let error = "Cannot set status for vote '" # Nat.toText(vote_id) # "' : ";

      switch((vote.status, new)){
        case(_, #OPEN) { Debug.trap(error # "cannot reopen a vote"); };
        case(#LOCKED, #LOCKED) { Debug.trap(error # "it is already locked"); };
        case(#CLOSED, #LOCKED) { Debug.trap(error # "cannot lock a closed vote"); };
        case(#CLOSED, #CLOSED) { Debug.trap(error # "it is already closed"); };
        case(_, _) { };
      };

      vote.status := new;
      vote.aggregate := _policy.onStatusChanged(new, vote.aggregate, date);
      Map.set(_register.votes, Map.nhash, vote_id, vote); // @todo: not required ?
    };

  };

};