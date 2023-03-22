import Types "../Types";
import QuestionQueries "../QuestionQueries";
import Categorizations "../votes/Categorizations";
import Questions "../Questions";
import Votes "../votes/Votes";
import Categories "../Categories";
import History "../History";
import SubaccountGenerator "../token/SubaccountGenerator";
import SubaccountMap "../token/SubaccountMap";
import StatusManager "../StatusManager2";

import Interests2 "../votes/Interests2";
import Opinions2 "../votes/Opinions2";
import Categorizations2 "../votes/Categorizations2";

import Ref "../../utils/Ref";
import WRef "../../utils/wrappers/WRef";
import Duration "../../utils/Duration";

import Debug "mo:base/Debug";
import Principal "mo:base/Principal";

module {

  type Time = Int;
  type Status = Types.Status;
  type Duration = Duration.Duration;
  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;
  type SchedulerParameters = Types.SchedulerParameters;
  type Master = Types.Master;
  type Categories = Categories.Categories;
  type Questions = Questions.Questions;
  type History = History.History;
  type QuestionQueries = QuestionQueries.QuestionQueries;
  type InterestVotes = Votes.Votes<Types.Interest, Types.Appeal>;
  type OpinionVotes = Votes.Votes<Types.Cursor, Types.Polarization>;
  type CategorizationVotes = Votes.Votes<Types.CursorMap, Types.PolarizationMap>;
  type SubaccountMap = SubaccountMap.SubaccountMap;
  type SubaccountGenerator = SubaccountGenerator.SubaccountGenerator;
  type StatusManager = StatusManager.StatusManager;

  type InterestVotes2 = Interests2.Interests;
  type OpinionVotes2 = Opinions2.Opinions;
  type CategorizationVotes2 = Categorizations2.Categorizations;

  public func build(
    admin: Ref<Principal>,
    time: Ref<Time>,
    last_pick_date: Ref<Time>,
    params: Ref<SchedulerParameters>,
    categories: Categories,
    questions: Questions,
    status_manager: StatusManager,
    history: History,
    queries: QuestionQueries,
    interest_votes: InterestVotes2,
    opinion_votes: OpinionVotes2,
    categorization_votes: CategorizationVotes2
  ) : Model {
    Model(
      WRef.WRef(admin),
      WRef.WRef(time),
      WRef.WRef(last_pick_date),
      WRef.WRef(params),
      categories,
      questions,
      status_manager,
      history,
      queries,
      interest_votes,
      opinion_votes,
      categorization_votes
    );
  };

  public class Model(
    admin_: WRef<Principal>,
    time_: WRef<Time>,
    last_pick_date_: WRef<Time>,
    params_: WRef<SchedulerParameters>,
    categories_: Categories,
    questions_: Questions,
    status_manager_: StatusManager,
    history_: History,
    queries_: QuestionQueries,
    interest_votes_: InterestVotes2,
    opinion_votes_: OpinionVotes2,
    categorization_votes_: CategorizationVotes2
  ) = {

    public func getMaster() : Master {
      actor(Principal.toText(admin_.get())); // @todo: shall the admin and the master be different?
    };

    public func getAdmin(): Principal {
      admin_.get();
    };

    public func setAdmin(admin: Principal) {
      admin_.set(admin);
    };

    public func getTime() : Time {
      time_.get();
    };

    public func setTime(time: Time) {
      time_.set(time);
    };

    public func getLastPickDate() : Time {
      last_pick_date_.get();
    };

    public func setLastPickDate(last_pick_date: Time) {
      last_pick_date_.set(last_pick_date);
    };

    public func getStatusDuration(status: Status) : Duration {
      switch(status){
        case(#CANDIDATE) { params_.get().interest_duration; };
        case(#OPEN) { params_.get().opinion_duration; };
        case(#REJECTED) { params_.get().rejected_duration; };
        case(_) { Debug.trap("There is no duration for this status"); };
      };
    };

    public func setStatusDuration(status: Status, duration: Duration) {
      switch(status){
        case(#CANDIDATE) {       params_.set({ params_.get() with interest_duration       = duration; }) };
        case(#OPEN) {        params_.set({ params_.get() with opinion_duration        = duration; }) };
        case(#REJECTED) {                params_.set({ params_.get() with rejected_duration       = duration; }) };
        case(_) { Debug.trap("Cannot set a duration for this status"); };
      };
    };

    public func getInterestPickRate() : Duration {
      params_.get().interest_pick_rate;
    };

    public func setInterestPickRate(rate: Duration) {
      params_.set({ params_.get() with interest_pick_rate = rate });
    };

    public func getCategories(): Categories {
      categories_;
    };

    public func getQuestions(): Questions {
      questions_;
    };

    public func getStatusManager(): StatusManager {
      status_manager_;
    };

    public func getHistory(): History {
      history_;
    };

    public func getQueries(): QuestionQueries {
      queries_;
    };

    public func getInterestVotes(): InterestVotes2 {
      interest_votes_;
    };

    public func getOpinionVotes(): OpinionVotes2 {
      opinion_votes_;
    };

    public func getCategorizationVotes(): CategorizationVotes2 {
      categorization_votes_;
    };

  };

};