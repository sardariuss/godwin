import Types "Types";
import QuestionQueries "QuestionQueries";
import Controller "controller/Controller";
import Categorizations "votes/Categorizations";
import Model "controller/Model";
import Questions "Questions";
import Votes "votes/Votes";
import Poll "votes/Poll";
import Categories "Categories";
import Duration "../utils/Duration";
import Utils "../utils/Utils";
import History "History";

import Set "mo:map/Set";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";

import TokenVote "TokenVote";
import Token "canister:godwin_token";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Int;
  type Set<K> = Set.Set<K>;

  // For convenience: from types module
  type Question = Types.Question;
  type Category = Types.Category;
  type Decay = Types.Decay;
  type Duration = Duration.Duration;
  type Status = Types.Status;
  type PolarizationArray = Types.PolarizationArray;
  type Ballot<T> = Types.Ballot<T>;
  type Vote<T, A> = Types.Vote<T, A>;
  type PublicVote<T, A> = Types.PublicVote<T, A>;
  type Interest = Types.Interest;
  type Appeal = Types.Appeal;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type InterestPoll = Poll.Poll<Interest, Appeal>;
  type OpinionPoll = Poll.Poll<Cursor, Polarization>;
  type CategorizationPoll = Poll.Poll<CursorMap, PolarizationMap>;
  type CursorArray = Types.CursorArray;
  // Errors
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type GetQuestionError = Types.GetQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type ReopenQuestionError = Types.ReopenQuestionError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type GetUserError = Types.GetUserError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type GetUserConvictionsError = Types.GetUserConvictionsError;
  type GetAggregateError = Types.GetAggregateError;
  type GetBallotError = Types.GetBallotError;
  type RevealBallotError = Types.RevealBallotError;
  type PutBallotError = Types.PutBallotError;
  type PutFreshBallotError = Types.PutFreshBallotError;
  type GetUserVotesError = Types.GetUserVotesError;
  type CategoryInfo = Types.CategoryInfo;
  type CategoryArray = Types.CategoryArray;
  type StatusHistory = Types.StatusHistory;
  type UserHistory = Types.UserHistory;
  type VoteId = Types.VoteId;

  public class Game(
    admin_: Principal,
    categories_: Categories.Categories,
    questions_: Questions.Questions,
    history_: History.History,
    queries_: QuestionQueries.QuestionQueries,
    model_: Model.Model,
    controller_: Controller.Controller,
    interest_poll_: InterestPoll,
    opinion_poll_: OpinionPoll,
    categorization_poll_: CategorizationPoll
  ) = {

    let interest_vote_accounts_ = TokenVote.TokenVote();
    let categorization_vote_accounts_ = TokenVote.TokenVote();

    let subaccount_generator_ = TokenVote.SubaccountGenerator();

    public func getDecay() : ?Decay {
      history_.getDecay();
    };

    public func getCategories() : CategoryArray {
      Iter.toArray(categories_.entries());
    };

    public func addCategory(caller: Principal, category: Category, info: CategoryInfo) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func() {
        Result.mapOk<(), (), AddCategoryError>(Utils.toResult(not categories_.has(category), #CategoryAlreadyExists), func() {
          categories_.set(category, info);
          // Also add the category to users' profile // @todo: use an obs instead?
          history_.addCategory(category);
        })
      });
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
        Result.mapOk<(), (), RemoveCategoryError>(Utils.toResult(categories_.has(category), #CategoryDoesntExist), func() {
          categories_.delete(category);
          // Also remove the category from users' profile // @todo: use an obs instead?
          history_.removeCategory(category);
        })
      });
    };

    public func getInterestPickRate() : Duration {
      model_.getInterestPickRate();
    };

    public func setInterestPickRate(caller: Principal, rate: Duration) : Result<(), SetPickRateError> {
      Result.mapOk<(), (), SetPickRateError>(verifyCredentials(caller), func () {
        model_.setInterestPickRate(rate);
      });
    };

    public func getStatusDuration(status: Status) : Duration {
      model_.getStatusDuration(status);
    };

    public func setStatusDuration(caller: Principal, status: Status, duration: Duration) : Result<(), SetDurationError> {
      Result.mapOk<(), (), SetDurationError>(verifyCredentials(caller), func () {
        model_.setStatusDuration(status, duration);
      });
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      questions_.searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries.ScanLimitResult {
      queries_.select(order_by, direction, limit, previous_id);
    };

    public func openQuestion(master: Types.Master, caller: Principal, text: Text, date: Time) : async Result<Question, OpenQuestionError> {
      let precondition = Utils.toResult(not Principal.isAnonymous(caller), #PrincipalIsAnonymous);
      switch(precondition){
        case(#err(err)) { #err(err); }; 
        case(#ok(_)){
          let voting_price = 1321321;
          let subaccount = subaccount_generator_.generateSubaccount();
          switch(await master.transferToSubGodwin(caller, voting_price, subaccount)){
            case(#err(err)) { #err(#PrincipalIsAnonymous); }; // @todo
            case(#ok){
              let question = controller_.openQuestion(caller, date, text); // @todo: make sure it cannot trap
              interest_vote_accounts_.linkSubaccount(question.id, 0, subaccount);
              #ok(question);
            };
          };
        };
      };
    };

    public func reopenQuestion(master: Types.Master, caller: Principal, question_id: Nat, date: Time) : async Result<(), ReopenQuestionError> {
      let precondition = Result.chain<(), (), ReopenQuestionError>(Utils.toResult(not Principal.isAnonymous(caller), #PrincipalIsAnonymous), func(_) {
        Result.chain<Question, (), ReopenQuestionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
          Utils.toResult(question.status_info.status == #CLOSED, #InvalidStatus)
        })
      });

      switch(precondition){
        case(#err(err)) { #err(err); }; 
        case(#ok(_)){
          let question = questions_.getQuestion(question_id);
          let voting_price = 1321321;
          let subaccount = subaccount_generator_.generateSubaccount();
          switch(await master.transferToSubGodwin(caller, voting_price, subaccount)){
            case(#err(err)) { #err(#PrincipalIsAnonymous); }; // @todo
            case(#ok){
              controller_.reopenQuestion(question, date);
              interest_vote_accounts_.linkSubaccount(question.id, 1, subaccount); // @todo
              #ok();
            };
          };
        };
      };
    };

    public func getInterestBallot(caller: Principal, question_id: Nat) : Result<?Ballot<Interest>, GetBallotError> {
      interest_poll_.findBallot(caller, question_id);
    };

    public func putInterestBallot(principal: Principal, question_id: Nat, date: Time, interest: Interest) : Result<(), PutFreshBallotError> {
      interest_poll_.putFreshBallot(principal, question_id, date, interest);
    };

    public func getOpinionBallot(caller: Principal, question_id: Nat) : Result<?Ballot<Cursor>, GetBallotError> {
      opinion_poll_.findBallot(caller, question_id);
    };

    public func putOpinionBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      opinion_poll_.putBallot(principal, question_id, date, cursor);
    };
      
    public func getCategorizationBallot(caller: Principal, question_id: Nat) : Result<?Ballot<CursorArray>, GetBallotError> {
      Result.mapOk(categorization_poll_.findBallot(caller, question_id), func(opt_ballot: ?Ballot<CursorMap>) : ?Ballot<CursorArray> {
        Option.map(opt_ballot, func(ballot: Ballot<CursorMap>) : Ballot<CursorArray> {
          { date = ballot.date; answer = Utils.trieToArray(ballot.answer); };
        });
      });
    };
      
    public func putCategorizationBallot(principal: Principal, question_id: Nat, date: Time, answer: CursorArray) : Result<(), PutFreshBallotError> {
      categorization_poll_.putFreshBallot(principal, question_id, date, Utils.arrayToTrie(answer, Categories.key, Categories.equal));
    };

    public func getStatusHistory(question_id: Nat) : ?[(Status, [Time])] {
      Option.map(history_.getStatusHistory(question_id), func(status_history: StatusHistory) : [(Status, [Time])] {
        Utils.mapToArray(status_history);
      });
    };

    public func getInterestVote(question_id: Nat, iteration: Nat) : ?PublicVote<Interest, Appeal> {
      Option.map(history_.getInterestVote(question_id, iteration), func(vote: Vote<Interest, Appeal>) : PublicVote<Interest, Appeal> {
        Votes.toPublicVote(vote);
      });
    };

    public func getOpinionVote(question_id: Nat, iteration: Nat) : ?PublicVote<Cursor, Polarization> {
      Option.map(history_.getOpinionVote(question_id, iteration), func(vote: Vote<Cursor, Polarization>) : PublicVote<Cursor, Polarization> {
        Votes.toPublicVote(vote);
      });
    };

    public func getCategorizationVote(question_id: Nat, iteration: Nat) : ?PublicVote<CursorArray, PolarizationArray> {
      Option.map(history_.getCategorizationVote(question_id, iteration), func(vote: Vote<CursorMap, PolarizationMap>) : PublicVote<CursorArray, PolarizationArray> {
        Categorizations.toPublicVote(vote);
      });
    };

    public func getUserConvictions(principal: Principal) : ?PolarizationArray {
      Option.map(history_.getUserConvictions(principal), func(convictions: PolarizationMap) : PolarizationArray {
        Utils.trieToArray(convictions);
      });
    };

    public func getUserVotes(principal: Principal) : ?[VoteId] {
      Option.map(history_.getUserVotes(principal), func(votes: Set<VoteId>) : [VoteId] {
        Iter.toArray(Set.keys(votes));
      });
    };

    public func run(date: Time) {
      controller_.run(date, queries_.iter(#INTEREST_SCORE, #FWD).next());
    };

    func verifyCredentials(principal: Principal) : Result<(), VerifyCredentialsError> {
      Result.mapOk<(), (), VerifyCredentialsError>(Utils.toResult(principal == admin_, #InsufficientCredentials), (func(){}));
    };

  };

};
