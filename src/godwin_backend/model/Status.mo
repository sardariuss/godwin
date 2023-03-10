import Types "Types";

import Map "mo:map/Map";

module {

  // For convenience: from types module
  type Status = Types.Status;

  public func statusToText(status: Status) : Text {
    switch(status){
      case(#CANDIDATE)               { "CANDIDATE"; };
      case(#OPEN)                    { "OPEN"; };
      case(#CLOSED)                  { "CLOSED"; };
      case(#REJECTED)                { "REJECTED"; };
      case(#TRASH)                   { "TRASH"; };
    };
  };

  public func hashStatus(a: Status) : Nat { Map.thash.0(statusToText(a)); };
  public func equalStatus(a: Status, b: Status) : Bool { Map.thash.1(statusToText(a), statusToText(b)); };
  public let status_hash : Map.HashUtils<Status> = ( func(a) = hashStatus(a), func(a, b) = equalStatus(a, b));

};