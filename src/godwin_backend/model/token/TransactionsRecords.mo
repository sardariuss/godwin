import Types               "Types";

import Map                 "mo:map/Map";

import Principal           "mo:base/Principal";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal          = Principal.Principal;

  type Map<K, V>          = Map.Map<K, V>;

  type Id                 = Nat;
  type TransactionsRecord = Types.TransactionsRecord;
  type TxIndex            = Types.TxIndex;
  type ReapAccountResult  = Types.ReapAccountResult;
  type MintResult         = Types.MintResult;

  public class TransactionsRecords(
    _register: Map<Principal, Map<Id, TransactionsRecord>>,
  ) {

    public func initWithPayin(principal: Principal, id: Id, tx_index: TxIndex) {
      // Get the transactions from this user
      let transactions = getRecords(principal);
      // Check there is not already a record for this element
      if (Map.has(transactions, Map.nhash, id)){
        Debug.trap("Cannot init transaction record: " #
          "there is already a transaction record for the principal '" # Principal.toText(principal) # "' and element '" # Nat.toText(id) # "'");
      };
      // Add the payin
      Map.set(transactions, Map.nhash, id, { payin = tx_index; payout = #PENDING; });
      Map.set(_register, Map.phash, principal, transactions);
    };

    public func setPayout(principal: Principal, id: Id, refund: ?ReapAccountResult, reward: ?MintResult){
      let error_prefix = "Cannot update the transaction record for principal '" # Principal.toText(principal) # "' and element '" # Nat.toText(id) # "'";
      // Get the transactions from this user
      let transactions = getRecords(principal);
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

    public func find(principal: Principal, id: Id) : ?TransactionsRecord {
      switch(Map.get(_register, Map.phash, principal)){
        case(null) { null; };
        case(?transactions) { Map.get(transactions, Map.nhash, id); };
      };
    };

    func getRecords(principal: Principal) : Map<Id, TransactionsRecord> {
      Option.get(Map.get(_register, Map.phash, principal), Map.new<Id, TransactionsRecord>(Map.nhash));
    };

  };

};