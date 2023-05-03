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
    };
  };

  public func hashStatus(a: Status) : Nat32 { Map.thash.0(statusToText(a)); };
  public func equalStatus(a: Status, b: Status) : Bool { Map.thash.1(statusToText(a), statusToText(b)); };
  public let status_hash : Map.HashUtils<Status> = ( func(a) = hashStatus(a), func(a, b) = equalStatus(a, b), func() = #CANDIDATE);

  public func optStatusToText(opt_status: ?Status) : Text {
    switch(opt_status){
      case(null) { "NULL"; };
      case(?status) { statusToText(status); };
    };
  };

  public func hashOptStatus(a: ?Status) : Nat32 { Map.thash.0(optStatusToText(a)); };
  public func equalOptStatus(a: ?Status, b: ?Status) : Bool { Map.thash.1(optStatusToText(a), optStatusToText(b)); };
  public let opt_status_hash : Map.HashUtils<?Status> = ( func(a) = hashOptStatus(a), func(a, b) = equalOptStatus(a, b), func() = null);

};