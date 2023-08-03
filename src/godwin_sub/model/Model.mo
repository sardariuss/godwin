import Types               "Types";
import StatusManager       "StatusManager";
import SubMomentum         "SubMomentum";
import Categories          "Categories";
import PayRules            "PayRules";
import Categorizations     "votes/Categorizations";
import Interests           "votes/Interests";
import Opinions            "votes/Opinions";
import Votes               "votes/Votes";
import Joins               "votes/QuestionVoteJoins";
import VotersHistory       "votes/VotersHistory";
import VoteTypes           "votes/Types";
import SubaccountGenerator "token/SubaccountGenerator";
import QuestionTypes       "questions/Types";
import Questions           "questions/Questions";

import WRef                "../utils/wrappers/WRef";

import Debug               "mo:base/Debug";
import Principal           "mo:base/Principal";

module {

  type WRef<T>              = WRef.WRef<T>;

  type Status               = Types.Status;
  type SchedulerParameters  = Types.SchedulerParameters;
  type SelectionParameters  = Types.SelectionParameters;
  type BasePriceParameters  = Types.BasePriceParameters;
  type Categories           = Categories.Categories;
  type PayRules             = PayRules.PayRules;
  type Questions            = Questions.Questions;
  type QuestionQueries      = QuestionTypes.QuestionQueries;
  type StatusManager        = StatusManager.StatusManager;
  type SubMomentum          = SubMomentum.SubMomentum;
  type InterestVotes        = Interests.Interests;
  type OpinionVotes         = Opinions.Opinions;
  type CategorizationVotes  = Categorizations.Categorizations;
  type Joins                = Joins.QuestionVoteJoins;
  type VotersHistory        = VotersHistory.VotersHistory;

  public class Model(
    _name: WRef<Text>,
    _master: WRef<Principal>,
    _scheduler_params: WRef<SchedulerParameters>,
    _selection_parameters: WRef<SelectionParameters>,
    _base_price_parameters: WRef<BasePriceParameters>,
    _categories: Categories,
    _pay_rules: PayRules,
    _questions: Questions,
    _status_manager: StatusManager,
    _sub_momentum: SubMomentum,
    _queries: QuestionQueries,
    _interest_votes: InterestVotes,
    _opinion_votes: OpinionVotes,
    _categorization_votes: CategorizationVotes,
    _interest_joins: Joins,
    _opinion_joins: Joins,
    _categorization_joins: Joins,
    _interest_voters_history: VotersHistory,
    _opinion_voters_history: VotersHistory,
    _categorization_voters_history: VotersHistory
  ) = {

    public func getName() : Text {
      _name.get();
    };

    public func setName(name: Text) {
      _name.set(name);
    };

    public func getMaster() : Principal {
      _master.get();
    };

    public func setMaster(master: Principal) {
      _master.set(master);
    };

    public func getSchedulerParameters() : SchedulerParameters {
      _scheduler_params.get();
    };

    public func setSchedulerParameters(params: SchedulerParameters) {
      _scheduler_params.set(params);
    };

    public func getSelectionParameters() : SelectionParameters {
      _selection_parameters.get();
    };

    public func setSelectionParameters(params: SelectionParameters) {
      _selection_parameters.set(params);
    };

    public func getBasePriceParameters() : BasePriceParameters {
      _base_price_parameters.get();
    };

    public func setBasePriceParameters(params: BasePriceParameters) {
      _base_price_parameters.set(params);
    };

    public func getCategories() : Categories {
      _categories;
    };

    public func getPayRules() : PayRules {
      _pay_rules;
    };

    public func getQuestions() : Questions {
      _questions;
    };

    public func getStatusManager() : StatusManager {
      _status_manager;
    };

    public func getSubMomentum() : SubMomentum {
      _sub_momentum;
    };

    public func getQueries() : QuestionQueries {
      _queries;
    };

    public func getInterestVotes() : InterestVotes {
      _interest_votes;
    };

    public func getOpinionVotes() : OpinionVotes {
      _opinion_votes;
    };

    public func getCategorizationVotes() : CategorizationVotes {
      _categorization_votes;
    };

    public func getInterestJoins() : Joins {
      _interest_joins;
    };

    public func getOpinionJoins() : Joins {
      _opinion_joins;
    };

    public func getCategorizationJoins() : Joins {
      _categorization_joins;
    };

    public func getInterestVotersHistory() : VotersHistory {
      _interest_voters_history;
    };

    public func getOpinionVotersHistory() : VotersHistory {
      _opinion_voters_history;
    };

    public func getCategorizationVotersHistory() : VotersHistory {
      _categorization_voters_history;
    };

  };

};