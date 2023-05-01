import Types     "Types";

import Godwin    "../godwin_backend/main";
import SubTypes  "../godwin_backend/model/Types";
import TextUtils "../godwin_backend/utils/Text"; // @todo

import Map       "mo:map/Map";
import Set       "mo:map/Set";

import Scenario  "../../test/motoko/Scenario"; // @todo

import Result    "mo:base/Result";
import Principal "mo:base/Principal";
import Time      "mo:base/Time";
import Nat64     "mo:base/Nat64";
import Int       "mo:base/Int";
import Nat       "mo:base/Nat";
import Iter      "mo:base/Iter";
import Array     "mo:base/Array";
import Debug     "mo:base/Debug";
import Prim      "mo:prim";
import Nat32     "mo:base/Nat32";
import Option    "mo:base/Option";

import Token     "canister:godwin_token";

actor Master {

  type Parameters                     = SubTypes.Parameters;
  type Result<Ok, Err>                = Result.Result<Ok, Err>;
  type Map<K, V>                      = Map.Map<K, V>;
  type Godwin                         = Godwin.Godwin;
  type Balance                        = Types.Balance;
  type CreateSubGodwinResult          = Types.CreateSubGodwinResult;
  type TransferResult                 = Types.TransferResult;
  type AirdropResult                  = Types.AirdropResult;
  type MintBatchResult                = Types.MintBatchResult;
  let { toSubaccount; toBaseResult; } = Types;

  let pthash: Map.HashUtils<(Principal, Text)> = (
    // +% is the same as addWrap, meaning it wraps on overflow
    func(key: (Principal, Text)) : Nat32 = (Prim.hashBlob(Prim.blobOfPrincipal(key.0)) +% Prim.hashBlob(Prim.encodeUtf8(key.1))) & 0x3fffffff, // @todo: remove cast to Nat with map v8.0.0
    func(a: (Principal, Text), b: (Principal, Text)) : Bool = a.0 == b.0 and a.1 == b.1,
    func() = (Principal.fromText("aaaaa-aa"), "")
  );

  stable let _sub_godwins = Map.new<(Principal, Text), Godwin>(pthash);

  stable let _airdropped_users = Set.new<Principal>(Map.phash);

  stable let _user_names = Map.new<Principal, Text>(Map.phash);

  stable var _airdrop_supply = 1_000_000_000;

  stable let _airdrop_user_amount = 1_000_000;

  public shared func createSubGodwin(identifier: Text, parameters: Parameters) : async CreateSubGodwinResult  {
    
    // The identifier shall be alphanumeric because it will be used in the url.
    if (not TextUtils.isAlphaNumeric(identifier)){
      return #err(#InvalidIdentifier);
    };

    if (Option.isSome(Map.find(_sub_godwins, func(key: (Principal, Text), value: Godwin) : Bool { key.1 == identifier; }))){
      return #err(#IdentifierAlreadyTaken);
    };

    let new_sub = await (system Godwin.Godwin)(#new {settings = ?{ 
      controllers = null; // @todo: verify the sub godwin controller is the master
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = null;
    }})(parameters);

    let principal = Principal.fromActor(new_sub);

    Map.set(_sub_godwins, pthash, (principal, identifier), new_sub);

    #ok(principal);
  };

  // @todo: deal with the parameters
  // @todo: what happens if there is a breaking change ?
  public shared func updateSubGodwins(parameters: Parameters) : async () {
    for (sub in Map.vals(_sub_godwins)){
      let updated_sub = await (system Godwin.Godwin)(#upgrade(sub))(parameters);
    };
  };

  public query func listSubGodwins() : async [(Principal, Text)] {
    Iter.toArray(Map.keys(_sub_godwins));
  };

  // @todo: remove
  public shared func runScenario() : async () {
    let time_now = Nat64.fromNat(Int.abs(Time.now()));

    Debug.print("Run scenario!");

    for (principal in Array.vals(Scenario.getPrincipals())){

      Debug.print("Loop for principal: " # Principal.toText(principal));
       
       let mint_result = toBaseResult(await Token.mint({
        to = {
          owner = Principal.fromActor(Master);
          subaccount = ?toSubaccount(principal);
        };
        amount = _airdrop_user_amount;
        memo = null;
        created_at_time = ?time_now;
      }));

      switch(mint_result){
        case(#err(err)) { Debug.print(Types.transferErrorToText(err)); };
        case(#ok(tx_index)) { ignore Set.put(_airdropped_users, Map.phash, principal); };
      };
    };
  };

  public shared({caller}) func airdrop() : async AirdropResult {
    
    if (_airdrop_supply == 0) {
      return #err(#AirdropOver);
    };

    if (Set.has(_airdropped_users, Map.phash, caller)) {
      return #err(#AlreadySupplied);
    };

    let mint_result = toBaseResult(await Token.mint({
      to = {
        owner = Principal.fromActor(Master);
        subaccount = ?toSubaccount(caller);
      };
      amount = _airdrop_user_amount;
      memo = null;
      created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
    }));

    Result.iterate(mint_result, func(tx_index: Token.TxIndex){
      ignore Set.put(_airdropped_users, Map.phash, caller);
    });

    mint_result;
  };

  public shared({caller}) func pullTokens(user: Principal, amount: Balance, subaccount: ?Blob) : async TransferResult {

    if(Option.isNull(Map.find(_sub_godwins, func(key: (Principal, Text), value: Godwin) : Bool { key.0 == caller; }))){
      return #err(#NotAllowed);
    };

    toBaseResult(
      await Token.icrc1_transfer({
        amount;
        created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        fee = ?666; // @todo: null is supposed to work according to the Token standard, but it doesn't...
        from_subaccount = ?toSubaccount(user);
        memo = null;
        to = {
          owner = caller;
          subaccount;
        };
      })
    );
  };

  public shared({caller}) func mintBatch(args: Token.MintBatchArgs) : async MintBatchResult {

    if(Option.isNull(Map.find(_sub_godwins, func(key: (Principal, Text), value: Godwin) : Bool { key.0 == caller; }))){
      return #err(#NotAllowed);
    };

    toBaseResult(await Token.mint_batch(args));
  };

  public query func getAirdropSupply() : async Balance {
    _airdrop_supply;
  };

  public query func getUserAccount(user: Principal) : async Token.Account {
    { owner = Principal.fromActor(Master); subaccount = ?toSubaccount(user) };
  };

  public query func getUserName(user: Principal) : async ?Text {
    Map.get(_user_names, Map.phash, user);
  };

  public shared({caller}) func setUserName(name: Text) : async () {
    Map.set(_user_names, Map.phash, caller, name);
  };

};