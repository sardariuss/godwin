import Types     "Types";

import Token     "canister:godwin_token";

import Map       "mo:map/Map";

import Result    "mo:base/Result";
import Principal "mo:base/Principal";
import Option    "mo:base/Option";
import Buffer    "mo:base/Buffer";
import Error     "mo:base/Error";
import Array     "mo:base/Array";
import Debug     "mo:base/Debug";

module {

  type Result<Ok, Err>                = Result.Result<Ok, Err>;
  type Buffer<T>                      = Buffer.Buffer<T>;
  type Map<K, V>                      = Map.Map<K, V>;

  let { toSubaccount; toBaseResult; } = Types;
  type MasterInterface                = Types.MasterInterface;
  type Subaccount                     = Types.Subaccount;
  type Balance                        = Types.Balance;
  type Account                        = Types.Account;
  type TxIndex                        = Types.TxIndex;
  type CanisterCallError              = Types.CanisterCallError;
  type TransferFromMasterResult       = Types.TransferFromMasterResult;
  type TransferToMasterResult         = Types.TransferToMasterResult;
  type ReapAccountRecipient           = Types.ReapAccountRecipient;
  type ReapAccountError               = Types.ReapAccountError;
  type ReapAccountResult              = Types.ReapAccountResult;
  type MintRecipient                  = Types.MintRecipient;
  type TransferArgs                   = Types.TransferArgs;
  type TransferResult                 = Types.TransferResult;
  type MintError                      = Types.MintError;
  type MintResult                     = Types.MintResult;
  type Mint                           = Types.Mint;

  public func build(principal: Principal) : PayInterface {
    let master : MasterInterface = actor(Principal.toText(principal));
    PayInterface(master);
  };

  public class PayInterface(_master: MasterInterface) {

    public func transferFromMaster(from: Principal, to_subaccount: Blob, amount: Balance) : async* TransferFromMasterResult {
      try {
        await _master.pullTokens(from, amount, ?to_subaccount);
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };

    public func transferToMaster(from_subaccount: Blob, to: Principal, amount: Balance) : async* TransferToMasterResult {
      try {
        // Call the token reap_account method
        toBaseResult(await Token.icrc1_transfer({
          from_subaccount = ?from_subaccount;
          to = getMasterAccount(?to);
          amount;
          fee = null;
          created_at_time = null;
          memo = null; // @todo: memo
        }));
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };

    // @todo: double ReapAccountRecipient types is confusing
    public func reapSubaccount(subaccount: Blob, recipients: Buffer<ReapAccountRecipient>, results: Map<Principal, ReapAccountResult>) : async* () {

      Map.clear(results);

      let map_recipients = Map.new<Subaccount, Principal>(Map.bhash);
      let to_accounts = Buffer.Buffer<Token.ReapAccountRecipient>(recipients.size());

      for ({ to; share; }  in recipients.vals()){
        // Add to the recipients 
        to_accounts.add({ account = getMasterAccount(?to); share; });
        // Keep the mapping of subaccount <-> principal
        Map.set(map_recipients, Map.bhash, toSubaccount(to), to);
        // Initialize the results map in case no error is found
        Map.set(results, Map.phash, to, #err(#SingleReapLost({ share; subgodwin_subaccount = subaccount; })));
      };

      let reap_result = try {
        // Call the token reap_account method
        await Token.reap_account({
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
            Map.set(results, Map.phash, recipient.to, #err(err));
          };
        };
        case(#Ok(transfer_results)){
          for ((args, result) in Array.vals(transfer_results)){
            Option.iterate(transferToReapAccountResult(map_recipients, args, result), func(payout: (Principal, ReapAccountResult)){
              Map.set(results, Map.phash, payout.0, payout.1);
            });
          };
        };
      };
    };

    // @todo: double MintRecipient types is confusing
    public func mintBatch(recipients: Buffer<MintRecipient>, results: Map<Principal, MintResult>) : async* () {

      Map.clear(results);

      let map_recipients = Map.new<Subaccount, Principal>(Map.bhash);
      let to_accounts = Buffer.Buffer<Token.MintRecipient>(recipients.size());

      for ({ to; amount; } in recipients.vals()){
        // Add to the recipients 
        to_accounts.add({ account = getMasterAccount(?to); amount; });
        // Keep the mapping of subaccount <-> principal
        Map.set(map_recipients, Map.bhash, toSubaccount(to), to);
        // Initialize the results map in case no error is found
        Map.set(results, Map.phash, to, #err(#SingleMintLost({ amount; })));
      };

      let mint_batch = try {
        // Call the token reap_account method
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
            Map.set(results, Map.phash, recipient.to, #err(err));
          };
        };
        case(#ok(transfer_results)){
          for ((args, result) in Array.vals(transfer_results)){
            Option.iterate(transferToMintResult(map_recipients, args, result), func(mint: (Principal, MintResult)){
              Map.set(results, Map.phash, mint.0, mint.1);
            });
          };
        };
      };
    };

    func getMasterAccount(principal: ?Principal) : Account {
      { owner = Principal.fromActor(_master); subaccount = Option.map(principal, func(p: Principal) : Blob { toSubaccount(p); }); };
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