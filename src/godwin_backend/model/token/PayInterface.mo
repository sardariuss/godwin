import Types "Types";

import Token "canister:godwin_token";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Error "mo:base/Error";
import Array "mo:base/Array";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Buffer<T>       = Buffer.Buffer<T>;

  let { toSubaccount; toBaseResult; } = Types;
  type MasterInterface                = Types.MasterInterface;
  type Subaccount                     = Types.Subaccount;
  type Balance                        = Types.Balance;
  type Account                        = Types.Account;
  type TxIndex                        = Types.TxIndex;
  type CanisterCallError              = Types.CanisterCallError;
  type PayInError                     = Types.PayInError;
  type PayInResult                    = Types.PayInResult;
  type PayoutRecipient                = Types.PayoutRecipient;
  type PayoutArgs                     = Types.PayoutArgs;
  type SinglePayoutInfo               = Types.SinglePayoutInfo;
  type PayoutError                    = Types.PayoutError;
  type PayOutResult                   = Types.PayOutResult;
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

    public func payIn(subaccount: Blob, from: Principal, amount: Balance) : async* PayInResult {
      try {
        await _master.pullTokens(from, amount, ?subaccount);
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
      };
    };

    public func payOut(subaccount: Blob, recipients: Buffer<PayoutRecipient>) : async* PayOutResult {
      // Convert each recipient's principal to the corresponding godwin_master's subaccount
      let to = Buffer.map<PayoutRecipient, Token.ReapAccountRecipient>(recipients, func(recipient: PayoutRecipient) : Token.ReapAccountRecipient {
        { account = getMasterAccount(?recipient.to); share = recipient.share; };
      });
      try {
        // Call the token reap_account method
        switch(await Token.reap_account({ subaccount = ?subaccount; to = Buffer.toArray(to); memo = null; })){ // @todo: memo
          case(#Ok(payout_info)){
            // If a single payout failed, return a batch error with all the payouts
            for (single_payout in Array.vals(payout_info)){
              switch(single_payout.1){
                case(#Err(_)){ return #err(#BatchError(payout_info)); };
                case(_) {};
              };
            };
            #ok;
          };
          case(#Err(err)) { #err(err); };
        };
      } catch(e) {
        #err(#CanisterCallError(Error.code(e)));
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