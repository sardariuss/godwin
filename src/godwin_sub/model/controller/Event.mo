import Map "mo:map/Map";

module {

  type Time = Int;
  
  public type Event = {
    #TIME_UPDATE;
    #REOPEN_QUESTION ;
  };

  func toKey(event: Event) : Text {
    switch(event){
      case(#TIME_UPDATE)     { "TIME_UPDATE";     };
      case(#REOPEN_QUESTION) { "REOPEN_QUESTION"; };
    };
  };

  func hashEvent(a: Event) : Nat32 { Map.thash.0(toKey(a)); };
  func equalEvent(a: Event, b: Event) : Bool { Map.thash.1(toKey(a), toKey(b)); };
  
  public let event_hash : Map.HashUtils<Event> = ( func(a) = hashEvent(a), func(a, b) = equalEvent(a, b), func() = #TIME_UPDATE );

};