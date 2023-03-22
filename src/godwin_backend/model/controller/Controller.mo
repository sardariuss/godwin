import Types "../Types";
import QuestionQueries "../QuestionQueries";
import Categorizations "../votes/Categorizations";
import Model "../controller/Model";
import Questions "../Questions";
import Votes "../votes/Votes";
import Categories "../Categories";
import Duration "../../utils/Duration";
import Utils "../../utils/Utils";
import History "../History";
import SubaccountGenerator "../token/SubaccountGenerator";
import SubaccountMap "../token/SubaccountMap";
import Event "Event";
import Schema "Schema";

import Set "mo:map/Set";
import Map "mo:map/Map";

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
  type Map<K, V> = Map.Map<K, V>;

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
  type CursorArray = Types.CursorArray;
  type CategoryInfo = Types.CategoryInfo;
  type CategoryArray = Types.CategoryArray;
  type StatusHistory = Types.StatusHistory;
  type UserHistory = Types.UserHistory;
  type VoteId = Types.VoteId;
  type StatusInfo2 = Types.StatusInfo2;
  type StatusHistory2 = Types.StatusHistory2;
  // Errors
  type AddCategoryError = Types.AddCategoryError;
  type RemoveCategoryError = Types.RemoveCategoryError;
  type GetQuestionError = Types.GetQuestionError;
  type OpenQuestionError = Types.OpenQuestionError;
  type ReopenQuestionError = Types.ReopenQuestionError;
  type SetUserNameError = Types.SetUserNameError;
  type VerifyCredentialsError = Types.VerifyCredentialsError;
  type PrincipalError = Types.PrincipalError;
  type SetPickRateError = Types.SetPickRateError;
  type SetDurationError = Types.SetDurationError;
  type GetUserConvictionsError = Types.GetUserConvictionsError;
  type GetAggregateError = Types.GetAggregateError;
  type GetBallotError = Types.GetBallotError;
  type PutBallotError = Types.PutBallotError;
  type GetUserVotesError = Types.GetUserVotesError;
  type GetVoteError = Types.GetVoteError;

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
      // Verify that the caller is not anonymous
      if (Principal.isAnonymous(caller)){
        return #err(#PrincipalIsAnonymous);
      };
      
      switch(await model_.getInterestVotes().openVote(caller, func() : Question {
        let question = model_.getQuestions().createQuestion(caller, date, text);
        model_.getStatusManager().setCurrent(question.id, #CANDIDATE, date); // @todo
        question;
      })){
        case(#err(_)) { return #err(#PrincipalIsAnonymous); }; // @todo
        case(#ok(question)) { return #ok(question); };
      };
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async Result<(), ReopenQuestionError> {
      // Verify that the caller is not anonymous
      if (Principal.isAnonymous(caller)){
        return #err(#PrincipalIsAnonymous);
      };
      // Verify that the question exists
      let question = switch(model_.getQuestions().findQuestion(question_id)){
        case(null) { return #err(#QuestionNotFound); };
        case(?question) { question; };
      };
      // Verify that the question is closed
      if (question.status_info.status != #CLOSED){
        return #err(#InvalidStatus);
      };
      // Reopen the question 
      // @todo: risk of reentry, user will loose tokens if the question has already been reopened
      switch(await model_.getInterestVotes().openVote(caller, func() : Question {
        model_.getStatusManager().setCurrent(question.id, #CANDIDATE, date);
        question;
      })){
        case(#err(_)) { return #err(#PrincipalIsAnonymous); }; // @todo
        case(#ok(question)) { return #ok; };
      };
    };

    public func getInterestBallot(caller: Principal, question_id: Nat) : Result<Ballot<Interest>, GetBallotError> {
      model_.getInterestVotes().getBallot(caller, question_id);
    };

    public func putInterestBallot(principal: Principal, question_id: Nat, date: Time, interest: Interest) : async Result<(), PutBallotError> {
      await model_.getInterestVotes().putBallot(principal, question_id, date, interest);
    };

    public func getOpinionBallot(caller: Principal, question_id: Nat) : Result<Ballot<Cursor>, GetBallotError> {
      model_.getOpinionVotes().getBallot(caller, question_id);
    };

    public func putOpinionBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      model_.getOpinionVotes().putBallot(principal, question_id, date, cursor);
    };
      
    public func getCategorizationBallot(caller: Principal, question_id: Nat) : Result<Ballot<CursorArray>, GetBallotError> {
      Result.mapOk(model_.getCategorizationVotes().getBallot(caller, question_id), func(ballot: Ballot<CursorMap>) : Ballot<CursorArray> {
        { date = ballot.date; answer = Utils.trieToArray(ballot.answer); };
      });
    };
      
    public func putCategorizationBallot(principal: Principal, question_id: Nat, date: Time, cursors: CursorArray) : async Result<(), PutBallotError> {
      await model_.getCategorizationVotes().putBallot(principal, question_id, date, Utils.arrayToTrie(cursors, Categories.key, Categories.equal));
    };

    public func getStatusHistory(question_id: Nat) : ?[(Status, [Time])] {
      Option.map(model_.getStatusManager().getHistory(question_id), func(history: Map<Status, [Time]>) : [(Status, [Time])] {
        Utils.mapToArray(history);
      });
    };

    public func getInterestVote(question_id: Nat, iteration: Nat) : Result<PublicVote<Interest, Appeal>, GetVoteError> {
      // Get the vote
      switch(model_.getInterestVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Votes.toPublicVote(vote)); };
      };
    };

    public func getOpinionVote(question_id: Nat, iteration: Nat) : Result<PublicVote<Cursor, Polarization>, GetVoteError> {
      // Get the vote
      switch(model_.getOpinionVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Votes.toPublicVote(vote)); };
      };
    };

    public func getCategorizationVote(question_id: Nat, iteration: Nat) : Result<PublicVote<CursorArray, PolarizationArray>, GetVoteError> {
      // Get the vote
      switch(model_.getCategorizationVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Categorizations.toPublicVote(vote)); };
      };
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
        // Close vote if any
        // @todo: do not ignore the result
        switch(question.status_info.status){
          case(#CANDIDATE) { ignore model_.getInterestVotes().closeVote(question.id) };
          case(#OPEN)   { ignore model_.getOpinionVotes().closeVote(question.id);
                          ignore model_.getCategorizationVotes().closeVote(question.id); };
          case(_) {};
        };

        switch(status){
          case(#CANDIDATE) { /*ignore await model_.getInterestVotes().openVote();*/ }; // @todo
          case(#OPEN)   { model_.getOpinionVotes().openVote(question.id);
                          model_.getCategorizationVotes().openVote(question.id); };
          case(_) {};
        };

        // Set as current status
        // @todo: temp hack to not overwrite the status if candidate
        if (status != #CANDIDATE){
          model_.getStatusManager().setCurrent(question.id, status, date);
        };
        
        // Remove question if needed
        if (status == #TRASH){
          model_.getQuestions().removeQuestion(question.id);
        };

        // When the question status changes, update the associated key for the #STATUS order_by
        // @todo
//        model_.getQueries().replace(
//          Option.map(old, func(question: Question) : Key { toStatusEntry(question); }),
//          Option.map(new, func(question: Question) : Key { toStatusEntry(question); })
//        );
      });
    };
  
  };

};