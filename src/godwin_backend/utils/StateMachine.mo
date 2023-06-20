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
  type Result<Ok> = Result.Result<Ok, Text>;

  public type Condition<M, E, Ok> = (M, E, TransitionResult<Ok>) -> async* ();
  public type Transitions<S, E, Ok, M> = WMap2D<S, ?S, Condition<M, E, Ok>>;
  public type Events<E, S> = WMap2D<E, S, Set<?S>>;
  public type Schema<S, E, Ok, M> = {
    transitions: Transitions<S, E, Ok, M>;
    events: Events<E, S>;
    state_opt_hash: Map.HashUtils<?S>;
  };
  public type OkInfo<S, Ok> = {
    state: ?S;
    info: ?Ok;
  };
  public type EventResult<S, Ok> = WRef<Result.Result<OkInfo<S, Ok>, [(?S, Text)]>>;
  public type TransitionResult<Ok> = WRef<Result<?Ok>>;

  public func init<S, E, Ok, M>(
    state_hash: Map.HashUtils<S>,
    state_opt_hash: Map.HashUtils<?S>,
    event_hash: Map.HashUtils<E>
  ) : Schema<S, E, Ok, M> {
    {
      transitions = WMap.new2D<S, ?S, Condition<M, E, Ok>>(state_hash, state_opt_hash);
      events = WMap.new2D<E, S, Set<?S>>(event_hash, state_hash);
      state_opt_hash;
    };
  };

  public func addTransition<S, E, Ok, M>(schema: Schema<S, E, Ok, M>, from: S, to: ?S, condition: Condition<M, E, Ok>, events: [E]) {
    ignore schema.transitions.put(from, to, condition);
    for (event in Array.vals<E>(events)) {
      let set = Option.get(schema.events.getOpt(event, from), Set.new<?S>(schema.state_opt_hash));
      ignore Set.put<?S>(set, schema.state_opt_hash, to);
      ignore schema.events.put(event, from, set);
    };
  };

  public func initEventResult<S, Ok>() : EventResult<S, Ok> {
    WRef.WRef<Result.Result<OkInfo<S, Ok>, [(?S, Text)]>>(Ref.init(#err([])));
  };

  public func submitEvent<S, E, Ok, M>(schema: Schema<S, E, Ok, M>, current: S, model: M, event: E, result: EventResult<S, Ok>) : async* () {
    let { transitions; events; } = schema;
    var errors : [(?S, Text)] = [];
    for(next in getNextStates(events, event, current, schema.state_opt_hash)) {
      switch(transitions.getOpt(current, next)){
        case(null){ }; // no transition to that state, nothing to do
        case(?condition){
          let transition_result = WRef.WRef<Result.Result<?Ok, Text>>(Ref.init(#err("Unset transition result")));
          await* condition(model, event, transition_result); 
          switch(transition_result.get()){
            case(#ok(info)){ 
              result.set(#ok({ state = next; info; }));
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

  func getNextStates<E, S>(events: Events<E, S>, event: E, from: S, state_opt_hash: Map.HashUtils<?S>) : Iter<?S> {
    Set.keys(Option.get(events.getOpt(event, from), Set.new<?S>(state_opt_hash)));
  };

};