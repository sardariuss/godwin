import Map "mo:map/Map";

import WMap "wrappers/WMap";
import Set "mo:map/Set";

import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Array "mo:base/Array";

module {

  type Time              = Int;
  type Map<K, V>         = Map.Map<K, V>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type Iter<T>           = Iter.Iter<T>;
  type Set<T>            = Set.Set<T>;

  public type Condition<S, M>   = (M, Time, Principal, ?S) -> async* Bool;
  public type Transitions<S, M> = WMap2D<S, ?S, Condition<S, M>>;
  public type Events<E, S>      = WMap2D<E, S, Set<?S>>;
  public type Schema<S, E, M>   = {
    transitions: Transitions<S, M>;
    events: Events<E, S>;
    state_opt_hash: Map.HashUtils<?S>;
  };

  public func hasTransition<E, S, M>(schema: Schema<S, E, M>, event: E, state: S) : Bool {
    schema.events.has(event, state);
  };

  public func init<S, E, M>(
    state_hash: Map.HashUtils<S>,
    state_opt_hash: Map.HashUtils<?S>,
    event_hash: Map.HashUtils<E>
  ) : Schema<S, E, M> {
    {
      transitions = WMap.new2D<S, ?S, Condition<S, M>>(state_hash, state_opt_hash);
      events = WMap.new2D<E, S, Set<?S>>(event_hash, state_hash);
      state_opt_hash;
    };
  };

  public func addTransition<S, E, M>(schema: Schema<S, E, M>, from: S, to: ?S, condition: Condition<S, M>, events: [E]) {
    ignore schema.transitions.put(from, to, condition);
    for (event in Array.vals<E>(events)) {
      let set = Option.get(schema.events.getOpt(event, from), Set.new<?S>(schema.state_opt_hash));
      ignore Set.put<?S>(set, schema.state_opt_hash, to);
      ignore schema.events.put(event, from, set);
    };
  };

  public func submitEvent<S, E, M>(schema: Schema<S, E, M>, current: S, model: M, event: E, time: Time, caller: Principal) : async* Bool {
    let { transitions; events; } = schema;
    var errors : [(?S, Text)] = [];
    for(next in getNextStates(events, event, current, schema.state_opt_hash)) {
      switch(transitions.getOpt(current, next)){
        case(null){ }; // no transition to that state, nothing to do
        case(?condition){
          if (await* condition(model, time, caller, next)){
            return true;
          };
        };
      };
    };
    false;
  };

  func getNextStates<E, S>(events: Events<E, S>, event: E, from: S, state_opt_hash: Map.HashUtils<?S>) : Iter<?S> {
    Set.keys(Option.get(events.getOpt(event, from), Set.new<?S>(state_opt_hash)));
  };

};