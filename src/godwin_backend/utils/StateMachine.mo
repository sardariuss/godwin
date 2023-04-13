import Map "mo:map/Map";
import Utils "Utils";
import Ref "Ref";

import WMap "wrappers/WMap";
import WRef "wrappers/WRef";
import Set "mo:map/Set";

import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Result "mo:base/Result";

module {

  type Map<K, V> = Map.Map<K, V>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type Iter<T> = Iter.Iter<T>;
  type Set<T> = Set.Set<T>;
  type WRef<T> = WRef.WRef<T>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  public type Condition<M, E, Err> = (M, E, TransitionResult<Err>) -> async* ();
  public type Transitions<S, E, Err, M> = WMap2D<S, ?S, Condition<M, E, Err>>;
  public type Events<E, S> = WMap2D<E, S, Set<?S>>;
  public type Schema<S, E, Err, M> = {
    transitions: Transitions<S, E, Err, M>;
    events: Events<E, S>;
    state_opt_hash: Map.HashUtils<?S>;
  };
  public type EventResult<S, Err> = WRef<Result<?S, [(?S, Err)]>>;
  public type TransitionResult<Err> = WRef<Result<(), Err>>;

  public func init<S, E, Err, M>(
    state_hash: Map.HashUtils<S>,
    state_opt_hash: Map.HashUtils<?S>,
    event_hash: Map.HashUtils<E>,
  ) : Schema<S, E, Err, M> {
    {
      transitions = WMap.new2D<S, ?S, Condition<M, E, Err>>(state_hash, state_opt_hash);
      events = WMap.new2D<E, S, Set<?S>>(event_hash, state_hash);
      state_opt_hash;
    };
  };

  public func addTransition<S, E, Err, M>(schema: Schema<S, E, Err, M>, from: S, to: ?S, condition: Condition<M, E, Err>, events: [E]) {
    ignore schema.transitions.put(from, to, condition);
    for (event in Array.vals<E>(events)) {
      let set = Option.get(schema.events.getOpt(event, from), Set.new<?S>());
      ignore Set.put<?S>(set, schema.state_opt_hash, to);
      ignore schema.events.put(event, from, set);
    };
  };

  public func initEventResult<S, Err>() : EventResult<S, Err> {
    WRef.WRef<Result<?S, [(?S, Err)]>>(Ref.initRef(#err([])));
  };

  public func submitEvent<S, E, Err, M>(schema: Schema<S, E, Err, M>, current: S, model: M, event: E, result: EventResult<S, Err>) : async* () {
    let { transitions; events; } = schema;
    var errors : [(?S, Err)] = [];
    for(next in getNextStates(events, event, current)) {
      switch(transitions.getOpt(current, next)){
        case(null){ }; // no transition to that state, nothing to do
        case(?condition){
          let transition_result = WRef.WRef<Result<(), Err>>(Ref.initRef(#ok));
          await* condition(model, event, transition_result); 
          switch(transition_result.get()){
            case(#ok){ 
              result.set(#ok(next));
              return;
            };
            case(#err(err)){ 
              errors := Utils.append(errors, [(next, err)]);
            };
          };
        };
      };
    };
    result.set(#err(errors));
  };

  func getNextStates<E, S>(events: Events<E, S>, event: E, from: S) : Iter<?S> {
    Set.keys(Option.get(events.getOpt(event, from), Set.new<?S>()));
  };

};