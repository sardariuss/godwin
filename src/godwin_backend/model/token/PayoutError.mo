import Types "../Types";

import Map "mo:map/Map";

import Principal "mo:base/Principal";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";

module {

  type PayoutError = Types.PayoutError;

  // @warn: This doesn't take the subaccount in parameter, this assumes that adding the time in the payout is enough to make it unique
  func toText(failed_payout: PayoutError) : Text {
    Nat64.toText(failed_payout.time) # Nat.toText(failed_payout.amount) # Principal.toText(failed_payout.principal);
  };
  public func hashPayoutError(a: PayoutError) : Nat { Map.thash.0(toText(a)); };
  public func equalPayoutError(a: PayoutError, b: PayoutError) : Bool { Map.thash.1(toText(a), toText(b)); };
  public let hash : Map.HashUtils<PayoutError> = ( func(a) = hashPayoutError(a), func(a, b) = equalPayoutError(a, b));
 
}