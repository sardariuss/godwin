module {
  public type WrappedRef<T> = {
    var ref: T;
  };

  public func init<T>(t : T) : WrappedRef<T>{
    {
      var ref = t;
    };
  };
}