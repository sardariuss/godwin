import Types               "Types";
import SubaccountGenerator "SubaccountGenerator";
import TransactionsRecords "TransactionsRecords";

import Map                 "mo:map/Map";

import Principal           "mo:base/Principal";
import Result              "mo:base/Result";
import Iter                "mo:base/Iter";
import Float               "mo:base/Float";
import Option              "mo:base/Option";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";
import Trie                "mo:base/Trie";

module {

  // For convenience: from base module
  type Principal                = Principal.Principal;
  type Result<Ok, Err>          = Result.Result<Ok, Err>;
  type Iter<T>                  = Iter.Iter<T>;

  type Map<K, V>                = Map.Map<K, V>;
  type Key<K>                   = Trie.Key<K>;
  func key(p: Principal) : Key<Principal> { { hash = Principal.hash(p); key = p; } };
  
  type SubaccountPrefix         = Types.SubaccountPrefix;
  type ReapAccountRecipient     = Types.ReapAccountRecipient;
  type ReapAccountError         = Types.ReapAccountError;
  type ReapAccountResult        = Types.ReapAccountResult;
  type TransferFromMasterResult = Types.TransferFromMasterResult;
  type TransactionsRecord       = Types.TransactionsRecord;
  type ITokenInterface          = Types.ITokenInterface;
  type Balance                  = Types.Balance;
  type PayoutRecipient          = Types.PayoutRecipient;
  type MintResult               = Types.MintResult;
  type MintRecipient            = Types.MintRecipient;

  type Id                       = Nat;

  // \note: Use the ITokenInterface to not link with the actual TokenInterface which uses
  // the canister:godwin_token. This is required to be able to build the tests.
  public func build(
    transactions_register: Map<Principal, Map<Id, TransactionsRecord>>,
    token_interface: ITokenInterface,
    subaccount_prefix: SubaccountPrefix
  ) : PayForElement {
    PayForElement(
      TransactionsRecords.TransactionsRecords(transactions_register),
      token_interface,
      subaccount_prefix
    );
  };

  public class PayForElement(
    _user_transactions: TransactionsRecords.TransactionsRecords,
    _token_interface: ITokenInterface,
    _subaccount_prefix: SubaccountPrefix
  ) {

    public func payin(id: Id, principal: Principal, amount: Balance) : async* TransferFromMasterResult {
      switch(await* _token_interface.transferFromMaster(principal, SubaccountGenerator.getSubaccount(_subaccount_prefix, id), amount)){
        case(#err(err)) { #err(err); };
        case(#ok(tx_index)) { 
          _user_transactions.initWithPayin(principal, id, tx_index);
          #ok(tx_index);
        };
      };
    };

    public func payout(id: Id, recipients: Iter<PayoutRecipient>) : async* () {
      // Refund the users
      let refunds = await* _token_interface.reapSubaccount(
        SubaccountGenerator.getSubaccount(_subaccount_prefix, id), 
        Iter.map(recipients, func({to; args;} : PayoutRecipient): ReapAccountRecipient { { to; share = args.refund_share; }; })
      );
      // Reward the users
      let rewards = await* _token_interface.mintBatch(
        Iter.map(recipients, func({to; args;} : PayoutRecipient): MintRecipient { { to; amount = Option.get(args.reward_tokens, 0); }; })
      );
      // Watchout, this loop only iterates on the refunds, not the rewards.
      // It is assumed that if for a user there is no refund, then there is no reward.
      // @todo: do not use this assumption!
      // @todo: should do a Trie.disj to get the union of both tries.
      for ((principal, result) in Trie.iter(refunds)) {
        let reward = switch(Trie.get(rewards, key(principal), Principal.equal)){
          case(null) { null; };
          case(?r) { r; };
        };
        _user_transactions.setPayout(principal, id, result, reward);
      };
    };

    public func findTransactionsRecord(principal: Principal, id: Id) : ?TransactionsRecord {
      _user_transactions.find(principal, id);
    };

  };

};