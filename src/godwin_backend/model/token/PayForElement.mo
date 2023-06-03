import Types               "Types";
import SubaccountGenerator "SubaccountGenerator";
import TransactionsRecords "TransactionsRecords";

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
  type Principal                = Principal.Principal;
  type Result<Ok, Err>          = Result.Result<Ok, Err>;
  type Buffer<T>                = Buffer.Buffer<T>;

  type Map<K, V>                = Map.Map<K, V>;
  
  type SubaccountPrefix         = Types.SubaccountPrefix;
  type ReapAccountRecipient     = Types.ReapAccountRecipient;
  type ReapAccountError         = Types.ReapAccountError;
  type ReapAccountResult        = Types.ReapAccountResult;
  type TransferFromMasterResult = Types.TransferFromMasterResult;
  type TransactionsRecord       = Types.TransactionsRecord;
  type IPayInterface            = Types.IPayInterface;
  type Balance                  = Types.Balance;

  type Id                       = Nat;

  // \note: Use the IPayInterface to not link with the actual PayInterface which uses
  // the canister:godwin_token. This is required to be able to build the tests.
  public func build(
    transactions_register: Map<Principal, Map<Id, TransactionsRecord>>,
    pay_interface: IPayInterface,
    subaccount_prefix: SubaccountPrefix
  ) : PayForElement {
    PayForElement(
      TransactionsRecords.TransactionsRecords(transactions_register),
      pay_interface,
      subaccount_prefix
    );
  };

  public class PayForElement(
    _user_transactions: TransactionsRecords.TransactionsRecords,
    _pay_interface: IPayInterface,
    _subaccount_prefix: SubaccountPrefix
  ) {

    public func payin(id: Id, principal: Principal, amount: Balance) : async* TransferFromMasterResult {
      switch(await* _pay_interface.transferFromMaster(principal, SubaccountGenerator.getSubaccount(_subaccount_prefix, id), amount)){
        case(#err(err)) { #err(err); };
        case(#ok(tx_index)) { 
          _user_transactions.initWithPayin(principal, id, tx_index);
          #ok(tx_index);
        };
      };
    };

    public func payout(id: Id, recipients: Buffer<ReapAccountRecipient>) : async* () {

      let results = Map.new<Principal, ReapAccountResult>(Map.phash);
      await* _pay_interface.reapSubaccount(SubaccountGenerator.getSubaccount(_subaccount_prefix, id), recipients, results);
      
      for ((principal, result) in Map.entries(results)) {
        _user_transactions.setPayout(principal, id, ?result, null); // @todo: add the reward
      };

    };

    public func findTransactionsRecord(principal: Principal, id: Id) : ?TransactionsRecord {
      _user_transactions.find(principal, id);
    };

  };

};