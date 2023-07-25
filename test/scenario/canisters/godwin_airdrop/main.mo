import TokenTypes   "../../../../src/godwin_token/Types";
import MasterTypes  "../../../../src/godwin_master/Types";
import Account      "../../../../src/godwin_sub/utils/Account";
import Scenario     "../../Scenario";

import Set          "mo:map/Set";

import Result       "mo:base/Result";
import Principal    "mo:base/Principal";
import Time         "mo:base/Time";
import Nat64        "mo:base/Nat64";
import Int          "mo:base/Int";
import Array        "mo:base/Array";
import Debug        "mo:base/Debug";
import Nat          "mo:base/Nat";

import GodwinToken  "canister:godwin_token";
import GodwinMaster "canister:godwin_master";

shared({caller = controller}) actor class GodwinAirdrop(
  amount_e8s_per_user: Nat,
  allow_self_airdrop: Bool
) {

  public type AuthorizationError = {
    #NotAuthorized;
  };

  public type AirdropError = TokenTypes.TransferError or AuthorizationError or {
    #AlreadySupplied;
    #AirdropOver;
  };

  public type AirdropResult = Result.Result<TokenTypes.TxIndex, AirdropError>;
  
  let { toBaseResult; transferErrorToText; } = MasterTypes;

  stable var _controller          = controller;
  stable var _amount_e8s_per_user = amount_e8s_per_user;
  stable var _allow_self_airdrop  = allow_self_airdrop;
  stable let _airdropped_users    = Set.new<Principal>(Set.phash);

  public shared func runScenario() : async () {
    Debug.print("Run scenario!");
    for (principal in Array.vals(Scenario.getPrincipals())){
      ignore await* airdrop(principal);
    };
  };

  func airdrop(principal: Principal) : async* AirdropResult {

    if (Set.has(_airdropped_users, Set.phash, principal)) {
      return #err(#AlreadySupplied);
    };

    let transfer_result = toBaseResult(await GodwinToken.icrc1_transfer({
      to = {
        owner = Principal.fromActor(GodwinMaster);
        subaccount = ?Account.toSubaccount(principal);
      };
      from_subaccount = null;
      amount = _amount_e8s_per_user;
      memo = null;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
      fee = ?10_000; // @todo: fix bug where null is not allowed
    }));

    switch(transfer_result){
      case(#err(err)) { Debug.print(transferErrorToText(err)); };
      case(#ok(tx_index)) { ignore Set.put(_airdropped_users, Set.phash, principal); };
    };

    transfer_result;
  };

};