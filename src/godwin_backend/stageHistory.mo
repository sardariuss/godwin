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

  public func setActiveStage<S>(history: StageHistory<S>, record: StageRecord<S>) : StageHistory<S> {
    assert(record.timestamp > getActiveStage(history).timestamp);
    append(history, [record]);
  };

  public func getActiveStage<S>(history: StageHistory<S>) : StageRecord<S> {
    history[history.size() - 1];
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