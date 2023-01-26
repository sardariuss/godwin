
module {

  public type Ref<V> = {
    var v: V;
  };

  public func initRef<V>(value: V) : Ref<V> {
    { var v = value; };
  };

};