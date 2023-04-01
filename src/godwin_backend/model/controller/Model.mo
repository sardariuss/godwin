import Types "../Types";
import QuestionQueries "../QuestionQueries";
import Categorizations "../votes/Categorizations";
import Questions "../Questions";
import Votes "../votes/Votes";
import Categories "../Categories";
import Users "../Users";
import SubaccountGenerator "../token/SubaccountGenerator";
import StatusManager "../StatusManager";
import Interests "../votes/Interests";
import Opinions "../votes/Opinions";

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
  //type Master = Types.Master;
  type Categories = Categories.Categories;
  type Questions = Questions.Questions;
  type Users = Users.Users;
  type QuestionQueries = QuestionQueries.QuestionQueries;
  type SubaccountGenerator = SubaccountGenerator.SubaccountGenerator;
  type StatusManager = StatusManager.StatusManager;
  type InterestVotes = Interests.Interests;
  type OpinionVotes = Opinions.Opinions;
  type CategorizationVotes = Categorizations.Categorizations;

  public func build(
    name: Ref<Text>,
    admin: Ref<Principal>,
    time: Ref<Time>,
    last_pick_date: Ref<Time>,
    params: Ref<SchedulerParameters>,
    categories: Categories,
    questions: Questions,
    status_manager: StatusManager,
    users: Users,
    queries: QuestionQueries,
    interest_votes: InterestVotes,
    opinion_votes: OpinionVotes,
    categorization_votes: CategorizationVotes
  ) : Model {
    Model(
      WRef.WRef(name),
      WRef.WRef(admin),
      WRef.WRef(time),
      WRef.WRef(last_pick_date),
      WRef.WRef(params),
      categories,
      questions,
      status_manager,
      users,
      queries,
      interest_votes,
      opinion_votes,
      categorization_votes
    );
  };

  public class Model(
    _name: WRef<Text>,
    _admin: WRef<Principal>,
    _time: WRef<Time>,
    _last_pick_date: WRef<Time>,
    _params: WRef<SchedulerParameters>,
    _categories: Categories,
    _questions: Questions,
    _status_manager: StatusManager,
    _users: Users,
    _queries: QuestionQueries,
    _interest_votes: InterestVotes,
    _opinion_votes: OpinionVotes,
    _categorization_votes: CategorizationVotes
  ) = {

//    public func getMaster() : Master {
//      actor(Principal.toText(_admin.get())); // @todo: shall the admin and the master be different?
//    };

    public func getName() : Text {
      _name.get();
    };

    public func setName(name: Text) {
      _name.set(name);
    };

    public func getAdmin(): Principal {
      _admin.get();
    };

    public func setAdmin(admin: Principal) {
      _admin.set(admin);
    };

    public func getTime() : Time {
      _time.get();
    };

    public func setTime(time: Time) {
      _time.set(time);
    };

    public func getLastPickDate() : Time {
      _last_pick_date.get();
    };

    public func setLastPickDate(last_pick_date: Time) {
      _last_pick_date.set(last_pick_date);
    };

    public func getStatusDuration(status: Status) : Duration {
      switch(status){
        case(#CANDIDATE) { _params.get().interest_duration; };
        case(#OPEN) { _params.get().opinion_duration; };
        case(#REJECTED) { _params.get().rejected_duration; };
        case(_) { Debug.trap("There is no duration for this status"); };
      };
    };

    public func setStatusDuration(status: Status, duration: Duration) {
      switch(status){
        case(#CANDIDATE) {       _params.set({ _params.get() with interest_duration       = duration; }) };
        case(#OPEN) {        _params.set({ _params.get() with opinion_duration        = duration; }) };
        case(#REJECTED) {                _params.set({ _params.get() with rejected_duration       = duration; }) };
        case(_) { Debug.trap("Cannot set a duration for this status"); };
      };
    };

    public func getInterestPickRate() : Duration {
      _params.get().interest_pick_rate;
    };

    public func setInterestPickRate(rate: Duration) {
      _params.set({ _params.get() with interest_pick_rate = rate });
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

    public func getUsers(): Users {
      _users;
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

  };

};