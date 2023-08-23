import Types       "Types";

import Account     "../../utils/Account";

import GodwinToken "canister:godwin_token";

import Map         "mo:map/Map";

import Result      "mo:base/Result";
import Principal   "mo:base/Principal";
import Option      "mo:base/Option";
import Buffer      "mo:base/Buffer";
import Error       "mo:base/Error";
import Array       "mo:base/Array";
import Debug       "mo:base/Debug";
import Trie        "mo:base/Trie";

module {

  type Result<Ok, Err>                = Result.Result<Ok, Err>;
  type Buffer<T>                      = Buffer.Buffer<T>;
  type Map<K, V>                      = Map.Map<K, V>;
  type Trie<K, V>                     = Trie.Trie<K, V>;
  type Key<K>                         = Trie.Key<K>;
  type Principal                      = Principal.Principal;
  func key(p: Principal) : Key<Principal> { { hash = Principal.hash(p); key = p; } };

  let { toBaseResult; } = Types;
  type MasterInterface                = Types.MasterInterface;
  type Subaccount                     = Types.Subaccount;
  type Balance                        = Types.Balance;
  type Account                        = Types.Account;
  type CanisterCallError              = Types.CanisterCallError;
  type TransferFromMasterResult       = Types.TransferFromMasterResult;
  type ReapAccountRecipient           = Types.ReapAccountRecipient;
  type ReapAccountResult              = Types.ReapAccountResult;
  type MintRecipient                  = Types.MintRecipient;
  type TransferArgs                   = Types.TransferArgs;
  type TransferResult                 = Types.TransferResult;
  type MintError                      = Types.MintError;
  type MintResult                     = Types.MintResult;
  type Mint                           = Types.Mint;
  type ITokenInterface                = Types.ITokenInterface;

  public func build(principal: Principal) : TokenInterface {
    let master : MasterInterface = actor(Principal.toText(principal));
    TokenInterface(master);
  };

  public class TokenInterface(_master: MasterInterface) : ITokenInterface {

    public func transferFromMaster(from: Principal, to_subaccount: Blob, amount: Balance) : async* TransferFromMasterResult {
      try {
        await _master.pullTokens(from, amount, ?to_subaccount);
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };
    
    // @todo: double ReapAccountRecipient types is confusing
    public func reapSubaccount(subaccount: Blob, recipients: Buffer<ReapAccountRecipient>) : async* Trie<Principal, ?ReapAccountResult> {

      var results : Trie<Principal, ?ReapAccountResult> = Trie.empty();

      let map_recipients = Map.new<Subaccount, Principal>(Map.bhash);
      let to_accounts = Buffer.Buffer<GodwinToken.ReapAccountRecipient>(recipients.size());

      for ({ to; share; }  in recipients.vals()){
        if (share > 0.0) {
          // Add to the recipients 
          to_accounts.add({ account = getMasterAccount(?to); share; });
          // Keep the mapping of subaccount <-> principal
          Map.set(map_recipients, Map.bhash, Account.toSubaccount(to), to);
          // Initialize the results map in case no error is found
          results := Trie.put(results, key(to), Principal.equal, ?#err(#SingleReapLost({ share; subgodwin_subaccount = subaccount; }))).0;
        } else {
          results := Trie.put(results, key(to), Principal.equal, null).0;
        };
      };

      let reap_result = try {
        // Call the token reap_account method
        await GodwinToken.reap_account({
          subaccount = ?subaccount;
          to = Buffer.toArray(to_accounts);
          memo = null; // @todo: memo
        });
      } catch(e) {
        #Err(#CanisterCallError(Error.code(e)));
      };

      switch(reap_result) {
        case(#Err(err)) {    
          for (recipient in recipients.vals()){
            results := Trie.put(results, key(recipient.to), Principal.equal, ?#err(err)).0;
          };
        };
        case(#Ok(transfer_results)){
          for ((args, result) in Array.vals(transfer_results)){
            Option.iterate(transferToReapAccountResult(map_recipients, args, result), func((principal, result): (Principal, ReapAccountResult)){
              results := Trie.put(results, key(principal), Principal.equal, ?result).0;
            });
          };
        };
      };

      results;
    };

    // @todo: double MintRecipient types is confusing
    public func mintBatch(recipients: Buffer<MintRecipient>) : async* Trie<Principal, ?MintResult> {

      var results : Trie<Principal, ?MintResult> = Trie.empty();

      let map_recipients = Map.new<Subaccount, Principal>(Map.bhash);
      let to_accounts = Buffer.Buffer<GodwinToken.MintRecipient>(recipients.size());

      for ({ to; amount; } in recipients.vals()){
        if (amount > 0) {
        // Add to the recipients 
        to_accounts.add({ account = getMasterAccount(?to); amount; });
        // Keep the mapping of subaccount <-> principal
        Map.set(map_recipients, Map.bhash, Account.toSubaccount(to), to);
        // Initialize the results map in case no error is found
        results := Trie.put(results, key(to), Principal.equal, ?#err(#SingleMintLost({ amount; }))).0;
        } else {
          results := Trie.put(results, key(to), Principal.equal, null).0;
        };
      };

      let mint_batch = try {
        await _master.mintBatch({
          to = Buffer.toArray(to_accounts);
          memo = null; // @todo: memo
        });
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };

      switch(mint_batch) {
        case(#err(err)) {    
          for (recipient in recipients.vals()){
            results := Trie.put(results, key(recipient.to), Principal.equal, ?#err(err)).0;
          };
        };
        case(#ok(transfer_results)){
          for ((args, result) in Array.vals(transfer_results)){
            Option.iterate(transferToMintResult(map_recipients, args, result), func((principal, result): (Principal, MintResult)){
              results := Trie.put(results, key(principal), Principal.equal, ?result).0;
            });
          };
        };
      };

      results;
    };

    public func mint(to: Principal, amount: Balance) : async* MintResult {
      let args = {
        to = getMasterAccount(?to);
        amount;
        memo = null; // @todo: memo
        created_at_time = null;
      };
      
      let mint = try {
        await _master.mint(args);
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };

    func getMasterAccount(principal: ?Principal) : Account {
      { owner = Principal.fromActor(_master); subaccount = Option.map(principal, func(p: Principal) : Blob { Account.toSubaccount(p); }); };
    };

  };

  // @todo: in case the subaccount or the principal is ever null, the transfer will be lost
  func transferToReapAccountResult(map_recipients: Map<Subaccount, Principal>, args: TransferArgs, result: TransferResult) : ?(Principal, ReapAccountResult) {
    let opt_subaccount = args.to.subaccount;
    switch(opt_subaccount){
      case(null) { null; };
      case(?subaccount) {
        let opt_principal = Map.get(map_recipients, Map.bhash, subaccount);
        switch(opt_principal){
          case(null) { null; };
          case(?principal) {
            switch(result){
              case(#Ok(tx_index)) { ?(principal, #ok(tx_index));                                             };
              case(#Err(err))     { ?(principal, #err(#SingleTransferError({ args = args; error = err; }))); };
            };
          };
        };
      };
    };
  };

  // @todo: in case the subaccount or the principal is ever null, the transfer will be lost
  func transferToMintResult(map_recipients: Map<Subaccount, Principal>, args: Mint, result: TransferResult) : ?(Principal, MintResult) {
    let opt_subaccount = args.to.subaccount;
    switch(opt_subaccount){
      case(null) { null; };
      case(?subaccount) {
        let opt_principal = Map.get(map_recipients, Map.bhash, subaccount);
        switch(opt_principal){
          case(null) { null; };
          case(?principal) {
            switch(result){
              case(#Ok(tx_index)) { ?(principal, #ok(tx_index));                                         };
              case(#Err(err))     { ?(principal, #err(#SingleMintError({ args = args; error = err; }))); };
            };
          };
        };
      };
    };
  };
 
};