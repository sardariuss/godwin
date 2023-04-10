import MasterTypes "../../../godwin_master/Types";

import Token "canister:godwin_token";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";

module {

  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type MasterInterface = MasterTypes.MasterInterface;
  type Buffer<T> = Buffer.Buffer<T>;

  let { toSubaccount } = MasterTypes;
  
  // Token general types
  public type Subaccount = Blob;
  public type Balance = Token.Balance;
  public type Account = Token.Account;
  // Payin types
  public type PayInError = MasterTypes.TransferError;
  public type PayInResult = MasterTypes.TransferResult;
  // Payout types
  public type PayoutRecipient = { to: Principal; share: Float; };
  public type PayoutError = Token.ReapAccountError;
  public type PayOutResult = Result<[Token.TransferResult], PayoutError>;
  // Mint types
  public type MintRecipients = [Token.MintRecipient];
  public type MintResult = MasterTypes.MintBatchResult;

  public func build(principal: Principal) : PayInterface {
    let master : MasterInterface = actor(Principal.toText(principal));
    PayInterface(master);
  };

  public class PayInterface(_master: MasterInterface) {

    public func payIn(subaccount: Blob, from: Principal, amount: Balance) : async* PayInResult {
      await _master.pullTokens(from, amount, ?subaccount)
    };

    public func payOut(subaccount: Blob, recipients: Buffer<PayoutRecipient>) : async* PayOutResult {

      let to = Buffer.map<PayoutRecipient, Token.ReapAccountRecipient>(recipients, func(recipient: PayoutRecipient) : Token.ReapAccountRecipient {
        { account = getMasterAccount(?recipient.to); share = recipient.share; };
      });

      switch(await Token.reap_account({ subaccount = ?subaccount; to = Buffer.toArray(to); memo = null; })){ // @todo: memo
        case(#Ok(result)) { #ok(result) };
        case(#Err(err))   { #err(err)   }; // @todo: shall be added to a history of errors
      };
    };

    public func mint(to: MintRecipients) : async* MintResult {
      await _master.mintBatch({ to; memo = null; }) // @todo: memo
    };

    public func getMasterAccount(principal: ?Principal) : Account {
      { owner = Principal.fromActor(_master); subaccount = Option.map(principal, func(p: Principal) : Blob { toSubaccount(p); }); };
    };

  };
 
};