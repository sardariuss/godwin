import Types "../Types";
import QuestionQueries "../QuestionQueries";
import Categorizations "../votes/Categorizations";
import Questions "../Questions";
import Votes "../votes/Votes";
import Categories "../Categories";
import History "../History";
import SubaccountGenerator "../token/SubaccountGenerator";
import SubaccountMap "../token/SubaccountMap";

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

  public func build(
    admin: Ref<Principal>,
    time: Ref<Time>,
    last_pick_date: Ref<Time>,
    params: Ref<SchedulerParameters>,
    categories: Categories,
    questions: Questions,
    history: History,
    queries: QuestionQueries,
    interest_votes: InterestVotes,
    opinion_votes: OpinionVotes,
    categorization_votes: CategorizationVotes,
    interest_subaccounts: SubaccountMap,
    categorization_subaccounts: SubaccountMap,
    subaccount_generator: SubaccountGenerator
  ) : Model {
    Model(
      WRef.WRef(admin),
      WRef.WRef(time),
      WRef.WRef(last_pick_date),
      WRef.WRef(params),
      categories,
      questions,
      history,
      queries,
      interest_votes,
      opinion_votes,
      categorization_votes,
      interest_subaccounts,
      categorization_subaccounts,
      subaccount_generator
    );
  };

  public class Model(
    admin_: WRef<Principal>,
    time_: WRef<Time>,
    last_pick_date_: WRef<Time>,
    params_: WRef<SchedulerParameters>,
    categories_: Categories,
    questions_: Questions,
    history_: History,
    queries_: QuestionQueries,
    interest_votes_: InterestVotes,
    opinion_votes_: OpinionVotes,
    categorization_votes_: CategorizationVotes,
    interest_subaccounts_: SubaccountMap,
    categorization_subaccounts_: SubaccountMap,
    subaccount_generator_: SubaccountGenerator
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

    public func getHistory(): History {
      history_;
    };

    public func getQueries(): QuestionQueries {
      queries_;
    };

    public func getInterestVotes(): InterestVotes {
      interest_votes_;
    };

    public func getOpinionVotes(): OpinionVotes {
      opinion_votes_;
    };

    public func getCategorizationVotes(): CategorizationVotes {
      categorization_votes_;
    };

    public func getInterestSubaccounts(): SubaccountMap {
      interest_subaccounts_;
    };

    public func getCategorizationSubaccounts(): SubaccountMap {
      categorization_subaccounts_;
    };

    public func getSubaccountGenerator(): SubaccountGenerator {
      subaccount_generator_;
    };

  };

};