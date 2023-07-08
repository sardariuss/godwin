import Types               "Types";
import QuestionTypes       "questions/Types";
import VoteTypes           "votes/Types";
import Controller          "controller/Controller";
import Categories          "Categories";

import Utils               "../utils/Utils";

import StableBuffer        "mo:stablebuffer/StableBuffer";
import Map                 "mo:map/Map";
import Set                 "mo:map/Set";

import Result              "mo:base/Result";
import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Iter                "mo:base/Iter";
import Buffer              "mo:base/Buffer";
import Array               "mo:base/Array";

module {

  // For convenience: from base module
  type Result<Ok, Err>              = Result.Result<Ok, Err>;
  type Principal                    = Principal.Principal;
  type Time                         = Int;
  type Buffer<T>                    = Buffer.Buffer<T>;
  type StableBuffer<T>              = StableBuffer.StableBuffer<T>;

  // For convenience: from other modules
  type Controller                   = Controller.Controller;

  // For convenience: from types module
  type QuestionId                   = Types.QuestionId;
  type QuestionOrderBy              = Types.QuestionOrderBy;
  type Interest                     = Types.Interest;
  type Appeal                       = Types.Appeal;
  type CursorArray                  = Types.CursorArray;
  type PolarizationArray            = Types.PolarizationArray;
  type CategoryInfo                 = Types.CategoryInfo;
  type CategoryArray                = Types.CategoryArray;
  type InterestVote                 = Types.InterestVote;
  type OpinionVote                  = Types.OpinionVote;
  type CategorizationVote           = Types.CategorizationVote;
  type InterestBallot               = Types.InterestBallot;
  type OpinionBallot                = Types.OpinionBallot;
  type CategorizationBallot         = Types.CategorizationBallot;
  type ShareableVote<T, A>          = Types.Vote<T, A>;
  type RevealedInterestBallot       = Types.RevealedInterestBallot;
  type RevealedOpinionBallot        = Types.RevealedOpinionBallot;
  type RevealedCategorizationBallot = Types.RevealedCategorizationBallot;
  type Direction                    = Types.Direction;
  type ScanLimitResult<K>           = Types.ScanLimitResult<K>;
  type FindQuestionIterationError   = Types.FindQuestionIterationError;
  type VoteKind                     = Types.VoteKind;
  type TransactionsRecord           = Types.TransactionsRecord;
  type SchedulerParameters          = Types.SchedulerParameters;
  type Duration                     = Types.Duration;
  type UserQuestionBallots<T>       = Types.UserQuestionBallots<T>;
  type Question                     = QuestionTypes.Question;
  type Status                       = QuestionTypes.Status;
  type StatusHistoryMap             = QuestionTypes.StatusHistory;
  type StatusInfo                   = QuestionTypes.StatusInfo;
  type StatusHistory                = QuestionTypes.StatusHistory;
  type Category                     = VoteTypes.Category;
  type Ballot<T>                    = VoteTypes.Ballot<T>;
  type Vote<T, A>                   = VoteTypes.Vote<T, A>;
  type RevealedBallot<T>            = VoteTypes.RevealedBallot<T>;
  type Cursor                       = VoteTypes.Cursor;
  type Polarization                 = VoteTypes.Polarization;
  type CursorMap                    = VoteTypes.CursorMap;
  type PolarizationMap              = VoteTypes.PolarizationMap;
  type VoteId                       = VoteTypes.VoteId;

  // Errors
  type AddCategoryError             = Types.AddCategoryError;
  type RemoveCategoryError          = Types.RemoveCategoryError;
  type GetQuestionError             = Types.GetQuestionError;
  type ReopenQuestionError          = Types.ReopenQuestionError;
  type VerifyCredentialsError       = Types.VerifyCredentialsError;
  type SetPickRateError             = Types.SetPickRateError;
  type SetSchedulerParametersError  = Types.SetSchedulerParametersError;
  type FindBallotError              = Types.FindBallotError;
  type PutBallotError               = Types.PutBallotError;
  type GetVoteError                 = Types.GetVoteError;
  type OpenVoteError                = Types.OpenVoteError;
  type RevealVoteError              = Types.RevealVoteError;
  type OpenQuestionError            = Types.OpenQuestionError; // @todo
  type FindVoteError                = Types.FindVoteError;

  public class Facade(_controller: Controller) = {

    public func getName() : Text {
      _controller.getName();
    };

    public func getHalfLife() : Duration {
      _controller.getHalfLife();
    };

    public func getSelectionScore(now: Time) : Float {
      _controller.getSelectionScore(now);
    };

    public func getCategories() : CategoryArray {
      Iter.toArray(_controller.getCategories().entries());
    };

    public func addCategory(caller: Principal, category: Category, info: CategoryInfo) : Result<(), AddCategoryError> {
      _controller.addCategory(caller, category, info);
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      _controller.removeCategory(caller, category);
    };

    public func getSchedulerParameters() : SchedulerParameters {
      _controller.getSchedulerParameters();
    };

    public func setSchedulerParameters(caller: Principal, params: SchedulerParameters) : Result<(), SetSchedulerParametersError> {
      _controller.setSchedulerParameters(caller, params);
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      _controller.searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      _controller.getQuestion(question_id);
    };

    public func queryQuestions(order_by: QuestionOrderBy, direction: Direction, limit: Nat, previous_id: ?Nat) : ScanLimitResult<VoteId> {
      _controller.queryQuestions(order_by, direction, limit, previous_id);
    };

    public func openQuestion(caller: Principal, text: Text, date: Time) : async* Result<QuestionId, OpenQuestionError> {
      await* _controller.openQuestion(caller, text, date);
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async* Result<(), [(?Status, Text)]> {
      await* _controller.reopenQuestion(caller, question_id, date);
    };

    public func getInterestBallot(caller: Principal, vote_id: VoteId) : Result<RevealedInterestBallot, FindBallotError> {
      _controller.getInterestBallot(caller, vote_id);
    };

    public func putInterestBallot(principal: Principal, vote_id: VoteId, date: Time, interest: Interest) : async* Result<(), PutBallotError> {
      await* _controller.putInterestBallot(principal, vote_id, date, interest);
    };

    public func getOpinionBallot(caller: Principal, vote_id: VoteId) : Result<RevealedOpinionBallot, FindBallotError> {
      _controller.getOpinionBallot(caller, vote_id);
    };

    public func putOpinionBallot(principal: Principal, vote_id: VoteId, date: Time, cursor: Cursor) : async* Result<(), PutBallotError> {
      await* _controller.putOpinionBallot(principal, vote_id, date, cursor);
    };
      
    public func getCategorizationBallot(caller: Principal, vote_id: VoteId) : Result<RevealedCategorizationBallot, FindBallotError> {
      Result.mapOk(_controller.getCategorizationBallot(caller, vote_id), func(revealed_ballot: RevealedBallot<CursorMap>) : RevealedCategorizationBallot {
        { revealed_ballot with answer = Option.map(revealed_ballot.answer, func(ans: CursorMap) : CursorArray { Utils.trieToArray(ans); }); };
      });
    };
      
    public func putCategorizationBallot(principal: Principal, vote_id: VoteId, date: Time, cursors: CursorArray) : async* Result<(), PutBallotError> {
      await* _controller.putCategorizationBallot(principal, vote_id, date, Utils.arrayToTrie(cursors, Categories.key, Categories.equal));
    };

    public func getStatusHistory(question_id: Nat) : Result<[StatusInfo], ReopenQuestionError> {
      Result.mapOk<StatusHistory, [StatusInfo], ReopenQuestionError>(
        _controller.getStatusHistory(question_id), func(history: StableBuffer<StatusInfo>) : [StatusInfo] {
          StableBuffer.toArray<StatusInfo>(history);
        });
    };

    public func revealInterestVote(vote_id: VoteId) : Result<InterestVote, RevealVoteError> {
      Result.mapOk<Vote<Interest, Appeal>, InterestVote, RevealVoteError>(_controller.revealInterestVote(vote_id), func(vote: Vote<Interest, Appeal>) : InterestVote {
        toShareableVote(vote);
      });
    };

    public func revealOpinionVote(vote_id: VoteId) : Result<OpinionVote, RevealVoteError> {
      Result.mapOk<Vote<Cursor, Polarization>, OpinionVote, RevealVoteError>(_controller.revealOpinionVote(vote_id), func(vote: Vote<Cursor, Polarization>) : OpinionVote {
        toShareableVote(vote);
      });
    };

    public func revealCategorizationVote(vote_id: VoteId) : Result<CategorizationVote, RevealVoteError> {
      Result.mapOk<Vote<CursorMap, PolarizationMap>, CategorizationVote, RevealVoteError>(_controller.revealCategorizationVote(vote_id), func(vote: Vote<CursorMap, PolarizationMap>) : CategorizationVote {
        toShareableCategorizationVote(vote);
      });
    };

    public func findInterestVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _controller.findInterestVoteId(question_id, iteration);
    };

    public func findOpinionVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _controller.findOpinionVoteId(question_id, iteration);
    };

    public func findCategorizationVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      _controller.findCategorizationVoteId(question_id, iteration);
    };

    public func queryInterestBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId
    ) : ScanLimitResult<UserQuestionBallots<Interest>> {
      _controller.queryInterestBallots(caller, voter, direction, limit, previous_id);
    };

    public func queryOpinionBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId
    ) : ScanLimitResult<UserQuestionBallots<Cursor>> {
      _controller.queryOpinionBallots(caller, voter, direction, limit, previous_id);
    };

    public func queryCategorizationBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId
    ) : ScanLimitResult<UserQuestionBallots<CursorArray>> {
      Utils.mapScanLimitResult<UserQuestionBallots<CursorMap>, UserQuestionBallots<CursorArray>>(
        _controller.queryCategorizationBallots(caller, voter, direction, limit, previous_id),
        func(question_ballots : UserQuestionBallots<CursorMap>) : UserQuestionBallots<CursorArray> {
          let ballots = Array.mapEntries<(Nat, Bool, RevealedBallot<CursorMap>), (Nat, Bool, RevealedBallot<CursorArray>)>(
            question_ballots.ballots,
            func((iteration, is_early, ballot): (Nat, Bool, RevealedBallot<CursorMap>), index: Nat) : (Nat, Bool, RevealedBallot<CursorArray>) {
              (
                iteration,
                is_early,
                { ballot with answer = Option.map(ballot.answer, func(ans: CursorMap) : CursorArray { Utils.trieToArray(ans); }); }
              );
            }
          );
          { question_ballots with ballots = ballots; };
        }
      );
    };

    public func getNumberOpinionVotes(principal: Principal) : Nat {
      _controller.getNumberOpinionVotes(principal);
    };

    public func getQuestionIteration(vote_kind: VoteKind, vote_id: VoteId) : Result<(QuestionId, Nat, ?Question), FindQuestionIterationError> {
      _controller.getQuestionIteration(vote_kind, vote_id);
    };

    public func queryQuestionsFromAuthor(principal: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<(QuestionId, ?Question, ?TransactionsRecord)> {
      _controller.queryQuestionsFromAuthor(principal, direction, limit, previous_id);
    };

    public func queryFreshVotes(principal: Principal, vote_kind: VoteKind, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<QuestionId> {
      _controller.queryFreshVotes(principal, vote_kind, direction, limit, previous_id);
    };

    public func getVoterConvictions(now: Time, principal: Principal) : [(VoteId, (OpinionBallot, [(Category, Float)], Float, Bool))] {
      Utils.mapToArray(_controller.getVoterConvictions(now, principal));
    };

    public func run(time: Time) : async* () {
      await* _controller.run(time);
    };

  };

  func toShareableVote<T, A>(vote: Vote<T, A>) : ShareableVote<T, A> {
    {
      id = vote.id;
      ballots = Utils.mapToArray(vote.ballots);
      aggregate = vote.aggregate;
    }
  };

  func toShareableCategorizationVote(vote: Vote<CursorMap, PolarizationMap>) : CategorizationVote {
    
    let ballots = Buffer.Buffer<(Principal, Ballot<CursorArray>)>(Map.size(vote.ballots));
    for ((principal, ballot) in Map.entries(vote.ballots)) {
      ballots.add((principal, { date = ballot.date; answer = Utils.trieToArray<Category, Cursor>(ballot.answer); }));
    };

    {
      id = vote.id;
      ballots = Buffer.toArray(ballots);
      aggregate = Utils.trieToArray(vote.aggregate);
    };
  };

};