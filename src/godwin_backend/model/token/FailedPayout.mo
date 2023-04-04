import Types "../Types";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";

module {

  type FailedPayout = Types.FailedPayout;

  // @warn: This doesn't take the subaccount in parameter, this assumes that adding the time in the payout is enough to make it unique
  func toText(failed_payout: FailedPayout) : Text {
    Nat64.toText(failed_payout.time) # Nat.toText(failed_payout.amount) # Principal.toText(failed_payout.principal);
  };
  public func hashFailedPayout(a: FailedPayout) : Nat { Map.thash.0(toText(a)); };
  public func equalFailedPayout(a: FailedPayout, b: FailedPayout) : Bool { Map.thash.1(toText(a), toText(b)); };
  public let hash : Map.HashUtils<FailedPayout> = ( func(a) = hashFailedPayout(a), func(a, b) = equalFailedPayout(a, b));
 
}