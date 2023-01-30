import Map "mo:map/Map";
import Utils "Utils";

import WMap "wrappers/WMap";
import Set "mo:map/Set";

import Option "mo:base/Option";
import Iter "mo:base/Iter";
import Array "mo:base/Array";

module {

  type Map<K, V> = Map.Map<K, V>;
  type WMap2D<K1, K2, V> = WMap.WMap2D<K1, K2, V>;
  type Iter<T> = Iter.Iter<T>;
  type Set<T> = Set.Set<T>;

  public type StateInfo<S, I> = {
    state: S;
    info: I;
  };
  public type Condition<S, I, M> = (StateInfo<S, I>, M) -> Bool;
  public type Transitions<S, I, M> = WMap2D<S, S, Condition<S, I, M>>;
  public type Events<E, S> = WMap2D<E, S, Set<S>>;
  public type Schema<S, E, I, M> = {
    transitions: Transitions<S, I, M>;
    events: Events<E, S>;
    state_hash: Map.HashUtils<S>;
  };
  public type StateMachine<S, E, I, M> = {
    schema: Schema<S, E, I, M>;
    model: M;
    current: StateInfo<S, I>;
  };

  public func init<S, E, I, M>(state_hash: Map.HashUtils<S>, event_hash: Map.HashUtils<E>) : Schema<S, E, I, M> {
    {
      transitions = WMap.new2D<S, S, Condition<S, I, M>>(state_hash, state_hash);
      events = WMap.new2D<E, S, Set<S>>(event_hash, state_hash);
      state_hash;
    };
  };

  public func addTransition<S, E, I, M>(schema: Schema<S, E, I, M>, from: S, to: S, condition: Condition<S, I, M>, events: [E]) {
    ignore schema.transitions.put(from, to, condition);
    for (event in Array.vals<E>(events)) {
      let set = Option.get(schema.events.get(event, from), Set.new<S>());
      ignore Set.put<S>(set, schema.state_hash, to);
      ignore schema.events.put(event, from, set);
    };
  };

  public func submitEvent<S, E, I, M>(state_machine: StateMachine<S, E, I, M>, event: E) : ?S {
    let { schema; model; current; } = state_machine;
    let { transitions; events; } = schema;
    for(next in getNextStates(events, event, current.state)) {
      if (canTransition(transitions, current, next, model)) {
        return ?next;
      };
    };
    null;
  };

  func getNextStates<E, S>(events: Events<E, S>, event: E, from: S) : Iter<S> {
    Set.keys(Option.get(events.get(event, from), Set.new<S>()));
  };
  
  func canTransition<S, I, M>(transitions: Transitions<S, I, M>, from: StateInfo<S, I>, to: S, model: M) : Bool {
    Option.getMapped<Condition<S, I, M>, Bool>(
      transitions.get(from.state, to), 
      func(condition: Condition<S, I, M>) : Bool {
        condition(from, model);
      },
      false
    );
  };

};