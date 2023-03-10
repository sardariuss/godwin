import Map "mo:map/Map";

module {
  
  public type Event = {
    #TIME_UPDATE;
    #REOPEN_QUESTION;
  };

  func toTextEvent(event: Event) : Text {
    switch(event){
      case(#TIME_UPDATE) { "TIME_UPDATE"; };
      case(#REOPEN_QUESTION) { "REOPEN_QUESTION"; };
    };
  };

  func hashEvent(a: Event) : Nat { Map.thash.0(toTextEvent(a)); };
  func equalEvent(a: Event, b: Event) : Bool { Map.thash.1(toTextEvent(a), toTextEvent(b)); };
  
  public let event_hash : Map.HashUtils<Event> = ( func(a) = hashEvent(a), func(a, b) = equalEvent(a, b) );

};