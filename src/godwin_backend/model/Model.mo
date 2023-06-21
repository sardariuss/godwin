import Types               "Types";
import Categorizations     "votes/Categorizations";
import Interests           "votes/Interests";
import Opinions            "votes/Opinions";
import Votes               "votes/Votes";
import Joins               "votes/QuestionVoteJoins";
import VoteTypes           "votes/Types";
import Categories          "Categories";
import SubaccountGenerator "token/SubaccountGenerator";
import QuestionTypes       "questions/Types";
import Questions           "questions/Questions";
import StatusManager       "questions/StatusManager";

import WRef                "../utils/wrappers/WRef";

import Debug               "mo:base/Debug";
import Principal           "mo:base/Principal";

module {

  type WRef<T>              = WRef.WRef<T>;

  type Status               = Types.Status;
  type SchedulerParameters  = Types.SchedulerParameters;
  type DecayParameters      = Types.DecayParameters;
  type InterestMomentumArgs = VoteTypes.InterestMomentumArgs;
  type Categories           = Categories.Categories;
  type Questions            = Questions.Questions;
  type QuestionQueries      = QuestionTypes.QuestionQueries;
  type StatusManager        = StatusManager.StatusManager;
  type InterestVotes        = Interests.Interests;
  type OpinionVotes         = Opinions.Opinions;
  type CategorizationVotes  = Categorizations.Categorizations;
  type Joins                = Joins.QuestionVoteJoins;

  public class Model(
    _name: WRef<Text>,
    _master: WRef<Principal>,
    _momentum_args: WRef<InterestMomentumArgs>,
    _scheduler_params: WRef<SchedulerParameters>,
    _decay_params: WRef<DecayParameters>,
    _categories: Categories,
    _questions: Questions,
    _status_manager: StatusManager,
    _queries: QuestionQueries,
    _interest_votes: InterestVotes,
    _opinion_votes: OpinionVotes,
    _categorization_votes: CategorizationVotes,
    _interest_joins: Joins,
    _opinion_joins: Joins,
    _categorization_joins: Joins
  ) = {

    public func getName() : Text {
      _name.get();
    };

    public func setName(name: Text) {
      _name.set(name);
    };

    public func getMaster(): Principal {
      _master.get();
    };

    public func setMaster(master: Principal) {
      _master.set(master);
    };

    public func getMomentumArgs() : InterestMomentumArgs {
      _momentum_args.get();
    };

    public func setMomentumArgs(momentum_args: InterestMomentumArgs) {
      _momentum_args.set(momentum_args);
    };

    public func getSchedulerParameters() : SchedulerParameters {
      _scheduler_params.get();
    };

    public func setSchedulerParameters(params: SchedulerParameters) {
      _scheduler_params.set(params);
    };

    public func getDecayParameters(): DecayParameters {
      _decay_params.get();
    };

    public func getCategories(): Categories {
      _categories;
    };

    public func getQuestions(): Questions {
      _questions;
    };

    public func getStatusManager(): StatusManager {
      _status_manager;
    };

    public func getQueries(): QuestionQueries {
      _queries;
    };

    public func getInterestVotes(): InterestVotes {
      _interest_votes;
    };

    public func getOpinionVotes(): OpinionVotes {
      _opinion_votes;
    };

    public func getCategorizationVotes(): CategorizationVotes {
      _categorization_votes;
    };

    public func getInterestJoins(): Joins {
      _interest_joins;
    };

    public func getOpinionJoins(): Joins {
      _opinion_joins;
    };

    public func getCategorizationJoins(): Joins {
      _categorization_joins;
    };

  };

};