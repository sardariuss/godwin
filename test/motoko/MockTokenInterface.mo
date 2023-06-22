import Types  "../../src/godwin_sub/model/token/Types";

import Result    "mo:base/Result";
import Principal "mo:base/Principal";
import Buffer    "mo:base/Buffer";
import Trie      "mo:base/Trie";

module {

  type Result<Ok, Err>                = Result.Result<Ok, Err>;
  type Buffer<T>                      = Buffer.Buffer<T>;
  type Trie<K, V>                     = Trie.Trie<K, V>;
  type Key<K>                         = Trie.Key<K>;
  type Principal                      = Principal.Principal;
  func key(p: Principal) : Key<Principal> { { hash = Principal.hash(p); key = p; } };

  type Subaccount                     = Types.Subaccount;
  type Balance                        = Types.Balance;
  type TransferFromMasterResult       = Types.TransferFromMasterResult;
  type TransferToMasterResult         = Types.TransferToMasterResult;
  type ReapAccountRecipient           = Types.ReapAccountRecipient;
  type ReapAccountResult              = Types.ReapAccountResult;
  type MintRecipient                  = Types.MintRecipient;
  type MintResult                     = Types.MintResult;
  type TxIndex                        = Types.TxIndex;

  public class MockTokenInterface() {

    var _tx : TxIndex = 0;

    public func transferFromMaster(from: Principal, to_subaccount: Blob, amount: Balance) : async* TransferFromMasterResult {
      #ok(getNextTx());
    };

    public func transferToMaster(from_subaccount: Blob, to: Principal, amount: Balance) : async* TransferToMasterResult {
      #ok(getNextTx());
    };
    
    public func reapSubaccount(subaccount: Blob, recipients: Buffer<ReapAccountRecipient>) : async* Trie<Principal, ReapAccountResult> {
      var results : Trie<Principal, ReapAccountResult> = Trie.empty();
      for ({ to; share; }  in recipients.vals()){
        results := Trie.put(results, key(to), Principal.equal, #ok(getNextTx())).0;
      };
      results;
    };

    public func mintBatch(recipients: Buffer<MintRecipient>) : async* Trie<Principal, MintResult> {
      var results : Trie<Principal, MintResult> = Trie.empty();
      for ({ to; amount; } in recipients.vals()){
        results := Trie.put(results, key(to), Principal.equal, #ok(getNextTx())).0;
      };
      results;
    };

    func getNextTx() : TxIndex {
      _tx := _tx + 1;
      _tx;
    };

  };
 
};