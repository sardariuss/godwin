import Types "../Types";
import StatusHelper "../StatusHelper";
import Questions "../Questions";
import Votes "Votes";
import Utils "../../utils/Utils";

import Result "mo:base/Result";
import Principal "mo:base/Principal";

module {

  type Time = Int;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Question = Types.Question;
  type Votes<T, A> = Votes.Votes<T, A>;
  type Ballot<T> = Types.Ballot<T>;
  type Questions = Questions.Questions;
  type GetAggregateError = Types.GetAggregateError;
  type GetBallotError = Types.GetBallotError;
  type RevealBallotError = Types.RevealBallotError;
  type PutBallotError = Types.PutBallotError;
  type PutFreshBallotError = Types.PutFreshBallotError;

  public class Poll<T, A>(poll_: Types.Poll, votes_: Votes<T, A>, questions_: Questions){

    public func getAggregate(question_id: Nat, iteration: Nat) : Result<A, GetAggregateError> {
      Result.chain<Question, A, GetAggregateError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        Result.mapOk<(), A, GetAggregateError>(Utils.toResult(canRevealVote(question, iteration), #NotAllowed), func(_) {
          votes_.getVote(question_id, iteration).aggregate;
        })
      });
    };

    public func getBallot(caller: Principal, principal: Principal, question_id: Nat, iteration: Nat) : Result<?Ballot<T>, GetBallotError> {
      Result.chain<Question, ?Ballot<T>, GetBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {     
        Result.mapOk<(), ?Ballot<T>, GetBallotError>(Utils.toResult(Principal.equal(caller, principal) or canRevealVote(question, iteration), #NotAllowed), func(_) {
          votes_.getBallot(principal, question_id, iteration);
        })
      });
    };

    public func putBallot(caller: Principal, question_id: Nat, iteration: Nat, date: Time, answer: T) : Result<(), PutBallotError> {
      Result.chain<(), (), PutBallotError>(Utils.toResult(not Principal.isAnonymous(caller), #PrincipalIsAnonymous), func(){
        Result.chain<Question, (), PutBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.chain<(), (), PutBallotError>(Utils.toResult(isCurrentPoll(question), #InvalidPoll), func(_) {
            let ballot = { answer; date; };
            Result.mapOk<(), (), PutBallotError>(Utils.toResult(votes_.isBallotValid(ballot), #InvalidBallot), func(_) {
              votes_.putBallot(caller, question_id, iteration, ballot);
            })
          })
        })
      });
    };

    public func putFreshBallot(caller: Principal, question_id: Nat, iteration: Nat, date: Time, answer: T) : Result<(), PutFreshBallotError> {
      Result.chain<(), (), PutFreshBallotError>(Utils.toResult(not Principal.isAnonymous(caller), #PrincipalIsAnonymous), func(){
        Result.chain<Question, (), PutFreshBallotError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Result.chain<(), (), PutFreshBallotError>(Utils.toResult(isCurrentPoll(question), #InvalidPoll), func(_) {
            Result.chain<(), (), PutFreshBallotError>(Utils.toResult(not votes_.hasBallot(caller, question_id, iteration), #AlreadyVoted), func(_) {
              let ballot = { answer; date; };
              Result.mapOk<(), (), PutFreshBallotError>(Utils.toResult(votes_.isBallotValid(ballot), #InvalidBallot), func(_) {
                votes_.putBallot(caller, question_id, iteration, ballot);
              })
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