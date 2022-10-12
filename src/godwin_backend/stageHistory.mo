import Types "types";

import Time "mo:base/Time";
import Buffer "mo:base/Buffer";

module {

  // For convenience: from base module
  type Time = Time.Time;
  // For convenience: from types module
  type StageRecord<S> = Types.StageRecord<S>;
  type StageHistory<S> = Types.StageHistory<S>;

  public func initStageHistory<S>(stage: S) : StageHistory<S> {
    [{timestamp = Time.now(); stage;}];
  };

  public func setActiveStage<S>(stage_records: StageHistory<S>, stage: S) : StageHistory<S> {
    append(stage_records, [{timestamp = Time.now(); stage;}]);
  };

  public func getActiveStageRecord<S>(stage_records: StageHistory<S>) : StageRecord<S> {
    stage_records[stage_records.size() - 1];
  };

  public func getActiveStage<S>(stage_records: StageHistory<S>) : S {
    stage_records[stage_records.size() - 1].stage;
  };

  public func getActiveTimestamp<S>(stage_records: StageHistory<S>) : Time {
    stage_records[stage_records.size() - 1].timestamp;
  };

  // It is not possible to use the append function from Utils because Utils imports StageHistory
  func append<T>(left: [T], right: [T]) : [T] {
    let buffer = Buffer.Buffer<T>(left.size());
    for(val in left.vals()){
      buffer.add(val);
    };
    for(val in right.vals()){
      buffer.add(val);
    };
    return buffer.toArray();
  };

};