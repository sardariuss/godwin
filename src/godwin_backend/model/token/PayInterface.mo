import Types "Types";

import Token "canister:godwin_token";

import Map "mo:map/Map";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Array "mo:base/Array";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Buffer<T>       = Buffer.Buffer<T>;
  type Map<K, V>       = Map.Map<K, V>;

  let { toSubaccount; toBaseResult; } = Types;
  type MasterInterface                = Types.MasterInterface;
  type Subaccount                     = Types.Subaccount;
  type Balance                        = Types.Balance;
  type Account                        = Types.Account;
  type TxIndex                        = Types.TxIndex;
  type CanisterCallError              = Types.CanisterCallError;
  type PayinError                     = Types.PayinError;
  type PayinResult                    = Types.PayinResult;
  type SinglePayoutRecipient          = Types.SinglePayoutRecipient;
  type SinglePayoutError              = Types.SinglePayoutError;
  type SinglePayoutResult             = Types.SinglePayoutResult;
  type PayoutResult                   = Types.PayoutResult;
  type MintRecipient                  = Types.MintRecipient;
  type MintArgs                       = Types.MintArgs;
  type SingleMintInfo                 = Types.SingleMintInfo;
  type MintError                      = Types.MintError;
  type MintResult                     = Types.MintResult;

  public func build(principal: Principal) : PayInterface {
    let master : MasterInterface = actor(Principal.toText(principal));
    PayInterface(master);
  };

  public class PayInterface(_master: MasterInterface) {

    public func payin(subaccount: Blob, from: Principal, amount: Balance) : async* PayinResult {
      try {
        await _master.pullTokens(from, amount, ?subaccount);
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };

    public func payout(subaccount: Blob, to: Principal, amount: Nat) : async* PayoutResult {
      try {
        // Call the token reap_account method
        toBaseResult(await Token.icrc1_transfer({
          from_subaccount = ?subaccount;
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

    public func batchPayout(subaccount: Blob, recipients: Buffer<SinglePayoutRecipient>, results: Map<Principal, SinglePayoutResult>) : async* () {

      Map.clear(results);

      let map_recipients = Map.new<Subaccount, Principal>(Map.bhash);
      let to_accounts = Buffer.Buffer<Token.ReapAccountRecipient>(recipients.size());

      // 1. iterate over recipients
      for (recipient in recipients.vals()){
        // Add to the recipients 
        to_accounts.add({ account = getMasterAccount(?recipient.to); share = recipient.share; });
        // Keep the mapping of subaccount <-> principal
        Map.set(map_recipients, Map.bhash, toSubaccount(recipient.to), recipient.to);
        // Initialize the results map in case no error is found
        Map.set(results, Map.phash, recipient.to, #err(#SingleReapLost({ share = recipient.share; subgodwin_subaccount = subaccount; })));
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
            let opt_subaccount = args.to.subaccount;
            switch(opt_subaccount){
              case(null) {}; // @todo: add to payinterface errors ?
              case(?subaccount) {
                let opt_principal = Map.get(map_recipients, Map.bhash, subaccount);
                switch(opt_principal){
                  case(null) {}; // @todo: add to payinterface errors ?
                  case(?principal) {
                    switch(result){
                      case(#Ok(tx_index)) {
                        Map.set(results, Map.phash, principal, #ok(tx_index));
                      };
                      case(#Err(err)) {
                        Map.set(results, Map.phash, principal, #err(#SingleTransferError({ args = args; error = err; })));
                      };
                    };
                  };
                };
              };
            };
          }
        };
      };
    };

    public func mint(recipients: Buffer<MintRecipient>) : async* MintResult {
      // Convert each recipient's principal to the corresponding godwin_master's subaccount
      let to = Buffer.map<MintRecipient, Token.MintRecipient>(recipients, func(recipient: MintRecipient) : Token.MintRecipient {
        { account = getMasterAccount(?recipient.to); amount = recipient.amount; };
      });
      try {
        // Call the token reap_account method
        switch(await _master.mintBatch({ to = Buffer.toArray(to); memo = null; })){ // @todo: memo
          case(#ok(mint_info)){
            // If a single payout failed, return a batch error with all the payouts
            for (single_mint in Array.vals(mint_info)){
              switch(single_mint.1){
                case(#Err(_)){ return #err(#BatchError(mint_info)); };
                case(_) {};
              };
            };
            #ok;
          };
          case(#err(err)) { #err(err); };
        };
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };

    func getMasterAccount(principal: ?Principal) : Account {
      { owner = Principal.fromActor(_master); subaccount = Option.map(principal, func(p: Principal) : Blob { toSubaccount(p); }); };
    };

  };
 
};