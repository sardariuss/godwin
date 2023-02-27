import Types "../Types";
import StatusHelper "../StatusHelper";
import Questions "../Questions";
import Votes2 "Votes2";
import Utils "../../utils/Utils";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";

module {

  type Time = Int;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Status = Types.Status;
  type Question = Types.Question;
  type Votes2<T, A> = Votes2.Votes2<T, A>;
  type Ballot<T> = Types.Ballot<T>;
  type Questions = Questions.Questions;
  type GetAggregateError = Types.GetAggregateError;
  type GetBallotError = Types.GetBallotError;
  type RevealBallotError = Types.RevealBallotError;
  type PutBallotError = Types.PutBallotError;
  type PutFreshBallotError = Types.PutFreshBallotError;
  type Vote2<T, A> = Types.Vote2<T, A>;

  public class Poll<T, A>(votes_: Votes2<T, A>){

    public func findBallot(caller: Principal, question_id: Nat) : Result<?Ballot<T>, GetBallotError> {
      Result.mapOk<Vote2<T, A>, ?Ballot<T>, GetBallotError>(Result.fromOption(votes_.findVote(question_id), #QuestionNotFound), func(_) {
        votes_.findBallot(caller, question_id);
      });
    };

    // @todo: can remove (but still need to err on vote not found, verify not anonymous and if ballot is valid)
    public func putBallot(caller: Principal, question_id: Nat, date: Time, answer: T) : Result<(), PutBallotError> {
      Result.chain<(), (), PutBallotError>(Utils.toResult(not Principal.isAnonymous(caller), #PrincipalIsAnonymous), func(){
        Result.chain<Vote2<T, A>, (), PutBallotError>(Result.fromOption(votes_.findVote(question_id), #QuestionNotFound), func(_) {
          let ballot = { answer; date; };
          Result.mapOk<(), (), PutBallotError>(Utils.toResult(votes_.isBallotValid(ballot), #InvalidBallot), func(_) {
            votes_.putBallot(caller, question_id, ballot);
          })
        })
      });
    };

    public func putFreshBallot(caller: Principal, question_id: Nat, date: Time, answer: T) : Result<(), PutFreshBallotError> {
      Result.chain<(), (), PutFreshBallotError>(Utils.toResult(not Principal.isAnonymous(caller), #PrincipalIsAnonymous), func(){
        Result.chain<Vote2<T, A>, (), PutFreshBallotError>(Result.fromOption(votes_.findVote(question_id), #QuestionNotFound), func(_) {
          Result.chain<(), (), PutFreshBallotError>(Utils.toResult(not votes_.hasBallot(caller, question_id), #AlreadyVoted), func(_) {
            let ballot = { answer; date; };
            Result.mapOk<(), (), PutFreshBallotError>(Utils.toResult(votes_.isBallotValid(ballot), #InvalidBallot), func(_) {
              votes_.putBallot(caller, question_id, ballot);
            })
          })
        })
      });
    };

  };

};