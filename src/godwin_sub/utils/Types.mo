module {

  public type Direction = { #FWD; #BWD; };
  public type ScanLimitResult<K> = { keys : [K]; next : ?K };

  public type Duration = {
    #DAYS: Nat;
    #HOURS: Nat;
    #MINUTES: Nat;
    #SECONDS: Nat;
    #NS: Nat;
  };

};