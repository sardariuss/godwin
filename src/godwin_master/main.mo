import Godwin "../godwin_backend/main";
import Types "../godwin_backend/model/Types";

import Map "mo:map/Map";

import ICRC1 "mo:icrc1/ICRC1";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";

import Token "canister:godwin_token";

actor Master = {

  type Parameters = Types.Parameters;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Map<K, V> = Map.Map<K, V>;
  type Godwin = Godwin.Godwin;
  type Balance = ICRC1.Balance;

  stable let _sub_godwins = Map.new<Principal, Godwin>();

  public shared func createSubGodwin(parameters: Parameters) : async Principal {

    let new_sub = await (system Godwin.Godwin)(#new {settings = ?{ 
      controllers = null; // @todo: let's try that
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = null;
    }})(parameters);

    let principal = Principal.fromActor(new_sub);

    Map.set(_sub_godwins, Map.phash, principal, new_sub);

    principal;
  };

  // @todo: deal with the fucking parameters
  // @todo: what happens if there is a breaking change ?
  public shared func updateSubGodwins(parameters: Parameters) : async () {
    for (sub in Map.vals(_sub_godwins)){
      let updated_sub = await (system Godwin.Godwin)(#upgrade(sub))(parameters);
    };
  };

  public query func listSubGodwins() : async [Principal] {
    Iter.toArray(Map.keys(_sub_godwins));
  };

  type CredentialErrors = {
    #NotAllowed;
  };

  type TransferFromUserError = ICRC1.TransferError or CredentialErrors;

  public shared({caller}) func transferToSubGodwin(user: Principal, amount: Balance, subaccount: Blob) : async Result<(), TransferFromUserError> {

    let godwin_fee = 1_000;

    switch(Map.get(_sub_godwins, Map.phash, caller)){
      case null {
        #err(#NotAllowed);
      };
      case (?sub_godwin) {
        let transfer_result = await Token.icrc1_transfer({
          amount;
          created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
          fee = ?godwin_fee;
          from_subaccount = ?Principal.toBlob(user);
          memo = null;
          to = {
            owner = caller;
            subaccount = ?subaccount;
          };
        });
        switch(transfer_result){
          case(#Err(err)) {
            #err(err);
          };
          case(#Ok(_)) {
            #ok();
          };
        };
      };
    };
  };

};
