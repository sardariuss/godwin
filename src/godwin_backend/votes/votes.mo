import Types "../types";
import WMap "../wrappers/WMap";

import Map "mo:map/Map";

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

//  let vote_transitions : Map<?QuestionStatus, ?QuestionStatus>
//
//  CLOSE: 
//  #CANDIDATE; #REJECTED; => CloseInterest
//  #CANDIDATE; #OPINION; => CloseInterest
//  #OPINION; #CATEGORIZATION; => CloseOpinion
//
//  OPEN:
//  null; #CANDIDATE; => Interest
//  #CANDIDATE; #OPINION; => OpenOpinion
//  #OPINION; #CATEGORIZATION; => OpenCat
//  #CLOSED; #CANDIDATE; => OpenInterest
//
//  DELETE:
//  not null, null; => Delete vote for all history

  public class Votes<T, A>(
    votes_: WMap2D<QuestionId, Iteration, Vote<T, A>>,
    empty_aggregate_: A,
    add_to_aggregate_: (A, T) -> A,
    remove_from_aggregate_: (A, T) -> A
  ) {

    public func newVote(question_id: QuestionId, iteration: Iteration, date: Time){
      if (Option.isSome(votes_.get(question_id, iteration))){
        Debug.trap("An aggregate already exist for this question and iteration");
      };
      ignore votes_.put(
        question_id,
        iteration,
        { 
          question_id;
          iteration;
          date;
          status = #OPEN;
          ballots = Map.new<Principal, Ballot<T>>();
          aggregate = empty_aggregate_; 
        }
      );
    };

    public func closeVote(question_id: QuestionId, iteration: Iteration){
      let vote = getVote(question_id, iteration);
      verifyStatus(vote, #OPEN);
      ignore votes_.put(question_id, iteration, { vote with status = #CLOSED; });
    };

    public func findVote(question_id: QuestionId, iteration: Iteration) : ?Vote<T, A> {
      votes_.get(question_id, iteration);
    };

    public func getVote(question_id: QuestionId, iteration: Iteration) : Vote<T, A> {
      switch(findVote(question_id, iteration)){
        case(null) { Debug.trap("The vote does not exist"); };
        case(?vote) { vote; };
      };
    };

    public func getBallot(principal: Principal, question_id: QuestionId, iteration: Iteration) : ?Ballot<T> {
      Map.get(getVote(question_id, iteration).ballots, Map.phash, principal);
    };

    public func putBallot(principal: Principal, question_id: QuestionId, iteration: Iteration, date: Time, answer: T) {
      let vote = getVote(question_id, iteration);
      verifyStatus(vote, #OPEN);
      let new_ballot = { answer; date; };
      let old_ballot = Map.put(vote.ballots, Map.phash, principal, new_ballot);
      let aggregate = updateAggregate(vote.aggregate, ?new_ballot, old_ballot);
      ignore votes_.put(question_id, iteration, { vote with aggregate; });
    };

    public func removeBallot(principal: Principal, question_id: QuestionId, iteration: Iteration) {
      let vote = getVote(question_id, iteration);
      verifyStatus(vote, #OPEN);
      let old_ballot = Map.remove(vote.ballots, Map.phash, principal);
      let aggregate = updateAggregate(vote.aggregate, null, old_ballot);
      ignore votes_.put(question_id, iteration, { vote with aggregate; });
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

  };

};