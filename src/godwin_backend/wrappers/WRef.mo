import Types "../types";

module {

  type Ref<V> = Types.Ref<V>;

  public class WRef<V>(ref_: Ref<V>){

    public func set(v: V) {
      ref_.v := v;
    };

    public func get() : V {
      ref_.v;
    };

  };

};