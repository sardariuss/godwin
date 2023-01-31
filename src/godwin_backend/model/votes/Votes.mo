import Types "../Types";
import WMap "../../utils/wrappers/WMap";

import Map "mo:map/Map";
import Observers "../../utils/Observers";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;
  type Iter<T> = Iter.Iter<T>;

  type Map<K, V> = Map.Map<K, V>;

  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;

  // For convenience
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;

  public class Votes<T, A>(
    register_: WMap2D<Nat, Nat, Vote<T, A>>,
    neutral_answer_: T,
    is_valid_answer: (T) -> Bool,
    empty_aggregate_: A,
    add_to_aggregate_: (A, T) -> A,
    remove_from_aggregate_: (A, T) -> A
  ) {

    // Make sure at construction that the neutral answer is valid
    assert(is_valid_answer(neutral_answer_));

    let observers_ = Observers.Observers2<Vote<T, A>>();

    public func newVote(question_id: Nat, iteration: Nat, date: Time){
      if (Option.isSome(register_.get(question_id, iteration))){
        Debug.trap("A vote already exists for this question and iteration");
      };
      let vote = { 
        question_id;
        iteration;
        date;
        ballots = Map.new<Principal, Ballot<T>>();
        aggregate = empty_aggregate_; 
      };
      updateVote(question_id, iteration, vote);
    };

    public func findVote(question_id: Nat, iteration: Nat) : ?Vote<T, A> {
      register_.get(question_id, iteration);
    };

    public func getVote(question_id: Nat, iteration: Nat) : Vote<T, A> {
      switch(findVote(question_id, iteration)){
        case(null) { Debug.trap("The vote does not exist"); };
        case(?vote) { vote; };
      };
    };

    public func getVotes(question_id: Nat) : Iter<Vote<T, A>>{
      switch(register_.getAll(question_id)){
        case(null) { { next = func () : ?Vote<T, A> { null; }; }; };
        case(?votes){
          // @todo: test, because it assumes the votes have been added chronologically and the map keeps insertion order
          Map.vals(votes);
        };
      };
    };

    public func deleteVotes(question_id: Nat) {
      Option.iterate(register_.getAll(question_id), func(votes: Map<Nat, Vote<T, A>>){
        for (iteration in Map.keys(votes)){
          switch(register_.remove(question_id, iteration)){
            case(null)  { Prelude.unreachable(); };
            case(?vote) { observers_.callObs(?vote, null); };
          };
        };
      });
    };

    public func revealBallot(principal: Principal, question_id: Nat, iteration: Nat, date: Time) : Ballot<T> {
      Option.get(getBallot(principal, question_id, iteration), do {
        let ballot = { date; answer = neutral_answer_; };
        putBallot(principal, question_id, iteration, ballot); 
        ballot;
      });
    };

    public func getBallot(principal: Principal, question_id: Nat, iteration: Nat) : ?Ballot<T> {
      Map.get(getVote(question_id, iteration).ballots, Map.phash, principal);
    };

    public func putBallot(principal: Principal, question_id: Nat, iteration: Nat, ballot: Ballot<T>) {
      if (not isBallotValid(ballot)){
        Debug.trap("The ballot is not valid");
      };
      let vote = getVote(question_id, iteration);
      let old_ballot = Map.put(vote.ballots, Map.phash, principal, ballot); // @todo: verify this works
      let aggregate = updateAggregate(vote.aggregate, ?ballot, old_ballot);
      updateVote(question_id, iteration, { vote with aggregate; });
    };

    public func removeBallot(principal: Principal, question_id: Nat, iteration: Nat) {
      let vote = getVote(question_id, iteration);
      let old_ballot = Map.remove(vote.ballots, Map.phash, principal); // @todo: verify this works
      let aggregate = updateAggregate(vote.aggregate, null, old_ballot);
      updateVote(question_id, iteration, { vote with aggregate; });
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
      aggregate;
    };

    func updateVote(question_id: Nat, iteration: Nat, new: Vote<T, A>) {
      let old = register_.put(question_id, iteration, new);
      observers_.callObs(old, ?new);
    };

  };

};