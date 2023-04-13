import Types "../Types";

import Map "mo:map/Map";

import Debug "mo:base/Debug";

module {

  type Question = Types.Question;
  type Time = Int;
  
  public type Event = {
    #TIME_UPDATE:      { #id; #data: { time: Time; }; };
    #REOPEN_QUESTION : { #id; #data: { caller: Principal; } };
  };

  func toKey(event: Event) : Text {
    switch(event){
      case(#TIME_UPDATE(_)) { "TIME_UPDATE"; };
      case(#REOPEN_QUESTION(_)) { "REOPEN_QUESTION"; };
    };
  };

  func hashEvent(a: Event) : Nat { Map.thash.0(toKey(a)); };
  func equalEvent(a: Event, b: Event) : Bool { Map.thash.1(toKey(a), toKey(b)); };
  
  public let event_hash : Map.HashUtils<Event> = ( func(a) = hashEvent(a), func(a, b) = equalEvent(a, b) );

};