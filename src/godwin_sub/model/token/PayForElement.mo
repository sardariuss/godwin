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
  type RedistributeBtcReceiver  = Types.RedistributeBtcReceiver;
  type RedistributeBtcResult    = Types.RedistributeBtcResult;
  type PullBtcResult            = Types.PullBtcResult;
  type TransactionsRecord       = Types.TransactionsRecord;
  type ITokenInterface          = Types.ITokenInterface;
  type Balance                  = Types.Balance;
  type PayoutRecipient          = Types.PayoutRecipient;
  type RewardGwcResult          = Types.RewardGwcResult;
  type RewardGwcReceiver        = Types.RewardGwcReceiver;

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

    public func payin(id: Id, principal: Principal, amount: Balance) : async* PullBtcResult {
      switch(await _token_interface.pullBtc(principal, SubaccountGenerator.getSubaccount(_subaccount_prefix, id), amount)){
        case(#err(err)) { #err(err); };
        case(#ok(tx_index)) { 
          _user_transactions.initWithPayin(principal, id, tx_index);
          #ok(tx_index);
        };
      };
    };

    public func payout(id: Id, recipients: Iter<PayoutRecipient>) : async* () {
      // Refund the users
      let refunds = await _token_interface.redistributeBtc(
        SubaccountGenerator.getSubaccount(_subaccount_prefix, id), 
        Iter.map(recipients, func({to; args;} : PayoutRecipient): RedistributeBtcReceiver { { to; share = args.refund_share; }; })
      );
      // Reward the users
      let rewards = await _token_interface.rewardGwcToAll(
        Iter.map(recipients, func({to; args;} : PayoutRecipient): RewardGwcReceiver { { to; amount = Option.get(args.reward_tokens, 0); }; })
      );
      // Join the refunds and rewards into a single trie
      type Payout = { refund: ?RedistributeBtcResult; reward: ?RewardGwcResult };
      let payouts = Trie.disj(refunds, rewards, Principal.equal, func(refund: ??RedistributeBtcResult, reward: ??RewardGwcResult) : Payout {
        {
          refund = switch(refund){ case(null) { null; }; case(?r) { r; }; };
          reward = switch(reward){ case(null) { null; }; case(?r) { r; }; };
        };
      });
      for ((principal, {refund; reward;}) in Trie.iter(payouts)) {
        _user_transactions.setPayout(principal, id, refund, reward);
      };
    };

    public func findTransactionsRecord(principal: Principal, id: Id) : ?TransactionsRecord {
      _user_transactions.find(principal, id);
    };

  };

};