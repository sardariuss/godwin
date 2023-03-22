import Types "../Types";
import WMap "../../utils/wrappers/WMap";
import Utils "../../utils/Utils";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Buffer<T> = Buffer.Buffer<T>;
  type Result <Ok, Err> = Result.Result<Ok, Err>;
  
  type Map<K, V> = Map.Map<K, V>;
  type WMap<K, V> = WMap.WMap<K, V>;

  type VoteStatus = Types.VoteStatus;
  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type PublicVote<T, A> = Types.PublicVote<T, A>;
  
  type CloseVoteError = Types.CloseVoteError;

  public func toPublicVote<T, A>(vote: Vote<T, A>) : PublicVote<T, A> {
    {
      id = vote.id;
      status = vote.status;
      ballots = Utils.mapToArray(vote.ballots);
      aggregate = vote.aggregate;
    }
  };

  public type Callback<A> = (Nat, ?A, ?A) -> ();

  public type VoteRegister<T, A> = {
    votes: Map<Nat, Vote<T, A>>;
    var index: Nat;
  };

  public func initRegister<T, A>() : VoteRegister<T, A> {
    {
      votes = Map.new<Nat, Vote<T, A>>();
      var index = 0;
    }
  };

  public class Votes2<T, A>(
    register_: VoteRegister<T, A>,
    empty_aggregate_: A
  ) {

    let observers_ = Buffer.Buffer<Callback<A>>(0);

    public func newVote() : Nat {
      let index = register_.index;
      let vote : Vote<T, A> = {
        id = index;
        var status = #OPEN;
        ballots = Map.new<Principal, Ballot<T>>();
        var aggregate = empty_aggregate_; 
      };
      Map.set(register_.votes, Map.nhash, index, vote);
      register_.index += 1;
      notifyObs(index, null, ?vote.aggregate);
      index;
    };

    public func closeVote(id: Nat) : Result<Vote<T, A>, CloseVoteError> {
      // Get the vote
      let vote = switch(findVote(id)){
        case(null) { return #err(#VoteNotFound); };
        case(?vote) { vote; };
      };
      // Check if not already closed
      if (vote.status == #CLOSED) {
        return #err(#AlreadyClosed);
      };
      // Close the vote
      vote.status := #CLOSED;
      // Notify the observers
      notifyObs(id, ?vote.aggregate, null);
      #ok(vote);
    };

    public func findVote(id: Nat) : ?Vote<T, A> {
      Map.get(register_.votes, Map.nhash, id);
    };

    public func addObs(callback: (Nat, ?A, ?A) -> ()) {
      observers_.add(callback);
    };

    public func notifyObs(id: Nat, old: ?A, new: ?A) {
      for (obs_func in observers_.vals()){
        obs_func(id, old, new);
      };
    };

  };

};