import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";

module {

  type Hash = Hash.Hash;
  
  type Callback<A> = (?A, ?A) -> ();

  public class Observers<T, A>(equal: (T, T) -> Bool, hash: (T) -> Hash) {

    let observers_ = HashMap.HashMap<T, Buffer.Buffer<Callback<A>>>(0, equal, hash);

    public func addObs(obs_type: T, obs_func: Callback<A>) {
      let buffer = Option.get(observers_.get(obs_type), Buffer.Buffer<Callback<A>>(0));
      buffer.add(obs_func);
      observers_.put(obs_type, buffer);
    };

    public func callObs(obs_type: T, old: ?A, new: ?A) {
      Option.iterate(observers_.get(obs_type), func(buffer: Buffer.Buffer<Callback<A>>) {
        for (obs_func in buffer.vals()){
          obs_func(old, new)
        };
      });
    };

  };

};