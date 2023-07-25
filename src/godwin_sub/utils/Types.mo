module {

  public type Direction = { #FWD; #BWD; };
  public type ScanLimitResult<K> = { keys : [K]; next : ?K };

  public type Duration = {
    #YEARS: Nat;
    #DAYS: Nat;
    #HOURS: Nat;
    #MINUTES: Nat;
    #SECONDS: Nat;
    #NS: Nat;
  };

  public type LogitNormalParams = {
    sigma: Float;
    mu: Float;
  };

  public type RealNumber = {
    #NUMBER: Float;
    #POSITIVE_INFINITY;
    #NEGATIVE_INFINITY;
  };

  public type LogitParameters = {
    k: Float;
    l: Float;
  };

};