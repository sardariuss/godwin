import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";

module {

  type Hash = Hash.Hash;
  
  type Callback<A> = (?A, ?A) -> ();

  public class Observers<T, A>(equal: (T, T) -> Bool, hash: (T) -> Hash) {

    let _observers = HashMap.HashMap<T, Buffer.Buffer<Callback<A>>>(0, equal, hash);

    public func addObs(obs_type: T, obs_func: Callback<A>) {
      let buffer = Option.get(_observers.get(obs_type), Buffer.Buffer<Callback<A>>(0));
      buffer.add(obs_func);
      _observers.put(obs_type, buffer);
    };

    public func callObs(obs_type: T, old: ?A, new: ?A) {
      Option.iterate(_observers.get(obs_type), func(buffer: Buffer.Buffer<Callback<A>>) {
        for (obs_func in buffer.vals()){
          obs_func(old, new)
        };
      });
    };

  };

  public class Observers2<A>() {

    let _observers = Buffer.Buffer<Callback<A>>(0);

    public func addObs(obs_func: Callback<A>) {
      _observers.add(obs_func);
    };

    public func callObs(old: ?A, new: ?A) {
      for (obs_func in _observers.vals()){
        obs_func(old, new);
      };
    };

  };

};