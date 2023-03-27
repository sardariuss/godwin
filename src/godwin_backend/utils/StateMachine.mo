import Map "mo:map/Map";
import Utils "Utils";

import WMap "wrappers/WMap";
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
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  public type Condition<M> = M -> Bool;
  public type Transitions<S, M> = WMap2D<S, ?S, Condition<M>>;
  public type Events<E, S> = WMap2D<E, S, Set<?S>>;
  public type Schema<S, E, M> = {
    transitions: Transitions<S, M>;
    events: Events<E, S>;
    state_opt_hash: Map.HashUtils<?S>;
  };
  public type StateMachine<S, E, M> = {
    schema: Schema<S, E, M>;
    model: M;
  };

  public func init<S, E, M>(state_hash: Map.HashUtils<S>, state_opt_hash: Map.HashUtils<?S>, event_hash: Map.HashUtils<E>) : Schema<S, E, M> {
    {
      transitions = WMap.new2D<S, ?S, Condition<M>>(state_hash, state_opt_hash);
      events = WMap.new2D<E, S, Set<?S>>(event_hash, state_hash);
      state_opt_hash;
    };
  };

  public func addTransition<S, E, M>(schema: Schema<S, E, M>, from: S, to: ?S, condition: Condition<M>, events: [E]) {
    ignore schema.transitions.put(from, to, condition);
    for (event in Array.vals<E>(events)) {
      let set = Option.get(schema.events.getOpt(event, from), Set.new<?S>());
      ignore Set.put<?S>(set, schema.state_opt_hash, to);
      ignore schema.events.put(event, from, set);
    };
  };

  public func submitEvent<S, E, M>(state_machine: StateMachine<S, E, M>, current: S, event: E) : Result<?S, ()> {
    let { transitions; events; } = state_machine.schema;
    for(next in getNextStates(events, event, current)) {
      if (canTransition(transitions, current, next, state_machine.model)) {
        return #ok(next);
      };
    };
    #err;
  };

  func getNextStates<E, S>(events: Events<E, S>, event: E, from: S) : Iter<?S> {
    Set.keys(Option.get(events.getOpt(event, from), Set.new<?S>()));
  };
  
  func canTransition<S, M>(transitions: Transitions<S, M>, from: S, to: ?S, model: M) : Bool {
    Option.getMapped<Condition<M>, Bool>(
      transitions.getOpt(from, to), 
      func(condition: Condition<M>) : Bool {
        condition(model);
      },
      false
    );
  };

};