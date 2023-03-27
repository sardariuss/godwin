import Types "../../Types";
import Votes "../Votes";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type GetVoteError = Types.GetVoteError;
  type GetBallotError = Types.GetBallotError;
  
  public class ReadVote<T, A>(_votes: Votes.Votes<T, A>) {

    // @todo: should return a public vote
    public func revealVote(id: Nat) : Result<Vote<T, A>, GetVoteError> {
      let vote = switch(_votes.findVote(id)){
        case(null) { return #err(#QuestionVoteLinkNotFound2); };
        case(?v) { v; };
      };
      if (vote.status == #OPEN){
        return #err(#VoteIsOpen);
      };
      #ok(vote);
    }; 

    public func getBallot(principal: Principal, id: Nat) : Result<Ballot<T>, GetBallotError> {
      let vote = switch(_votes.findVote(id)){
        case(null) { return #err(#VoteNotFound); };
        case(?v) { v; };
      };
      Result.fromOption(Map.get(vote.ballots, Map.phash, principal), #BallotNotFound);
    };

  };

};