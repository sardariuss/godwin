import Types              "Types";

import GodwinSub          "../godwin_sub/main";
import SubTypes           "../godwin_sub/model/Types";
import TextUtils          "../godwin_sub/utils/Text";

import Map                "mo:map/Map";

import Result             "mo:base/Result";
import Principal          "mo:base/Principal";
import Time               "mo:base/Time";
import Nat64              "mo:base/Nat64";
import Int                "mo:base/Int";
import Iter               "mo:base/Iter";
import Prim               "mo:prim";
import Option             "mo:base/Option";
import ExperimentalCycles "mo:base/ExperimentalCycles";

import GodwinToken        "canister:godwin_token";

shared({caller = _controller}) actor class GodwinMaster() = this {

  type Parameters                     = SubTypes.Parameters;
  type Result<Ok, Err>                = Result.Result<Ok, Err>;
  type Map<K, V>                      = Map.Map<K, V>;
  type GodwinSub                      = GodwinSub.GodwinSub;
  type Balance                        = Types.Balance;
  type CreateSubGodwinResult          = Types.CreateSubGodwinResult;
  type TransferResult                 = Types.TransferResult;
  type MintBatchResult                = Types.MintBatchResult;
  type SetUserNameError               = Types.SetUserNameError;

  let MIN_USERNAME_LENGTH = 3;
  let MAX_USERNAME_LENGTH = 32;

  let { toSubaccount; toBaseResult; } = Types;

  let pthash: Map.HashUtils<(Principal, Text)> = (
    // +% is the same as addWrap, meaning it wraps on overflow
    func(key: (Principal, Text)) : Nat32 = (Prim.hashBlob(Prim.blobOfPrincipal(key.0)) +% Prim.hashBlob(Prim.encodeUtf8(key.1))) & 0x3fffffff,
    func(a: (Principal, Text), b: (Principal, Text)) : Bool = a.0 == b.0 and a.1 == b.1,
    func() = (Principal.fromText("2vxsx-fae"), "")
  );

  stable let _sub_godwins = Map.new<(Principal, Text), GodwinSub>(pthash);

  stable let _user_names = Map.new<Principal, Text>(Map.phash);

  public query func getCyclesBalance() : async Nat {
    ExperimentalCycles.balance();
  };

  public shared({caller}) func createSubGodwin(identifier: Text, parameters: Parameters) : async CreateSubGodwinResult  {
    
    // The identifier shall be alphanumeric because it will be used in the url.
    if (not TextUtils.isAlphaNumeric(identifier)){
      return #err(#InvalidIdentifier);
    };

    if (Option.isSome(Map.find(_sub_godwins, func(key: (Principal, Text), value: GodwinSub) : Bool { key.1 == identifier; }))){
      return #err(#IdentifierAlreadyTaken);
    };

    // Add 50B cycles; creating the canister seem to take 8B, installation 6B.
    // @todo: probably want to be more conservative in prod
    ExperimentalCycles.add(50_000_000_000);

    let new_sub = await (system GodwinSub.GodwinSub)(#new {settings = ?{ 
      controllers = ?[Principal.fromActor(this), _controller];
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = null;
    }})(parameters);

    let principal = Principal.fromActor(new_sub);

    Map.set(_sub_godwins, pthash, (principal, identifier), new_sub);

    #ok(principal);
  };

  type AddGodwinSubError = {
    #NotAuthorized;
    #AlreadyAdded;
  };

  // @todo: verify the names are unique
  public shared({caller}) func addGodwinSub(principal: Principal, identifier: Text) : async Result<(), AddGodwinSubError> {
    if (caller != _controller){
      return #err(#NotAuthorized);
    };
    if(Option.isSome(Map.find(_sub_godwins, func(key: (Principal, Text), value: GodwinSub) : Bool { key.0 == caller; }))){
      return #err(#AlreadyAdded);
    };
    let sub : GodwinSub = actor(Principal.toText(principal));
    Map.set(_sub_godwins, pthash, (principal, identifier), sub);
    #ok;
  };

  // @todo: deal with the parameters
  // @todo: what happens if there is a breaking change ?
  public shared func updateSubGodwins(parameters: Parameters) : async () {
    for (sub in Map.vals(_sub_godwins)){
      let updated_sub = await (system GodwinSub.GodwinSub)(#upgrade(sub))(parameters);
    };
  };

  public query func listSubGodwins() : async [(Principal, Text)] {
    Iter.toArray(Map.keys(_sub_godwins));
  };

  public shared({caller}) func pullTokens(user: Principal, amount: Balance, subaccount: ?Blob) : async TransferResult {

    if(Option.isNull(Map.find(_sub_godwins, func(key: (Principal, Text), value: GodwinSub) : Bool { key.0 == caller; }))){
      return #err(#NotAllowed);
    };

    toBaseResult(
      await GodwinToken.icrc1_transfer({
        amount;
        created_at_time = ?Nat64.fromNat(Int.abs(Time.now()));
        fee = ?10_000; // @todo: null is supposed to work according to the Token standard, but it doesn't...
        from_subaccount = ?toSubaccount(user);
        memo = null;
        to = {
          owner = caller;
          subaccount;
        };
      })
    );
  };

  public shared({caller}) func mintBatch(args: GodwinToken.MintBatchArgs) : async MintBatchResult {

    if(Option.isNull(Map.find(_sub_godwins, func(key: (Principal, Text), value: GodwinSub) : Bool { key.0 == caller; }))){
      return #err(#NotAllowed);
    };

    toBaseResult(await GodwinToken.mint_batch(args));
  };

  public query func getUserAccount(user: Principal) : async GodwinToken.Account {
    { owner = Principal.fromActor(this); subaccount = ?toSubaccount(user) };
  };

  public query func getUserName(user: Principal) : async ?Text {
    Map.get(_user_names, Map.phash, user);
  };

  // @todo: have a user name regexp (that e.g. does not allow only whitespaces, etc.)
  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    // Check if the principal is anonymous
    if (Principal.isAnonymous(caller)){
      return #err(#AnonymousNotAllowed);
    };
    // Check if not too short
    if (name.size() < MIN_USERNAME_LENGTH){
      return #err(#NameTooShort({ min_length = MIN_USERNAME_LENGTH; }));
    };
    // Check if not too long
    if (name.size() > MAX_USERNAME_LENGTH){
      return #err(#NameTooLong({ max_length = MAX_USERNAME_LENGTH; }));
    };
    // Check it this is the same name as before
    switch(Map.get(_user_names, Map.phash, caller)){
      case(?old_name) {
        if (old_name == name){
          return #ok;
        };
      };
      case(null){};
    };
    // Check if the name is already taken
    if (Map.some(_user_names, func(key: Principal, value: Text) : Bool { value == name; })){
      return #err(#NameAlreadyTaken);
    };
    Map.set(_user_names, Map.phash, caller, name);
    #ok;
  };

};