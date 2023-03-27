import Types "../Types";
import QuestionQueries "../QuestionQueries";
import Categorizations "../votes/Categorizations";
import Model "../controller/Model";
import Questions "../Questions";
import Votes "../votes/Votes";
import Categories "../Categories";
import Duration "../../utils/Duration";
import Utils "../../utils/Utils";
import SubaccountGenerator "../token/SubaccountGenerator";
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
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

module {

  // For convenience: from other modules
  type Questions = Questions.Questions;
  type Model = Model.Model;
  type Event = Event.Event;
  type Schema = Schema.Schema;
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
  type User = Types.User;
  type StatusInfo = Types.StatusInfo;
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

  public class Controller(_schema: Schema, _model: Model) = {

    public func getDecay() : ?Decay {
      _model.getUsers().getDecay();
    };

    public func getCategories() : CategoryArray {
      Iter.toArray(_model.getCategories().entries());
    };

    public func addCategory(caller: Principal, category: Category, info: CategoryInfo) : Result<(), AddCategoryError> {
      Result.chain<(), (), AddCategoryError>(verifyCredentials(caller), func() {
        Result.mapOk<(), (), AddCategoryError>(Utils.toResult(not _model.getCategories().has(category), #CategoryAlreadyExists), func() {
          _model.getCategories().set(category, info);
          _model.getUsers().addCategory(category);
        })
      });
    };

    public func removeCategory(caller: Principal, category: Category) : Result<(), RemoveCategoryError> {
      Result.chain<(), (), RemoveCategoryError>(verifyCredentials(caller), func () {
        Result.mapOk<(), (), RemoveCategoryError>(Utils.toResult(_model.getCategories().has(category), #CategoryDoesntExist), func() {
          _model.getCategories().delete(category);
          _model.getUsers().removeCategory(category);
        })
      });
    };

    public func getInterestPickRate() : Duration {
      _model.getInterestPickRate();
    };

    public func setInterestPickRate(caller: Principal, rate: Duration) : Result<(), SetPickRateError> {
      Result.mapOk<(), (), SetPickRateError>(verifyCredentials(caller), func () {
        _model.setInterestPickRate(rate);
      });
    };

    public func getStatusDuration(status: Status) : Duration {
      _model.getStatusDuration(status);
    };

    public func setStatusDuration(caller: Principal, status: Status, duration: Duration) : Result<(), SetDurationError> {
      Result.mapOk<(), (), SetDurationError>(verifyCredentials(caller), func () {
        _model.setStatusDuration(status, duration);
      });
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      _model.getQuestions().searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(_model.getQuestions().findQuestion(question_id), #QuestionNotFound);
    };

    public func getQuestions(order_by: QuestionQueries.OrderBy, direction: QuestionQueries.Direction, limit: Nat, previous_id: ?Nat) : QuestionQueries.ScanLimitResult {
      _model.getQueries().select(order_by, direction, limit, previous_id);
    };

    public func openQuestion(caller: Principal, text: Text, date: Time) : async* Result<Question, OpenQuestionError> {
      // Verify that the caller is not anonymous
      if (Principal.isAnonymous(caller)){
        return #err(#PrincipalIsAnonymous);
      };
      
      switch(await* _model.getInterestVotes().openVote(caller, func() : Question {
        let question = _model.getQuestions().createQuestion(caller, date, text);
        _model.getQueries().add(toStatusEntry(question.id, #CANDIDATE, date));
        _model.getStatusManager().setCurrent(question.id, #CANDIDATE, date);
        question;
      })){
        case(#err(_)) { return #err(#PrincipalIsAnonymous); }; // @todo
        case(#ok(question)) { return #ok(question); };
      };
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async* Result<(), ReopenQuestionError> {
      // Verify that the caller is not anonymous
      if (Principal.isAnonymous(caller)){
        return #err(#PrincipalIsAnonymous);
      };
      // Verify that the question exists
      let question = switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { return #err(#QuestionNotFound); };
        case(?question) { question; };
      };
      // Verify that the question is closed
      if (_model.getStatusManager().getCurrent(question_id).status != #CLOSED){
        return #err(#InvalidStatus);
      };
      // Reopen the question 
      // @todo: risk of reentry, user will loose tokens if the question has already been reopened
      switch(await* _model.getInterestVotes().openVote(caller, func() : Question {
        question;
      })){
        case(#err(_)) { #err(#PrincipalIsAnonymous); }; // @todo
        case(#ok(question)) {
          submitEvent(question, #REOPEN_QUESTION, date);
          return #ok; 
        };
      };
    };

    public func getInterestBallot(caller: Principal, question_id: Nat) : Result<Ballot<Interest>, GetBallotError> {
      _model.getInterestVotes().getBallot(caller, question_id);
    };

    public func putInterestBallot(principal: Principal, question_id: Nat, date: Time, interest: Interest) : async* Result<(), PutBallotError> {
      await* _model.getInterestVotes().putBallot(principal, question_id, date, interest);
    };

    public func getOpinionBallot(caller: Principal, question_id: Nat) : Result<Ballot<Cursor>, GetBallotError> {
      _model.getOpinionVotes().getBallot(caller, question_id);
    };

    public func putOpinionBallot(principal: Principal, question_id: Nat, date: Time, cursor: Cursor) : Result<(), PutBallotError> {
      _model.getOpinionVotes().putBallot(principal, question_id, date, cursor);
    };
      
    public func getCategorizationBallot(caller: Principal, question_id: Nat) : Result<Ballot<CursorArray>, GetBallotError> {
      Result.mapOk(_model.getCategorizationVotes().getBallot(caller, question_id), func(ballot: Ballot<CursorMap>) : Ballot<CursorArray> {
        { date = ballot.date; answer = Utils.trieToArray(ballot.answer); };
      });
    };
      
    public func putCategorizationBallot(principal: Principal, question_id: Nat, date: Time, cursors: CursorArray) : async* Result<(), PutBallotError> {
      await* _model.getCategorizationVotes().putBallot(principal, question_id, date, Utils.arrayToTrie(cursors, Categories.key, Categories.equal));
    };

    public func getStatusInfo(question_id: Nat) : Result<StatusInfo, ReopenQuestionError> {
      switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { #err(#PrincipalIsAnonymous); };
        case(?question) { #ok(_model.getStatusManager().getCurrent(question_id)); };
      };
    };

    public func getStatusHistory(question_id: Nat) : Result<[(Status, [Time])], ReopenQuestionError> {
      switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { #err(#PrincipalIsAnonymous); };
        case(?question) { #ok(Utils.mapToArray(_model.getStatusManager().getHistory(question_id))); };
      };
    };

    public func getInterestVote(question_id: Nat, iteration: Nat) : Result<PublicVote<Interest, Appeal>, GetVoteError> {
      switch(_model.getInterestVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Votes.toPublicVote(vote)); };
      };
    };

    public func getOpinionVote(question_id: Nat, iteration: Nat) : Result<PublicVote<Cursor, Polarization>, GetVoteError> {
      switch(_model.getOpinionVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Votes.toPublicVote(vote)); };
      };
    };

    public func getCategorizationVote(question_id: Nat, iteration: Nat) : Result<PublicVote<CursorArray, PolarizationArray>, GetVoteError> {
      switch(_model.getCategorizationVotes().revealVote(question_id, iteration)){
        case(#err(err)) { #err(err); };
        case(#ok(vote)) { #ok(Categorizations.toPublicVote(vote)); };
      };
    };

    public func getUserConvictions(principal: Principal) : ?PolarizationArray {
      Option.map(_model.getUsers().getUserConvictions(principal), func(convictions: PolarizationMap) : PolarizationArray {
        Utils.trieToArray(convictions);
      });
    };

    public func getUserOpinions(principal: Principal) : ?[Nat] {
      Option.map(_model.getUsers().getUserOpinions(principal), func(votes: Set<Nat>) : [Nat] {
        Iter.toArray(Set.keys(votes));
      });
    };

    func verifyCredentials(principal: Principal) : Result<(), VerifyCredentialsError> {
      Result.mapOk<(), (), VerifyCredentialsError>(Utils.toResult(principal == _model.getAdmin(), #InsufficientCredentials), (func(){}));
    };

    public func run(date: Time) {
      _model.setTime(date);
      for (question in _model.getQuestions().iter()){
        submitEvent(question, #TIME_UPDATE, date);
      };
    };

    func submitEvent(question: Question, event: Event, date: Time) {

      let state_machine = {
        schema = _schema;
        model = question;
      };

      let current = _model.getStatusManager().getCurrent(question.id);
      
      Result.iterate(StateMachine.submitEvent(state_machine, current.status, event), func(new: ?Status) {
        // When the question status changes, update the associated key for the #STATUS order_by
        _model.getQueries().replace(
          ?toStatusEntry(question.id, current.status, current.date),
          Option.map(new, func(status: Status) : Key { toStatusEntry(question.id, status, date); })
        );
        // Close vote(s) if any
        switch(current.status){
          case(#CANDIDATE) { 
            switch(_model.getInterestVotes().closeVote(question.id)) {
              case(#err(err)) { Debug.trap("Error!"); };
              case(#ok(_)) { };
            };
          };
          case(#OPEN)      { // Update the user convictions on question closed
                             // @todo: watchout, has to be called before the votes are closed
                             _model.getUsers().onClosingQuestion(question.id);
                             ignore _model.getOpinionVotes().closeVote(question.id);
                             ignore _model.getCategorizationVotes().closeVote(question.id); };
          case(_) {};
        };
        switch(new){
          case(null) {
            // Remove status and question
            _model.getStatusManager().deleteStatus(question.id);
            _model.getQuestions().removeQuestion(question.id);
          };
          case(?status){
            // Open a vote if applicable
            switch(status){
              case(#CANDIDATE) { // @todo: the opening of the vote shall be done by the state machine transition
                                 /*ignore await* _model.getInterestVotes().openVote();*/ }; 
              case(#OPEN)      { _model.getOpinionVotes().openVote(question.id);
                                 _model.getCategorizationVotes().openVote(question.id); };
              case(_) {};
            };
            // Finally set the status as current
            _model.getStatusManager().setCurrent(question.id, status, date);
          };
        };
      });
    };
  
  };

};