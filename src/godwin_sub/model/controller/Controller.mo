import Event               "Event";
import Schema              "Schema";
import VoteFacade          "../VoteFacade";
import Types               "../Types";
import Model               "../Model";
import StatusManager       "../StatusManager";
import QuestionTypes       "../questions/Types";
import Questions           "../questions/Questions";
import KeyConverter        "../questions/KeyConverter";
import VoteTypes           "../votes/Types";
import Decay               "../votes/Decay";
import PolarizationMap     "../votes/representation/PolarizationMap";

import Utils               "../../utils/Utils";
import StateMachine        "../../utils/StateMachine";

import Map                 "mo:map/Map";
import StableBuffer        "mo:stablebuffer/StableBuffer";

import Result              "mo:base/Result";
import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Iter                "mo:base/Iter";
import Buffer              "mo:base/Buffer";
import Array               "mo:base/Array";
import Debug               "mo:base/Debug";
import Int                 "mo:base/Int";

module {

  type Map<K, V>                   = Map.Map<K, V>;
  type Buffer<T>                   = Buffer.Buffer<T>;

  // For convenience: from other modules
  type Questions                   = Questions.Questions;
  type Model                       = Model.Model;
  type Event                       = Event.Event;
  type Schema                      = Schema.Schema;

  // For convenience: from base module
  type Result<Ok, Err>             = Result.Result<Ok, Err>;
  type Principal                   = Principal.Principal;
  type Time                        = Int;

  // For convenience: from types module
  type TransactionsRecord          = Types.TransactionsRecord;
  type Direction                   = Types.Direction;
  type ScanLimitResult<K>          = Types.ScanLimitResult<K>;
  type VoteKind                    = Types.VoteKind;
  type SchedulerParameters         = Types.SchedulerParameters;
  type BallotConvictionInput       = Types.BallotConvictionInput;
  type VoteAggregate               = Types.VoteAggregate;
  type QueryQuestionItem           = Types.QueryQuestionItem;
  type QueryVoteItem               = Types.QueryVoteItem;
  type StatusInfo                  = Types.StatusInfo;
  type StatusData                  = Types.StatusData;
  type BasePriceParameters         = Types.BasePriceParameters;
  type SelectionParameters         = Types.SelectionParameters;
  type SubInfo                     = Types.SubInfo;
  type KindRevealableBallot        = Types.KindRevealableBallot;
  type KindAnswer                  = Types.KindAnswer;
  type KindVote                    = Types.KindVote;
  type QuestionId                  = QuestionTypes.QuestionId;
  type Question                    = QuestionTypes.Question;
  type Status                      = QuestionTypes.Status;
  type Key                         = QuestionTypes.Key;
  type OrderBy                     = QuestionTypes.OrderBy;
  type VoteLink                    = VoteTypes.VoteLink;
  type OpinionBallot               = VoteTypes.OpinionBallot;
  type VoteId                      = VoteTypes.VoteId;
  type QueryOpenedVoteItem         = Types.QueryOpenedVoteItem;
  // Errors
  type GetQuestionError            = Types.GetQuestionError;
  type ReopenQuestionError         = Types.ReopenQuestionError;
  type AccessControlError          = Types.AccessControlError;
  type AccessControlRole           = Types.AccessControlRole;
  type SetSchedulerParametersError = Types.SetSchedulerParametersError;
  type FindBallotError             = Types.FindBallotError;
  type PutBallotError              = Types.PutBallotError;
  type RevealVoteError             = Types.RevealVoteError;
  type OpenQuestionError           = Types.OpenQuestionError;

  public func build(model: Model) : Controller {
    Controller(Schema.SchemaBuilder(model).build(), model);
  };

  public class Controller(_schema: Schema, _model: Model) = {

    let _vote_facade = VoteFacade.VoteFacade(_model.getInterestVotes(), _model.getOpinionVotes(), _model.getCategorizationVotes());

    public func getSubInfo() : SubInfo {
      {
        name = _model.getName();
        character_limit = _model.getQuestions().getCharacterLimit();
        categories = Iter.toArray(_model.getCategories().entries());
        selection_parameters = _model.getSelectionParameters();
        scheduler_parameters = _model.getSchedulerParameters();
        prices = _model.getSubPrices().getPrices();
        momentum = _model.getSubMomentum().get();
      };
    };

    public func setSchedulerParameters(caller: Principal, params: SchedulerParameters) : Result<(), SetSchedulerParametersError> {
      Result.mapOk<(), (), SetSchedulerParametersError>(verifyAuthorizedAccess(caller, #MASTER), func () {
        _model.setSchedulerParameters(params);
      });
    };

    public func setSelectionParameters(caller: Principal, params: SelectionParameters) : Result<(), AccessControlError> {
      Result.mapOk<(), (), AccessControlError>(verifyAuthorizedAccess(caller, #MASTER), func () {
        _model.setSelectionParameters(params);
        _model.getSubPrices().updatePrices(_model.getBasePriceParameters(), _model.getSelectionParameters());
      });
    };

    public func setBasePriceParameters(caller: Principal, params: BasePriceParameters) : Result<(), AccessControlError> {
      Result.mapOk<(), (), AccessControlError>(verifyAuthorizedAccess(caller, #MASTER), func () {
        _model.setBasePriceParameters(params);
        _model.getSubPrices().updatePrices(_model.getBasePriceParameters(), _model.getSelectionParameters());
      });
    };

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {
      _model.getQuestions().searchQuestions(text, limit);
    };

    public func getQuestion(question_id: Nat) : Result<Question, GetQuestionError> {
      Result.fromOption(_model.getQuestions().findQuestion(question_id), #QuestionNotFound);
    };

    public func openQuestion(caller: Principal, text: Text, date: Time) : async* Result<QuestionId, OpenQuestionError> {
      // Verify if the arguments are valid
      switch(_model.getQuestions().canCreateQuestion(caller, date, text)){
        case(?err) { return #err(err); };
        case(null) {};
      };
      // Callback called if opening the vote succeeds
      let create_question = func(vote_id: VoteId) : QuestionId {
        // Create the question
        let question = _model.getQuestions().createQuestion(caller, date, text);
        // Set the status
        ignore _model.getStatusManager().setCurrentStatus(question.id, #CANDIDATE, date, [{ vote_kind = #INTEREST; vote_id; }]);
        // Add to the status queries
        _model.getQueries().add(KeyConverter.toStatusKey(question.id, #CANDIDATE, date));
        // Return the question
        question.id;
      };
      // Open up the vote
      switch(await* _model.getInterestVotes().openVote(caller, date, null, create_question)){
        case(#err(err)) { return #err(err); };
        case(#ok((question_id, _))) { return #ok(question_id); };
      };
    };

    public func reopenQuestion(caller: Principal, question_id: Nat, date: Time) : async* Result<(), Text> {
      if(await* submitEvent(question_id, #REOPEN_QUESTION, date, caller)){ #ok; }
      else { #err("Fail to reopen question"); };
    };

    public func revealBallot(vote_kind: VoteKind, caller: Principal, voter: Principal, vote_id: VoteId) : Result<KindRevealableBallot, FindBallotError> {
      _vote_facade.revealBallot(vote_kind, caller, voter, vote_id);
    };

    public func putBallot(vote_kind: VoteKind, principal: Principal, id: VoteId, date: Time, answer: KindAnswer) : async* Result<(), PutBallotError> {
      await* _vote_facade.putBallot(vote_kind, principal, id, date, answer);
    };

    public func revealVote(vote_kind: VoteKind, id: VoteId) : Result<KindVote, RevealVoteError> {
      _vote_facade.revealVote(vote_kind, id);
    };

    public func getStatusHistory(question_id: Nat) : Result<[StatusData], ReopenQuestionError> {
      switch(_model.getQuestions().findQuestion(question_id)){
        case(null) { #err(#QuestionNotFound); };
        case(?question) { 
          let history = StableBuffer.toArray(_model.getStatusManager().getStatusHistory(question_id));
          #ok(Array.mapEntries<StatusInfo, StatusData>(
            history, 
            func(status_info: StatusInfo, index: Nat) : StatusData {
              let is_current = (index == Int.abs(history.size() - 1));
              {
                status_info;
                previous_status = if (index > 0) { ?{ vote_aggregates = revealStatusAggregates(history[index - 1]) }; } else { null; };
                is_current;
                ending_date = if (is_current) { _model.getStatusManager().endingDate(question_id, _model.getSchedulerParameters()); } else { null; };
              };
            }));
        };
      };
    };

    func revealStatusAggregates(status_info: StatusInfo) : [VoteAggregate] {
      let aggregates_buffer = Buffer.Buffer<VoteAggregate>(0);
      for({vote_id; vote_kind;} in Array.vals(status_info.votes)){
        switch(_vote_facade.revealAggregate(vote_kind, vote_id)){
          case(#err(err)) {};
          case(#ok(aggregate)) { aggregates_buffer.add({ vote_id; aggregate; }); };
        };
      };
      Buffer.toArray(aggregates_buffer); 
    };

    public func queryQuestions(order_by: OrderBy, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<QueryQuestionItem> {
      Utils.mapScanLimitResult<QuestionId, QueryQuestionItem>(
        _model.getQueries().select(order_by, direction, limit, previous_id, null),
        func(question_id: QuestionId) : QueryQuestionItem {
          switch(_model.getQuestions().findQuestion(question_id)){
            case(null) { Debug.trap("Question not found"); };
            case(?question) {
              let current = _model.getStatusManager().getCurrentStatus(question_id);
              // If retrieved ARCHIVE votes, show the last CLOSED status, else the current one
              let (index, status_info) = if(order_by == #ARCHIVE) {
                _model.getStatusManager().getLastStatusInfo(question_id, #CLOSED);
              } else {
                current;
              };
              // If there is a previous status, get its aggregates
              let previous_status = if (index > 0) {
                ?{ vote_aggregates = revealStatusAggregates(_model.getStatusManager().getStatus(question_id, index - 1)); };
              } else {
                null;
              };
              // Indicate if the status is the current
              let is_current = index == current.0;
              // Get the ending date if applicable
              let ending_date = if (is_current) {
                _model.getStatusManager().endingDate(question_id, _model.getSchedulerParameters());
              } else {
                null;
              };
              // Indicate if the question can be reopened
              let can_reopen = StateMachine.hasTransition(_schema, #REOPEN_QUESTION, current.1.status);
              // Get the time left
              { question; can_reopen; status_data = { status_info; previous_status; is_current; ending_date; } };
            };
          };
        });
    };

    public func queryOpenedVotes(principal: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : ScanLimitResult<QueryOpenedVoteItem> {
      let vote_ids = Utils.mapScanLimit<VoteId, Time>(_model.getInterestVotes().getOpenedVotes(principal), Map.nhash, direction, limit, previous_id);
      Utils.mapScanLimitResult<(VoteId, Time), QueryOpenedVoteItem>(vote_ids, func((vote_id, date): (VoteId, Time)) : QueryOpenedVoteItem {
        let (question_id, iteration) = _model.getInterestJoins().getQuestionIteration(vote_id);
        {
          vote_id;
          question_id;
          iteration;
          date;
          question = _model.getQuestions().findQuestion(question_id);
        };
      });
    };

    public func findOpenedVoteTransactions(principal: Principal, id: VoteId) : ?TransactionsRecord {
      _model.getInterestVotes().findOpenedVoteTransactions(principal, id);
    };

    public func queryFreshVotes(principal: Principal, vote_kind: VoteKind, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<QueryVoteItem> {
      
      let (order_by, votes, joins) = switch(vote_kind){
        case(#INTEREST)       {
          (#HOTNESS,        _model.getInterestVotes(),       _model.getInterestJoins()      );
        };
        case(#OPINION)        { 
          (#OPINION_VOTE,   _model.getOpinionVotes(),        _model.getOpinionJoins()       );
        };
        case(#CATEGORIZATION) { 
          (#STATUS(#OPEN),  _model.getCategorizationVotes(), _model.getCategorizationJoins());
        };
      };

      let filter = func(key: Key) : Bool {
        let question_id = KeyConverter.getQuestionId(key);
        for (vote_id in Map.vals(joins.getQuestionVotes(question_id))){
          if (votes.hasBallot(principal, vote_id)){
            return false;
          };
        };
        true;
      };

      Utils.mapScanLimitResult<QuestionId, QueryVoteItem>(
        _model.getQueries().select(order_by, direction, limit, previous_id, ?filter),
        func(question_id: QuestionId) : QueryVoteItem {
          let (iteration, id) = joins.getLastVote(question_id);
          let vote = votes.getVote(id);
          {
            question_id;
            question = _model.getQuestions().findQuestion(question_id); 
            // The ballot will always be null because we filter out the votes that the user has already voted on
            vote = (vote_kind, { id; status = vote.status; iteration; user_ballot = null; });
          };
        }
      );
    };

    public func queryVoterBallots(
      vote_kind: VoteKind,
      caller: Principal,
      voter: Principal,
      direction: Direction,
      limit: Nat,
      previous_id: ?QuestionId
    ) : ScanLimitResult<QueryVoteItem> {
      let scan_answered_questions = switch(vote_kind){
        case(#INTEREST){
          _model.getInterestVotersHistory().scanVoterHistory(voter, direction, limit, previous_id);
        };
        case(#OPINION){
          _model.getOpinionVotersHistory().scanVoterHistory(voter, direction, limit, previous_id);
        };
        case(#CATEGORIZATION){
          _model.getCategorizationVotersHistory().scanVoterHistory(voter, direction, limit, previous_id);
        };
      };
      Utils.mapScanLimitResult(scan_answered_questions, func((question_id, vote_map): (QuestionId, Map<Nat, VoteId>)) : QueryVoteItem {
        {
          question_id; 
          question = _model.getQuestions().findQuestion(question_id);
          vote = switch(vote_kind){
            case(#INTEREST){
              let (iteration, id) = _model.getInterestJoins().getLastVote(question_id);
              let status = _model.getInterestVotes().getVote(id).status;
              // Take the last ballot
              let user_ballot = Option.chain(Map.peek(vote_map), func((iteration, vote_id) : (Nat, VoteId)) : ?KindRevealableBallot{
                Result.toOption(revealBallot(vote_kind, caller, voter, vote_id));
              });
              (#INTEREST, { id; iteration; status; user_ballot; });
            };
            case(#OPINION){
              let (iteration, id) = _model.getOpinionJoins().getLastVote(question_id);
              let status = _model.getOpinionVotes().getVote(id).status;
              let user_ballot = Option.chain(Map.peek(vote_map), func((iteration, vote_id) : (Nat, VoteId)) : ?KindRevealableBallot{
                Result.toOption(revealBallot(vote_kind, caller, voter, vote_id));
              });
              (#OPINION, { id; iteration; status; user_ballot; });
            };
            case(#CATEGORIZATION){
              let (iteration, id) = _model.getCategorizationJoins().getLastVote(question_id);
              let status = _model.getCategorizationVotes().getVote(id).status;
              let user_ballot = Option.chain(Map.peek(vote_map), func((iteration, vote_id) : (Nat, VoteId)) : ?KindRevealableBallot{
                Result.toOption(revealBallot(vote_kind, caller, voter, vote_id));
              });
              (#CATEGORIZATION, { id; iteration; status; user_ballot; });
            };
          };
        };
      });
    };

    public func queryVoterQuestionBallots(
      question_id: QuestionId,
      vote_kind: VoteKind,
      caller: Principal,
      voter: Principal
    ) : [(Nat, ?KindRevealableBallot)] {
      let question_ballots = switch(vote_kind){
        case(#INTEREST){
          let question_ballots = _model.getInterestVotersHistory().getVoterQuestionBallots(voter, question_id);
          Map.toArray(Map.map<Nat, VoteId, ?KindRevealableBallot>(question_ballots, Map.nhash, func((iteration, vote_id) : (Nat, VoteId)) : ?KindRevealableBallot{
            Result.toOption(revealBallot(vote_kind, caller, voter, vote_id));
          }));
        };
        case(#OPINION){
          let question_ballots = _model.getOpinionVotersHistory().getVoterQuestionBallots(voter, question_id);
          Map.toArray(Map.map<Nat, VoteId, ?KindRevealableBallot>(question_ballots, Map.nhash, func((iteration, vote_id) : (Nat, VoteId)) : ?KindRevealableBallot{
            Result.toOption(revealBallot(vote_kind, caller, voter, vote_id));
          }));
        };
        case(#CATEGORIZATION){
          let question_ballots = _model.getCategorizationVotersHistory().getVoterQuestionBallots(voter, question_id);
          Map.toArray(Map.map<Nat, VoteId, ?KindRevealableBallot>(question_ballots, Map.nhash, func((iteration, vote_id) : (Nat, VoteId)) : ?KindRevealableBallot{
            Result.toOption(revealBallot(vote_kind, caller, voter, vote_id));
          }));
        };
      };
    };

    public func findBallotTransactions(vote_kind: VoteKind, principal: Principal, id: VoteId) : ?TransactionsRecord {
      _vote_facade.findBallotTransactions(vote_kind, principal, id);
    };

    public func getVoterConvictions(now: Time, principal: Principal) : [(VoteId, BallotConvictionInput)] {

      // Get the current decays
      let current_vote_decay = Decay.computeDecay(_model.getOpinionVotes().getVoteDecay(), now);
      let current_late_ballot_decay = Decay.computeDecay(_model.getOpinionVotes().getLateBallotDecay(), now);

      // Function to convert a ballot to a conviction input
      let to_ballot_conviction_input = func(vote_id: VoteId, ballot: OpinionBallot) : ?BallotConvictionInput {
        let { answer = { cursor; late_decay; }; date; } = ballot;
        // Get the opinion decay
        let opinion_vote = _model.getOpinionVotes().getVote(vote_id);
        let vote_decay = switch(opinion_vote.aggregate.decay){
          case(null) { return null; }; // Do not consider the vote if it is not locked or closed
          case(?decay) { decay / current_vote_decay; };
        };
        // Get the most up-to-date categorization vote for this question
        let (question_id, opinion_iteration) = _model.getOpinionJoins().getQuestionIteration(vote_id);
        let join = Map.findDesc(
          _model.getCategorizationJoins().getQuestionVotes(question_id),
          func(iteration: Nat, id: VoteId) : Bool {
            _model.getCategorizationVotes().getVote(id).status == #CLOSED;
          });
        let categorization = switch(join){
          case(null) { Debug.trap("Categorization vote is missing"); };
          case(?(_, id)){
            Utils.trieToArray(PolarizationMap.toCursorMap(_model.getCategorizationVotes().getVote(id).aggregate));
          };
        };
        // Compute the ballot decay if applicable
        let late_ballot_decay = Option.map(late_decay, func(late_decay: Float) : Float { (late_decay / current_late_ballot_decay); });
        // Return the whole input
        ?{ cursor; date; categorization; vote_decay; late_ballot_decay; };
      };

      Map.toArray(Map.mapFilter<VoteId, OpinionBallot, BallotConvictionInput>(
        _model.getOpinionVotes().getVoterBallots(principal), Map.nhash, to_ballot_conviction_input
      ));
    };

    public func run(date: Time, caller: Principal) : async* () {
      // Update the momentum
      _model.getSubMomentum().update(date);
      // Iterate over the questions and update their status via the state machine
      for (question in _model.getQuestions().iter()){
        ignore await* submitEvent(question.id, #TIME_UPDATE, date, caller);
      };
    };

    private func verifyAuthorizedAccess(principal: Principal, required_role: AccessControlRole) : Result<(), AccessControlError> {
      switch(required_role){
        case(#MASTER) { if(principal == _model.getMaster()) { return #ok; }; };
      };
      #err(#AccessDenied({required_role;}));
    };

    private func submitEvent(question_id: Nat, event: Event, date: Time, caller: Principal) : async* Bool {
      let (_, {status}) = _model.getStatusManager().getCurrentStatus(question_id);
      // Submit the event
      await* StateMachine.submitEvent(_schema, status, question_id, event, date, caller);
    };

  };

};