import Types "../Types";
import QuestionQueries "../QuestionQueries";
import Categorizations "../votes/Categorizations";
import Model "../controller/Model";
import Questions "../Questions";
import Votes "../votes/Votes";
import Poll "../votes/Poll";
import Categories "../Categories";
import Duration "../../utils/Duration";
import Utils "../../utils/Utils";
import History "../History";
import SubaccountGenerator "../token/SubaccountGenerator";
import SubaccountMap "../token/SubaccountMap";
import Event "Event";
import Schema "Schema";

import Set "mo:map/Set";

import StateMachine "../../utils/StateMachine";

import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Iter "mo:base/Iter";


module {

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type History = History.History;
  type Model = Model.Model;
  type Event = Event.Event;
  type Schema = Schema.Schema;
  type SubaccountMap = SubaccountMap.SubaccountMap;
  type SubaccountGenerator = SubaccountGenerator.SubaccountGenerator;
  type Key = QuestionQueries.Key;
  let { toAppealScore; toStatusEntry } = QuestionQueries;

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Int;
  type Set<K> = Set.Set<K>;
  type Iter<T> = Iter.Iter<T>;

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
  type CategoryInfo = Types.CategoryInfo;
  type CategoryArray = Types.CategoryArray;
  type StatusHistory = Types.StatusHistory;
  type UserHistory = Types.UserHistory;
  type VoteId = Types.VoteId;
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

  public func build(model: Model) : Controller {
    Controller(Schema.SchemaBuilder(model).build(), model);
  };

  public class Controller(schema_: Schema, model_: Model) = {

    public func getDecay() : ?Decay {
      model_.getHistory().getDecay();
    };

    public func getCategories() : CategoryArray {
      Iter.toArray(model_.getCategories().entries());
    };

    public func addCategory(caller: Principal, category: Category, info: CategoryInfo) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func() {
        Result.mapOk<(), (), AddCategoryError>(Utils.toResult(not model_.getCategories().has(category), #CategoryAlreadyExists), func() {
          model_.getCategories().set(category, info);
          // Also add the category to users' profile // @todo: use an obs instead?
          model_.getHistory().addCategory(category);
        })
      });
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
        Result.mapOk<(), (), RemoveCategoryError>(Utils.toResult(model_.getCategories().has(category), #CategoryDoesntExist), func() {
          model_.getCategories().delete(category);
          // Also remove the category from users' profile // @todo: use an obs instead?
          model_.getHistory().removeCategory(category);
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
      model_.getQuestions().searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(model_.getQuestions().findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries.ScanLimitResult {
      model_.getQueries().select(order_by, direction, limit, previous_id);
    };

    // @todo: to be able to pass the question creation through the validation of the state machine,
    // we need to create a new question with the status #START and then update it with the status #CANDIDATE.
    // Same thing for the #END status (instead of #TRASH)
    public func openQuestion(caller: Principal, text: Text, date: Time) : async Result<Question, OpenQuestionError> {
      let precondition = Utils.toResult(not Principal.isAnonymous(caller), #PrincipalIsAnonymous);
      switch(precondition){
        case(#err(err)) { #err(err); }; 
        case(#ok(_)){
          let voting_price = 1321321;
          let subaccount = model_.getSubaccountGenerator().generateSubaccount();
          switch(await model_.getMaster().transferToSubGodwin(caller, voting_price, subaccount)){
            case(#err(err)) { #err(#PrincipalIsAnonymous); }; // @todo
            case(#ok){
              let question = model_.getQuestions().createQuestion(caller, date, text);
              model_.getInterestSubaccounts().linkSubaccount(question.id, 0, subaccount);
              onStatusUpdate(null, ?question);
              #ok(question);
            };
          };
        };
      };
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async Result<(), ReopenQuestionError> {
      let precondition = Result.chain<(), (), ReopenQuestionError>(Utils.toResult(not Principal.isAnonymous(caller), #PrincipalIsAnonymous), func(_) {
        Result.chain<Question, (), ReopenQuestionError>(Result.fromOption(model_.getQuestions().findQuestion(question_id), #QuestionNotFound), func(question) {
          Utils.toResult(question.status_info.status == #CLOSED, #InvalidStatus)
        })
      });

      switch(precondition){
        case(#err(err)) { #err(err); }; 
        case(#ok(_)){
          let question = model_.getQuestions().getQuestion(question_id);
          let voting_price = 1321321;
          let subaccount = model_.getSubaccountGenerator().generateSubaccount();
          switch(await model_.getMaster().transferToSubGodwin(caller, voting_price, subaccount)){
            case(#err(err)) { #err(#PrincipalIsAnonymous); }; // @todo
            case(#ok){
              submitEvent(question, #REOPEN_QUESTION, date);
              model_.getInterestSubaccounts().linkSubaccount(question.id, 1, subaccount); // @todo
              #ok();
            };
          };
        };
      };
    };

//    public func getInterestBallot(caller: Principal, question_id: Nat) : Result<?Ballot<Interest>, GetBallotError> {
//      interest_poll_.findBallot(caller, question_id);
//    };
//
//    public func putInterestBallot(principal: Principal, question_id: Nat, date: Time, interest: Interest) : Result<(), PutFreshBallotError> {
//      interest_poll_.putFreshBallot(principal, question_id, date, interest);
//    };
//
//    public func getOpinionBallot(caller: Principal, question_id: Nat) : Result<?Ballot<Cursor>, GetBallotError> {
//      opinion_poll_.findBallot(caller, question_id);
//    };
//
//    public func putOpinionBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
//      opinion_poll_.putBallot(principal, question_id, date, cursor);
//    };
//      
//    public func getCategorizationBallot(caller: Principal, question_id: Nat) : Result<?Ballot<CursorArray>, GetBallotError> {
//      Result.mapOk(categorization_poll_.findBallot(caller, question_id), func(opt_ballot: ?Ballot<CursorMap>) : ?Ballot<CursorArray> {
//        Option.map(opt_ballot, func(ballot: Ballot<CursorMap>) : Ballot<CursorArray> {
//          { date = ballot.date; answer = Utils.trieToArray(ballot.answer); };
//        });
//      });
//    };
//      
//    public func putCategorizationBallot(principal: Principal, question_id: Nat, date: Time, answer: CursorArray) : Result<(), PutFreshBallotError> {
//      categorization_poll_.putFreshBallot(principal, question_id, date, Utils.arrayToTrie(answer, Categories.key, Categories.equal));
//    };

    public func getStatusHistory(question_id: Nat) : ?[(Status, [Time])] {
      Option.map(model_.getHistory().getStatusHistory(question_id), func(status_history: StatusHistory) : [(Status, [Time])] {
        Utils.mapToArray(status_history);
      });
    };

    public func getInterestVote(question_id: Nat, iteration: Nat) : ?PublicVote<Interest, Appeal> {
      Option.map(model_.getHistory().getInterestVote(question_id, iteration), func(vote: Vote<Interest, Appeal>) : PublicVote<Interest, Appeal> {
        Votes.toPublicVote(vote);
      });
    };

    public func getOpinionVote(question_id: Nat, iteration: Nat) : ?PublicVote<Cursor, Polarization> {
      Option.map(model_.getHistory().getOpinionVote(question_id, iteration), func(vote: Vote<Cursor, Polarization>) : PublicVote<Cursor, Polarization> {
        Votes.toPublicVote(vote);
      });
    };

    public func getCategorizationVote(question_id: Nat, iteration: Nat) : ?PublicVote<CursorArray, PolarizationArray> {
      Option.map(model_.getHistory().getCategorizationVote(question_id, iteration), func(vote: Vote<CursorMap, PolarizationMap>) : PublicVote<CursorArray, PolarizationArray> {
        Categorizations.toPublicVote(vote);
      });
    };

    public func getUserConvictions(principal: Principal) : ?PolarizationArray {
      Option.map(model_.getHistory().getUserConvictions(principal), func(convictions: PolarizationMap) : PolarizationArray {
        Utils.trieToArray(convictions);
      });
    };

    public func getUserVotes(principal: Principal) : ?[VoteId] {
      Option.map(model_.getHistory().getUserVotes(principal), func(votes: Set<VoteId>) : [VoteId] {
        Iter.toArray(Set.keys(votes));
      });
    };

    func verifyCredentials(principal: Principal) : Result<(), VerifyCredentialsError> {
      Result.mapOk<(), (), VerifyCredentialsError>(Utils.toResult(principal == model_.getAdmin(), #InsufficientCredentials), (func(){}));
    };

    public func run(date: Time) {
      model_.setTime(date);
      for (question in model_.getQuestions().iter()){
        submitEvent(question, #TIME_UPDATE, date);
      };
    };

    func submitEvent(question: Question, event: Event, date: Time) {

      let state_machine = {
        schema = schema_;
        model = question;
        var current = question.status_info.status;
      };
      
      Option.iterate(StateMachine.submitEvent(state_machine, event), func(status: Status) {
        let question_updated = switch(status) {
          case(#TRASH) {
            // @todo: the votes need to be removed too
            // Remove the question if it is in the trash
            model_.getQuestions().removeQuestion(question.id); 
            null; 
          };
          case(_) {
            // Update the question status
            let iteration = model_.getHistory().getStatusIteration(question.id, status);
            let update = { question with status_info = { status; iteration; date; } };
            model_.getQuestions().replaceQuestion(update);
            ?update;
          };
        };
        // @todo: explain
        onStatusUpdate(?question, question_updated);
      });
    };

    func onStatusUpdate(old: ?Question, new: ?Question){
      // When the question status changes, update the associated key for the #STATUS order_by
      model_.getQueries().replace(
        Option.map(old, func(question: Question) : Key { toStatusEntry(question); }),
        Option.map(new, func(question: Question) : Key { toStatusEntry(question); })
      );

      // Put the previous status in history (transferring the vote to the history if needed)
      Option.iterate(old, func(question: Question) {       
        let status_data = switch(question.status_info.status){
          case(#CANDIDATE) { #CANDIDATE({ vote_interest =             model_.getInterestVotes().removeVote(question.id); }); };
          case(#OPEN)      { #OPEN     ({ vote_opinion =               model_.getOpinionVotes().removeVote(question.id); 
                                          vote_categorization = model_.getCategorizationVotes().removeVote(question.id); }); };
          case(#CLOSED)    { #CLOSED   (); };
          case(#REJECTED)  { #REJECTED (); };
          case(#TRASH)     { #TRASH    (); };
        };
        model_.getHistory().add(question.id, question.status_info, status_data);
      });

      // Open a new vote if needed
      Option.iterate(new, func(question: Question) {
        switch(question.status_info.status){
          case(#CANDIDATE) {       model_.getInterestVotes().newVote(question.id); };
          case(#OPEN)      {        model_.getOpinionVotes().newVote(question.id);            
                             model_.getCategorizationVotes().newVote(question.id); };
          case(_)          {};
        };
      });
    };

  };

};