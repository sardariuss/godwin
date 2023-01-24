module {

  public type Ref<V> = {
    var v: V;
  };

  public class WRef<V>(ref_: Ref<V>){

    public func set(v: V) {
      ref_.v := v;
    };

    public func get() : V {
      ref_.v;
    };

  };

};