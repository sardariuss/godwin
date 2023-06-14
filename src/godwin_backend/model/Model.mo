import Types               "Types";
import Categorizations     "votes/Categorizations";
import Votes               "votes/Votes";
import Joins               "votes/QuestionVoteJoins";
import Categories          "Categories";
import SubaccountGenerator "token/SubaccountGenerator";
import QuestionTypes       "questions/Types";
import Questions           "questions/Questions";
import StatusManager       "questions/StatusManager";
import Interests           "votes/Interests";
import Opinions            "votes/Opinions";

import Ref                 "../utils/Ref";
import WRef                "../utils/wrappers/WRef";

import Debug               "mo:base/Debug";
import Principal           "mo:base/Principal";

module {

  type Time                = Int;
  type Status              = Types.Status;
  type Ref<T>              = Ref.Ref<T>;
  type WRef<T>             = WRef.WRef<T>;
  type SchedulerParameters = Types.SchedulerParameters;
  type Categories          = Categories.Categories;
  type Questions           = Questions.Questions;
  type QuestionQueries     = QuestionTypes.QuestionQueries;
  type StatusManager       = StatusManager.StatusManager;
  type InterestVotes       = Interests.Interests;
  type OpinionVotes        = Opinions.Opinions;
  type CategorizationVotes = Categorizations.Categorizations;
  type Joins               = Joins.QuestionVoteJoins;

  public func build(
    name: Ref<Text>,
    master: Ref<Principal>,
    last_pick_date: Ref<Time>,
    params: Ref<SchedulerParameters>,
    categories: Categories,
    questions: Questions,
    status_manager: StatusManager,
    queries: QuestionQueries,
    interest_votes: InterestVotes,
    opinion_votes: OpinionVotes,
    categorization_votes: CategorizationVotes,
    interest_joins: Joins,
    opinion_joins: Joins,
    categorization_joins: Joins,
  ) : Model {
    Model(
      WRef.WRef(name),
      WRef.WRef(master),
      WRef.WRef(last_pick_date),
      WRef.WRef(params),
      categories,
      questions,
      status_manager,
      queries,
      interest_votes,
      opinion_votes,
      categorization_votes,
      interest_joins,
      opinion_joins,
      categorization_joins,
    );
  };

  public class Model(
    _name: WRef<Text>,
    _master: WRef<Principal>,
    _last_pick_date: WRef<Time>,
    _params: WRef<SchedulerParameters>,
    _categories: Categories,
    _questions: Questions,
    _status_manager: StatusManager,
    _queries: QuestionQueries,
    _interest_votes: InterestVotes,
    _opinion_votes: OpinionVotes,
    _categorization_votes: CategorizationVotes,
    _interest_joins: Joins,
    _opinion_joins: Joins,
    _categorization_joins: Joins,
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

    public func getLastPickDate() : Time {
      _last_pick_date.get();
    };

    public func setLastPickDate(last_pick_date: Time) {
      _last_pick_date.set(last_pick_date);
    };

    public func getSchedulerParameters() : SchedulerParameters {
      _params.get();
    };

    public func setSchedulerParameters(params: SchedulerParameters) {
      _params.set(params);
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