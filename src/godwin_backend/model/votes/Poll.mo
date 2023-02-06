import Types "../Types";
import StatusHelper "../StatusHelper";
import Questions "../Questions";
import Votes "Votes";
import Utils "../../utils/Utils";

import Debug "mo:base/Debug";
import Result "mo:base/Result";

module {

  type Time = Int;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Question = Types.Question;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Ballot<T> = Types.Ballot<T>;
  type Questions = Questions.Questions;

  type GetAggregateError = {
    #QuestionNotFound;
    #VoteOngoing;
  };

  type GetBallotError = {
    #QuestionNotFound;
    #VoteOngoing;
  };

  type RevealBallotError = {
    #QuestionNotFound;
    #InvalidPoll;
  };

  type PutBallotError = {
    #QuestionNotFound;
    #InvalidPoll;
    #InvalidBallot;
  };

  type PutFreshBallotError = {
    #QuestionNotFound;
    #InvalidPoll;
    #UserAlreadyVoted;
    #InvalidBallot;
  };

  public class Poll<T, A>(poll_: Types.Poll, votes_: Votes<T, A>, questions_: Questions){

    public func openVote(question_id: Nat) {
      let question = questions_.getQuestion(question_id);
      let indexed_status = StatusHelper.getCurrent(question);
      switch(indexed_status.status){
        case(#VOTING(poll)) { votes_.newVote(question_id, indexed_status.index, indexed_status.date); };
        case(_)             { Debug.trap("Cannot open vote: wrong question status"); };
      };
    };

    public func deleteVotes(question_id: Nat) {
      let question = questions_.getQuestion(question_id);
      let indexed_status = StatusHelper.getCurrent(question);
      switch(indexed_status.status){
        case(#TRASH) { votes_.deleteVotes(question_id); };
        case(_)      { Debug.trap("Cannot remove vote: wrong question status"); };
      };
    };

    public func getAggregate(question_id: Nat, iteration: Nat) : A {
      let question = questions_.getQuestion(question_id);
      if (not canRevealVote(question, iteration)) {
        Debug.trap("Cannot reveal vote");
      };
      votes_.getVote(question_id, iteration).aggregate;
    };

    public func tryGetAggregate(question_id: Nat, iteration: Nat) : Result<A, GetAggregateError> {
      Result.chain<Question, A, GetAggregateError>(questions_.tryGetQuestion(question_id), func(question) {
        Result.mapOk<(), A, GetAggregateError>(Utils.toResult(canRevealVote(question, iteration), #VoteOngoing), func(_) {
          votes_.getVote(question_id, iteration).aggregate;
        })
      });
    };

    public func tryGetBallot(principal: Principal, question_id: Nat, iteration: Nat) : Result<?Ballot<T>, GetBallotError> {
      Result.chain<Question, ?Ballot<T>, GetBallotError>(questions_.tryGetQuestion(question_id), func(question) {
        Result.mapOk<(), ?Ballot<T>, GetBallotError>(Utils.toResult(canRevealVote(question, iteration), #VoteOngoing), func(_) {
          votes_.getBallot(principal, question_id, iteration);
        })
      });
    };

    public func tryRevealBallot(principal: Principal, question_id: Nat, iteration: Nat, date: Time) : Result<Ballot<T>, RevealBallotError> {
      Result.chain<Question, Ballot<T>, RevealBallotError>(questions_.tryGetQuestion(question_id), func(question) {
        Result.mapOk<(), Ballot<T>, RevealBallotError>(Utils.toResult(isCurrentPoll(question), #InvalidPoll), func(_) {
          votes_.revealBallot(principal, question_id, iteration, date);
        })
      });
    };

    public func tryPutBallot(principal: Principal, question_id: Nat, iteration: Nat, date: Time, answer: T) : Result<(), PutBallotError> {
      Result.chain<Question, (), PutBallotError>(questions_.tryGetQuestion(question_id), func(question) {
        Result.chain<(), (), PutBallotError>(Utils.toResult(isCurrentPoll(question), #InvalidPoll), func(_) {
          let ballot = { answer; date; };
          Result.mapOk<(), (), PutBallotError>(Utils.toResult(votes_.isBallotValid(ballot), #InvalidBallot), func(_) {
            votes_.putBallot(principal, question_id, iteration, ballot);
          })
        })
      });
    };

    public func tryPutFreshBallot(principal: Principal, question_id: Nat, iteration: Nat, date: Time, answer: T) : Result<(), PutFreshBallotError> {
      Result.chain<Question, (), PutFreshBallotError>(questions_.tryGetQuestion(question_id), func(question) {
        Result.chain<(), (), PutFreshBallotError>(Utils.toResult(isCurrentPoll(question), #InvalidPoll), func(_) {
          Result.chain<(), (), PutFreshBallotError>(Utils.toResult(votes_.hasBallot(principal, question_id, iteration), #UserAlreadyVoted), func(_) {
            let ballot = { answer; date; };
            Result.mapOk<(), (), PutFreshBallotError>(Utils.toResult(votes_.isBallotValid(ballot), #InvalidBallot), func(_) {
              votes_.putBallot(principal, question_id, iteration, ballot);
            })
          })
        })
      });
    };

    func canRevealVote(question: Question, iteration: Nat) : Bool {
      let status_info = StatusHelper.StatusInfo(question.status_info);
      let current_status = status_info.getCurrentStatus();
      current_status == #REJECTED or current_status == #CLOSED or iteration < status_info.getIteration(#VOTING(poll_));
    };

    func isCurrentPoll(question: Question) : Bool {
      question.status_info.current.status == #VOTING(poll_);
    };

  };

};