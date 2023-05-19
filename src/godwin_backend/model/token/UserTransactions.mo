import Types               "Types";

import Map                 "mo:map/Map";

import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal    = Principal.Principal;

  type Map<K, V>    = Map.Map<K, V>;

  type Id           = Nat;
  type Transactions = Types.Transactions;
  type TxIndex      = Types.TxIndex;
  type PayoutResult = Types.PayoutResult;

  public class UserTransactions(
    _register: Map<Principal, Map<Id, Transactions>>,
  ) {

    public func initWithPayin(principal: Principal, id: Id, tx_index: TxIndex) {
      // Get the transactions from this user
      let transactions = getUserTransactions(principal);
      // Check there is not already a record for this element
      if (Map.has(transactions, Map.nhash, id)){
        Debug.trap("Cannot init transaction record: " #
          "there is already a transaction record for the principal '" # Principal.toText(principal) # "' and element '" # Nat.toText(id) # "'");
      };
      // Add the payin
      Map.set(transactions, Map.nhash, id, { payin = tx_index; payout = #PENDING; });
      Map.set(_register, Map.phash, principal, transactions);
    };

    public func setPayout(principal: Principal, id: Id, refund: ?PayoutResult, reward: ?PayoutResult){
      let error_prefix = "Cannot update the transaction record for principal '" # Principal.toText(principal) # "' and element '" # Nat.toText(id) # "'";
      // Get the transactions from this user
      let transactions = getUserTransactions(principal);
      // Get the record for this element
      var record = switch (Map.get(transactions, Map.nhash, id)) {
        case(null) { Debug.trap(error_prefix # ": the transaction record cannot be found"); };
        case(?record) { record; };
      };
      // Check the payout has not already been set
      if(record.payout != #PENDING) {
        Debug.trap(error_prefix # ": the payout has already been set");
      };
      // Set the payout
      record := { record with payout = #PROCESSED({ refund; reward; }) };
      Map.set(transactions, Map.nhash, id, record);
      Map.set(_register, Map.phash, principal, transactions);
    };

    func getUserTransactions(principal: Principal) : Map<Id, Transactions> {
      Option.get(Map.get(_register, Map.phash, principal), Map.new<Id, Transactions>(Map.nhash));
    };

  };

};