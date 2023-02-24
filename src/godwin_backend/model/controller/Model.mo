import Debug "mo:base/Debug";

import Ref "../../utils/Ref";
import WRef "../../utils/wrappers/WRef";
import Duration "../../utils/Duration";
import Types "../Types";

module {

  type Time = Int;
  type Status = Types.Status;
  type Duration = Duration.Duration;
  type Ref<T> = Ref.Ref<T>;
  type WRef<T> = WRef.WRef<T>;

  public func build(time: Ref<Time>, most_interesting: Ref<?Nat>, last_pick_date: Ref<Time>, params: Ref<Types.SchedulerParameters>) : Model {
    Model(
      WRef.WRef(time),
      WRef.WRef(most_interesting),
      WRef.WRef(last_pick_date),
      WRef.WRef(params)
    );
  };

  public class Model(time_: WRef<Time>, most_interesting_: WRef<?Nat>, last_pick_date_: WRef<Time>, params_: WRef<Types.SchedulerParameters>) = {

    public func getTime() : Time {
      time_.get();
    };

    public func setTime(time: Time) {
      time_.set(time);
    };

    public func getMostInteresting() : ?Nat {
      most_interesting_.get();
    };

    public func setMostInteresting(most_interesting: ?Nat) {
      most_interesting_.set(most_interesting);
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

  };

};