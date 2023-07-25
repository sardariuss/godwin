import Types              "Types";
import Validator          "Validator";

import GodwinSub          "../godwin_sub/main";
import SubTypes           "../godwin_sub/model/Types";
import UtilsTypes         "../godwin_sub/utils/Types";
import Account            "../godwin_sub/utils/Account";

import Map                "mo:map/Map";
import Set                "mo:map/Set";

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

shared({caller = _controller}) actor class GodwinMaster() : async Types.MasterInterface = this {

  type Result<Ok, Err>       = Result.Result<Ok, Err>;
  type Map<K, V>             = Map.Map<K, V>;
  type Set<K>                = Set.Set<K>;

  type CategoryArray         = SubTypes.CategoryArray;
  type SchedulerParameters   = SubTypes.SchedulerParameters;
  type ConvictionsParameters = SubTypes.ConvictionsParameters;
  type SubParameters         = SubTypes.SubParameters;
  type Balance               = Types.Balance;
  type CreateSubGodwinResult = Types.CreateSubGodwinResult;
  type TransferResult        = Types.TransferResult;
  type MintBatchResult       = Types.MintBatchResult;
  type CreateSubGodwinError  = Types.CreateSubGodwinError;
  type AddGodwinSubError     = Types.AddGodwinSubError;
  type SetUserNameError      = Types.SetUserNameError;
  type Duration              = UtilsTypes.Duration;
  type GodwinSub             = GodwinSub.GodwinSub;

  let { toBaseResult; } = Types;

  let pthash: Map.HashUtils<(Principal, Text)> = (
    // +% is the same as addWrap, meaning it wraps on overflow
    func(key: (Principal, Text)) : Nat32 = (Prim.hashBlob(Prim.blobOfPrincipal(key.0)) +% Prim.hashBlob(Prim.encodeUtf8(key.1))) & 0x3fffffff,
    func(a: (Principal, Text), b: (Principal, Text)) : Bool = a.0 == b.0 and a.1 == b.1,
    func() = (Principal.fromText("2vxsx-fae"), "")
  );

  // @todo: keeping the actor as value seems useless
  stable let _sub_godwins = Map.new<(Principal, Text), GodwinSub>(pthash);

  stable let _user_names = Map.new<Principal, Text>(Map.phash);

  stable let _validation_params = {
    username = {
      min_length = 3;
      max_length = 32;
    };
    subgodwin = {
      scheduler_params = {
        minimum_duration = #MINUTES(10);
        maximum_duration = #YEARS(1);
      };
      convictions_params = {
        minimum_duration = #DAYS(1);
        maximum_duration = #YEARS(100);
      };
      question_char_limit = {
        maximum = 4000;
      };
      minimum_interest_score = {
        minimum = 1.0;
      };
    };
  };

  let _validator = Validator.Validator(_validation_params);

  public query func getCyclesBalance() : async Nat {
    ExperimentalCycles.balance();
  };

  public shared({caller}) func createSubGodwin(identifier: Text, sub_parameters: SubParameters) : async CreateSubGodwinResult  {

    switch(_validator.validateSubGodwinParams(identifier, sub_parameters, Set.fromIter(Map.keys(_sub_godwins), pthash))){
      case(#err(err)) { return #err(err); };
      case(#ok()) {};
    };

    // @todo
    let price_parameters = {
      open_vote_price_e8s           = 1_000_000_000;
      interest_vote_price_e8s       = 100_000_000;
      categorization_vote_price_e8s = 300_000_000;
    };
  
    // Add 50B cycles; creating the canister seem to take 8B, installation 6B.
    // @todo: probably want to be more conservative in prod
    ExperimentalCycles.add(50_000_000_000);

    let new_sub = await (system GodwinSub.GodwinSub)(#new {settings = ?{ 
      controllers = ?[Principal.fromActor(this), _controller];
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = null;
    }})(#init({ master = Principal.fromActor(this); sub_parameters; price_parameters; }));

    let principal = Principal.fromActor(new_sub);

    Map.set(_sub_godwins, pthash, (principal, identifier), new_sub);

    #ok(principal);
  };

  // In anticipation of next versions
  public shared func upgradeSubGodwins() : async () {
    for (sub in Map.vals(_sub_godwins)){
      let updated_sub = await (system GodwinSub.GodwinSub)(#upgrade(sub))(#upgrade({}));
    };
  };

  // In anticipation of next versions
  public shared func downgradeSubGodwins() : async () {
    for (sub in Map.vals(_sub_godwins)){
      let updated_sub = await (system GodwinSub.GodwinSub)(#upgrade(sub))(#downgrade({}));
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
        from_subaccount = ?Account.toSubaccount(user);
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

  public shared({caller}) func mint(args: GodwinToken.Mint) : async TransferResult {

    if(Option.isNull(Map.find(_sub_godwins, func(key: (Principal, Text), value: GodwinSub) : Bool { key.0 == caller; }))){
      return #err(#NotAllowed);
    };

    toBaseResult(await GodwinToken.mint(args));
  };

  public query func getUserAccount(user: Principal) : async GodwinToken.Account {
    { owner = Principal.fromActor(this); subaccount = ?Account.toSubaccount(user) };
  };

  public query func getUserName(user: Principal) : async ?Text {
    Map.get(_user_names, Map.phash, user);
  };

  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    Result.mapOk<(), (), SetUserNameError>(_validator.validateUserName(caller, name, _user_names), func() {
      Map.set(_user_names, Map.phash, caller, name);
    });
  };

  // Validation functions

  public query func validateSubIdentifier(identifier: Text) : async Result<(), CreateSubGodwinError> {
    _validator.validateSubIdentifier(identifier, Set.fromIter(Map.keys(_sub_godwins), pthash));
  };

  public query func validateSubName(name: Text) : async Result<(), CreateSubGodwinError> {
    _validator.validateSubName(name);
  };

  public query func validateCategories(categories: CategoryArray) : async Result<(), CreateSubGodwinError> {
    _validator.validateCategories(categories);
  };

  public query func validateSchedulerDuration(duration: Duration) : async Result<(), CreateSubGodwinError> {
    _validator.validateSchedulerDuration(duration);
  };

  public query func validateConvictionDuration(duration: Duration) : async Result<(), CreateSubGodwinError> {
    _validator.validateConvictionDuration(duration);
  };

  public query func validateCharacterLimit(character_limit: Nat) : async Result<(), CreateSubGodwinError> {
    _validator.validateCharacterLimit(character_limit);
  };

  public query func validateMinimumInterestScore(minimum_interest_score: Float) : async Result<(), CreateSubGodwinError> {
    _validator.validateMinimumInterestScore(minimum_interest_score);
  };

  public query({caller}) func validateUserName(name: Text) : async Result<(), SetUserNameError> {
    _validator.validateUserName(caller, name, _user_names);
  };

};