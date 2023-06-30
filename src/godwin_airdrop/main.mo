import TokenTypes   "../godwin_token/Types";
import MasterTypes  "../godwin_master/Types";

import Set          "mo:map/Set";

import Result       "mo:base/Result";
import Principal    "mo:base/Principal";
import Time         "mo:base/Time";
import Nat64        "mo:base/Nat64";
import Int          "mo:base/Int";

import GodwinToken  "canister:godwin_token";
import GodwinMaster "canister:godwin_master";

shared({caller = controller}) actor class GodwinAirdrop(
  amount_e8s_per_user: Nat,
  allow_self_airdrop: Bool
) = this {

  public type AuthorizationError = {
    #NotAuthorized;
  };

  public type AirdropError = TokenTypes.TransferError or AuthorizationError or {
    #AlreadySupplied;
    #AirdropOver;
  };

  public type AirdropResult = Result.Result<TokenTypes.TxIndex, AirdropError>;
  
  let { toSubaccount; toBaseResult; } = MasterTypes;

  stable var _controller          = controller;
  stable var _amount_e8s_per_user = amount_e8s_per_user;
  stable var _allow_self_airdrop  = allow_self_airdrop;
  stable let _airdropped_users    = Set.new<Principal>(Set.phash);

  public query func getController() : async Principal {
    _controller;
  };

  public shared({caller}) func setController(new_controller: Principal) : async Result.Result<(), AuthorizationError> {
    if (caller != _controller) {
      return #err(#NotAuthorized);
    };
    _controller := new_controller;
    #ok;
  };

  public query func getAmountPerUser() : async Nat {
    _amount_e8s_per_user;
  };

  public shared({caller}) func setAmountPerUser(new_amount: Nat) : async Result.Result<(), AuthorizationError> {
    if (caller != _controller) {
      return #err(#NotAuthorized);
    };
    _amount_e8s_per_user := new_amount;
    #ok;
  };

  public query func isSelfAirdropAllowed() : async Bool {
    _allow_self_airdrop;
  };

  public shared({caller}) func allowSelfAirdrop(new_allow: Bool) : async Result.Result<(), AuthorizationError> {
    if (caller != _controller) {
      return #err(#NotAuthorized);
    };
    _allow_self_airdrop := new_allow;
    #ok;
  };

  public shared func getRemainingSupply() : async TokenTypes.Balance {
    await GodwinToken.icrc1_balance_of({ owner = Principal.fromActor(this); subaccount = null; });
  };

  public shared({caller}) func airdropSelf() : async AirdropResult {
    if (not(_allow_self_airdrop)){
      return #err(#NotAuthorized);
    };
    await* airdrop(caller);
  };

  public shared({caller}) func airdropUser(user: Principal) : async AirdropResult {
    if (caller != _controller) {
      return #err(#NotAuthorized);
    };
    await* airdrop(user);
  };

  func airdrop(principal: Principal) : async* AirdropResult {

    if (Set.has(_airdropped_users, Set.phash, principal)) {
      return #err(#AlreadySupplied);
    };

    let transfer_result = toBaseResult(await GodwinToken.icrc1_transfer({
      to = {
        owner = Principal.fromActor(GodwinMaster);
        subaccount = ?toSubaccount(principal);
      };
      from_subaccount = null;
      amount = _amount_e8s_per_user;
      memo = null;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
      fee = ?10_000; // @todo: fix bug where null is not allowed
    }));

    Result.iterate(transfer_result, func(tx_index: GodwinToken.TxIndex){
      ignore Set.put(_airdropped_users, Set.phash, principal);
    });

    transfer_result;
  };

};