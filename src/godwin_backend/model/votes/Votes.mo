import Types     "Types";
import Utils     "../../utils/Utils";

import Map       "mo:map/Map";

import Principal "mo:base/Principal";
import Result    "mo:base/Result";
import Debug     "mo:base/Debug";
import Nat       "mo:base/Nat";
import Int       "mo:base/Int";

module {

  // For convenience: from base module
  type Principal        = Principal.Principal;
  type Result <Ok, Err> = Result.Result<Ok, Err>;
  
  type Map<K, V>        = Map.Map<K, V>;

  type Ballot<T>        = Types.Ballot<T>;
  type Vote<T, A>       = Types.Vote<T, A>;
  type PublicVote<T, A> = Types.PublicVote<T, A>;
  type CloseVoteError   = Types.CloseVoteError;
  type GetVoteError     = Types.GetVoteError;
  type GetBallotError   = Types.GetBallotError;

  public func toPublicVote<T, A>(vote: Vote<T, A>) : PublicVote<T, A> {
    {
      id = vote.id;
      ballots = Utils.mapToArray(vote.ballots);
      aggregate = vote.aggregate;
    }
  };

  public func ballotToText<T>(ballot: Ballot<T>, toText: (T) -> Text) : Text {
    "Ballot: { date = " # Int.toText(ballot.date) # "; answer = " # toText(ballot.answer) # "; }";
  };

  public func ballotsEqual<T>(ballot1: Ballot<T>, ballot2: Ballot<T>, equal: (T, T) -> Bool) : Bool {
    Int.equal(ballot1.date, ballot2.date) and equal(ballot1.answer, ballot2.answer);
  };

  public type Register<T, A> = {
    votes: Map<Nat, Vote<T, A>>;
    var index: Nat;
  };

  public func initRegister<T, A>() : Register<T, A> {
    {
      votes = Map.new<Nat, Vote<T, A>>(Map.nhash);
      var index = 0;
    }
  };

  public class Votes<T, A>(
    _register: Register<T, A>,
    _empty_aggregate: A
  ) {

    public func newVote() : Nat {
      let index = _register.index;
      let vote : Vote<T, A> = {
        id = index;
        ballots = Map.new<Principal, Ballot<T>>(Map.phash);
        var aggregate = _empty_aggregate; 
      };
      Map.set(_register.votes, Map.nhash, index, vote);
      _register.index += 1;
      index;
    };

    public func findVote(id: Nat) : Result<Vote<T, A>, GetVoteError> {
      Result.fromOption(Map.get(_register.votes, Map.nhash, id), #VoteNotFound);
    }; 

    public func getVote(id: Nat) : Vote<T, A> {
      switch(Map.get(_register.votes, Map.nhash, id)){
        case(null) { Debug.trap("Could not find a vote with ID '" # Nat.toText(id) # "'"); };
        case(?vote) { vote; };
      };
    };

    public func getBallot(principal: Principal, id: Nat) : Result<Ballot<T>, GetBallotError> {
      let vote = switch(findVote(id)){
        case(#err(err)) { return #err(err); };
        case(#ok(v)) { v; };
      };
      Result.fromOption(Map.get(vote.ballots, Map.phash, principal), #BallotNotFound);
    };

  };

};