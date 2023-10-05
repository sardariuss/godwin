import Types               "Types";
import SubaccountGenerator "SubaccountGenerator";
import TransactionsRecords "TransactionsRecords";

import WMap                "../../utils/wrappers/WMap";
import WRef                "../../utils/wrappers/WRef";
import Ref                 "../../utils/Ref";

import Map                 "mo:map/Map";

import Result              "mo:base/Result";
import Debug               "mo:base/Debug";
import Nat                 "mo:base/Nat";
import Array               "mo:base/Array";
import Iter                "mo:base/Iter";
import Trie                "mo:base/Trie";
import Principal           "mo:base/Principal";
import Option              "mo:base/Option";

module {

  type Result<Ok, Err>  = Result.Result<Ok, Err>;

  type Ref<T>                  = Ref.Ref<T>;
  type WRef<T>                 = WRef.WRef<T>;
  type WMap<K, V>              = WMap.WMap<K, V>;
  type Map<K, V>               = Map.Map<K, V>;
  type Principal               = Principal.Principal;
  type Key<K>                  = Trie.Key<K>;
  func key(p: Principal) : Key<Principal> { { hash = Principal.hash(p); key = p; } };

  type ITokenInterface         = Types.ITokenInterface;
  type Subaccount              = Types.Subaccount;
  type Balance                 = Types.Balance;
  type TransferFromMasterError = Types.TransferFromMasterError;
  type ReapAccountError        = Types.ReapAccountError;
  type SubaccountPrefix        = Types.SubaccountPrefix;
  type TransactionsRecord      = Types.TransactionsRecord;
  type MintResult              = Types.MintResult;
  type PayoutArgs              = Types.PayoutArgs;
  type ReapAccountReceiver     = Types.ReapAccountReceiver;
  type ReapAccountResult       = Types.ReapAccountResult;
  type TransactionsRecords     = TransactionsRecords.TransactionsRecords;
  
  type Id = Nat;

  // \note: Use the ITokenInterface to not link with the actual TokenInterface which uses
  // the canister:godwin_token. This is required to be able to build the tests.
  public func build(
    token_interface: ITokenInterface,
    subaccount_prefix: SubaccountPrefix,
    lock_register: Map<Id, (Principal, Subaccount)>,
    subaccount_index: Ref<Nat>,
    user_transactions: Map<Principal, Map<Id, TransactionsRecord>>
  ) : PayForNew {
    PayForNew(
      token_interface,
      subaccount_prefix,
      WMap.WMap(lock_register, Map.nhash),
      WRef.WRef(subaccount_index),
      TransactionsRecords.TransactionsRecords(user_transactions)
    );
  };

  public class PayForNew(
    _token_interface: ITokenInterface,
    _subaccount_prefix: SubaccountPrefix,
    _lock_register: WMap<Id, (Principal, Subaccount)>,
    _subaccount_index: WRef<Nat>,
    _user_transactions: TransactionsRecords
  ){

    public func payin(buyer: Principal, price: Balance, create_new: () -> Id) : async* Result<Id, TransferFromMasterError>{
      let subaccount = getNextSubaccount();
      switch(await _token_interface.transferFromMaster(buyer, subaccount, price)) {
        case (#err(err)) { #err(err); };
        case (#ok(tx_index)) {
          let id = create_new();
          _lock_register.set(id, (buyer, subaccount));
          _user_transactions.initWithPayin(buyer, id, tx_index);
          return #ok(id);
        };
      };
    };

    public func payout(id: Id, args: PayoutArgs) : async* () {
      let (to, subaccount) = switch(_lock_register.getOpt(id)){
        case(null) { Debug.trap("Refund aborted (elem '" # Nat.toText(id) # "'') : not found in the map"); };
        case(?v) { v; };
      };
      let reap_result = await _token_interface.reapSubaccount(subaccount, Array.vals<ReapAccountReceiver>([{to; share = args.refund_share;}]));
      let refund = Option.chain(Trie.get(reap_result, key(to), Principal.equal), func(res: ?ReapAccountResult) : ?ReapAccountResult { res; });
      let reward = switch(args.reward_tokens){
        case(?amount) { ?(await _token_interface.mint(to, amount)); };
        case(null) { null; };
      };
      _user_transactions.setPayout(to, id, refund, reward);
      _lock_register.delete(id);
    };

    public func findTransactionsRecord(principal: Principal, id: Id) : ?TransactionsRecord {
      _user_transactions.find(principal, id);
    };

    func getNextSubaccount() : Subaccount {
      let subaccount = SubaccountGenerator.getSubaccount(_subaccount_prefix, _subaccount_index.get());
      _subaccount_index.set(_subaccount_index.get() + 1);
      subaccount;
    };
  
  };

 
};