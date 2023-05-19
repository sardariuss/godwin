import Types               "Types";
import SubaccountGenerator "SubaccountGenerator";
import PayInterface        "PayInterface";
import UserTransactions    "UserTransactions";

import Map                 "mo:map/Map";

import Principal           "mo:base/Principal";
import Result              "mo:base/Result";
import Buffer              "mo:base/Buffer";
import Float               "mo:base/Float";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal              = Principal.Principal;
  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Buffer<T>              = Buffer.Buffer<T>;

  type Map<K, V>              = Map.Map<K, V>;
  
  type SubaccountPrefix       = Types.SubaccountPrefix;
  type PayinError             = Types.PayinError;
  type PayoutRecipient        = Types.PayoutRecipient;
  type PayoutError            = Types.PayoutError;
  type PayoutResult           = Types.PayoutResult;
  type PayinResult            = Types.PayinResult;
  type Transactions           = Types.Transactions;

  type PayInterface           = PayInterface.PayInterface;

  type Id                     = Nat;

  public func build(
    transactions_register: Map<Principal, Map<Id, Transactions>>,
    pay_interface: PayInterface,
    subaccount_prefix: SubaccountPrefix,
    pay_in_price: Nat
  ) : PayForElement {
    PayForElement(
      UserTransactions.UserTransactions(transactions_register),
      pay_interface,
      subaccount_prefix,
      pay_in_price
    );
  };

  public class PayForElement(
    _user_transactions: UserTransactions.UserTransactions,
    _pay_interface: PayInterface,
    _subaccount_prefix: SubaccountPrefix,
    _pay_in_price: Nat // @todo
  ) {

    public func payin(id: Id, principal: Principal) : async* PayinResult {
      switch(await* _pay_interface.payin(SubaccountGenerator.getSubaccount(_subaccount_prefix, id), principal, _pay_in_price)){
        case(#err(err)) { #err(err); };
        case(#ok(tx_index)) { 
          _user_transactions.initWithPayin(principal, id, tx_index);
          #ok(tx_index);
        };
      };
    };

    public func payout(id: Id, recipients: Buffer<PayoutRecipient>) : async* () {

      let results = Map.new<Principal, PayoutResult>(Map.phash);
      await* _pay_interface.batchPayout(SubaccountGenerator.getSubaccount(_subaccount_prefix, id), recipients, results);
      
      for ((principal, result) in Map.entries(results)) {
        _user_transactions.setPayout(principal, id, ?result, null); // @todo: add the reward
      };

    };

  };

};