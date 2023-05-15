import Types      "Types";
import UtilsTypes "../../utils/Types";
import Utils      "../../utils/Utils";

import Map        "mo:map/Map";
import Set        "mo:map/Set";

import Principal  "mo:base/Principal";
import Result     "mo:base/Result";
import Debug      "mo:base/Debug";
import Nat        "mo:base/Nat";
import Int        "mo:base/Int";
import Option     "mo:base/Option";

module {

  // For convenience: from base module
  type Principal          = Principal.Principal;
  type Result <Ok, Err>   = Result.Result<Ok, Err>;
    
  type Map<K, V>          = Map.Map<K, V>;
  type Set<K>             = Set.Set<K>;

  type ScanLimitResult<T> = UtilsTypes.ScanLimitResult<T>;

  type VoteId             = Types.VoteId;
  type Ballot<T>          = Types.Ballot<T>;
  type Vote<T, A>         = Types.Vote<T, A>;
  type GetVoteError       = Types.GetVoteError;
  type FindBallotError    = Types.FindBallotError;
  type RevealVoteError    = Types.RevealVoteError;

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

  public class Votes<T, A>(
    _register: Register<T, A>,
    _empty_aggregate: A
  ) {

    public func newVote() : VoteId {
      let index = _register.index;
      let vote : Vote<T, A> = {
        id = index;
        var status = #OPEN;
        ballots = Map.new<Principal, Ballot<T>>(Map.phash);
        var aggregate = _empty_aggregate; 
      };
      Map.set(_register.votes, Map.nhash, index, vote);
      _register.index += 1;
      index;
    };

    public func closeVote(id: VoteId) {
      switch(Map.get(_register.votes, Map.nhash, id)){
        case(null) { Debug.trap("Could not find a vote with ID '" # Nat.toText(id) # "'"); };
        case(?vote) {
          // Link the vote to the voters
          for (principal in Map.keys(vote.ballots)){
            let history = Option.get(Map.get(_register.voters_history, Map.phash, principal), Set.new<VoteId>(Map.nhash));
            Set.add(history, Map.nhash, id);
            Map.set(_register.voters_history, Map.phash, principal, history);
          };
          // Close the vote
          vote.status := #CLOSED;
          Map.set(_register.votes, Map.nhash, id, vote); 
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

    public func getBallot(principal: Principal, id: VoteId) : Ballot<T> {
      switch(Map.get(getVote(id).ballots, Map.phash, principal)){
        case(null) { Debug.trap("Could not find a ballot for principal '" # Principal.toText(principal) # "' for vote ID '" # Nat.toText(id) # "'"); };
        case(?ballot) { ballot; };
      };
    };

    public func findBallot(principal: Principal, id: VoteId) : Result<Ballot<T>, FindBallotError> {
      let vote = switch(findVote(id)){
        case(#err(err)) { return #err(err); };
        case(#ok(v)) { v; };
      };
      Result.fromOption(Map.get(vote.ballots, Map.phash, principal), #BallotNotFound);
    };

    public func getVoterBallots(principal: Principal, vote_ids: Set<VoteId>) : Map<VoteId, Ballot<T>> {
      // @todo: one shall rather iterate over the vote_ids
      Map.mapFilter(_register.votes, Map.nhash, func(id: VoteId, vote: Vote<T, A>) : ?Ballot<T> {
        if(Set.has(vote_ids, Map.nhash, id)){
          Map.get(vote.ballots, Map.phash, principal);
        } else {
          null;
        };
      });
    };

    public func revealVote(id: VoteId) : Result<Vote<T, A>, RevealVoteError> {
      Result.chain<Vote<T, A>, Vote<T, A>, RevealVoteError>(findVote(id), func(vote) {
        switch(vote.status){
          case(#OPEN) { #err(#VoteOpen); }; //@todo
          case(#CLOSED) { #ok(vote); };
        };
      });
    };

    public func getVoterHistory(principal: Principal) : Set<VoteId> {
      Option.get(Map.get(_register.voters_history, Map.phash, principal), Set.new<VoteId>(Map.nhash));
    };

  };

};