import Types "../Types";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";
import Observers "../Observers";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;

  type Map<K, V> = Map.Map<K, V>;

  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;

  // For convenience
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type QuestionId = Nat;
  type Iteration = Nat;
  type VoteStatus = Types.VoteStatus;

  func verifyStatus<T, A>(vote: Vote<T, A>, status: VoteStatus) {
    if (vote.status != status) {
      Debug.trap("Unexpected vote status");
    };
  };

  public class Votes<T, A>(
    register_: WMap2D<QuestionId, Iteration, Vote<T, A>>,
    empty_aggregate_: A,
    add_to_aggregate_: (A, T) -> A,
    remove_from_aggregate_: (A, T) -> A
  ) {

    let observers_ = Observers.Observers2<Vote<T, A>>();

    public func newVote(question_id: QuestionId, iteration: Iteration, date: Time){
      if (Option.isSome(register_.get(question_id, iteration))){
        Debug.trap("An aggregate already exists for this question and iteration");
      };
      let vote = { 
        question_id;
        iteration;
        date;
        status = #OPEN;
        ballots = Map.new<Principal, Ballot<T>>();
        aggregate = empty_aggregate_; 
      };
      updateVote(question_id, iteration, vote);
    };

    public func closeVote(question_id: QuestionId, iteration: Iteration){
      let vote = getVote(question_id, iteration);
      verifyStatus(vote, #OPEN);
      updateVote(question_id, iteration, { vote with status = #CLOSED; });
    };

    public func findVote(question_id: QuestionId, iteration: Iteration) : ?Vote<T, A> {
      register_.get(question_id, iteration);
    };

    public func getVote(question_id: QuestionId, iteration: Iteration) : Vote<T, A> {
      switch(findVote(question_id, iteration)){
        case(null) { Debug.trap("The vote does not exist"); };
        case(?vote) { vote; };
      };
    };

    public func removeVote(question_id: QuestionId, iteration: Iteration) {
      switch(register_.remove(question_id, iteration)){
        case(null) { Debug.trap("The vote does not exist"); };
        case(?vote) { observers_.callObs(?vote, null); };
      };
    };

    public func getBallot(principal: Principal, question_id: QuestionId, iteration: Iteration) : ?Ballot<T> {
      Map.get(getVote(question_id, iteration).ballots, Map.phash, principal);
    };

    public func putBallot(principal: Principal, question_id: QuestionId, iteration: Iteration, ballot: Ballot<T>) {
      let vote = getVote(question_id, iteration);
      verifyStatus(vote, #OPEN);
      let old_ballot = Map.put(vote.ballots, Map.phash, principal, ballot); // @todo: verify this works
      let aggregate = updateAggregate(vote.aggregate, ?ballot, old_ballot);
      updateVote(question_id, iteration, { vote with aggregate; });
    };

    public func removeBallot(principal: Principal, question_id: QuestionId, iteration: Iteration) {
      let vote = getVote(question_id, iteration);
      verifyStatus(vote, #OPEN);
      let old_ballot = Map.remove(vote.ballots, Map.phash, principal); // @todo: verify this works
      let aggregate = updateAggregate(vote.aggregate, null, old_ballot);
      updateVote(question_id, iteration, { vote with aggregate; });
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

    func updateVote(question_id: QuestionId, iteration: Iteration, new: Vote<T, A>) {
      let old = register_.put(question_id, iteration, new);
      observers_.callObs(old, ?new);
    };

  };

};