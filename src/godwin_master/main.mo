import Types              "Types";
import Validator          "Validator";

import GodwinSub          "../godwin_sub/main";
import SubTypes           "../godwin_sub/model/Types";
import UtilsTypes         "../godwin_sub/utils/Types";
import Account            "../godwin_sub/utils/Account";
import SubMigrationTypes  "../godwin_sub/stable/Types";

import Map                "mo:map/Map";
import Set                "mo:map/Set";

import Result             "mo:base/Result";
import Principal          "mo:base/Principal";
import Time               "mo:base/Time";
import Nat64              "mo:base/Nat64";
import Int                "mo:base/Int";
import Iter               "mo:base/Iter";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Buffer             "mo:base/Buffer";
import Error              "mo:base/Error";

import GodwinToken        "canister:godwin_token";

shared({caller = _admin}) actor class GodwinMaster() : async Types.MasterInterface = this {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Map<K, V>              = Map.Map<K, V>;

  type CategoryArray          = SubTypes.CategoryArray;
  type SubParameters          = SubTypes.SubParameters;
  type SubMigrationArgs       = SubMigrationTypes.Args;
  type Balance                = Types.Balance;
  type CreateSubGodwinResult  = Types.CreateSubGodwinResult;
  type TransferResult         = Types.TransferResult;
  type AccessControlRole      = Types.AccessControlRole;
  type AccessControlError     = Types.AccessControlError;
  type UpgradeAllSubsResult   = Types.UpgradeAllSubsResult;
  type SingleSubUpgradeResult = Types.SingleSubUpgradeResult;
  type MintBatchResult        = Types.MintBatchResult;
  type CreateSubGodwinError   = Types.CreateSubGodwinError;
  type SetUserNameError       = Types.SetUserNameError;
  type Duration               = UtilsTypes.Duration;
  type GodwinSub              = GodwinSub.GodwinSub;

  let { toBaseResult; } = Types;

  // Map<Sub, Identifier>
  stable let _sub_godwins = Map.new<Principal, Text>(Map.phash);

  stable let _user_names = Map.new<Principal, Text>(Map.phash);

  // @todo
  stable let _create_sub_cycles  = 50_000_000_000;
  stable let _upgrade_sub_cycles = 10_000_000_000;

  stable let _price_parameters = {
    open_vote_price_e8s           = 1_000_000_000;
    interest_vote_price_e8s       = 100_000_000;
    categorization_vote_price_e8s = 300_000_000;
  };

  stable let _validation_params = {
    username = {
      min_length = 3;
      max_length = 32;
    };
    subgodwin = {
      identifier = {
        min_length = 3;
        max_length = 32;
      };
      subname = {
        min_length = 3;
        max_length = 60;
      };
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

    switch(_validator.validateSubGodwinParams(identifier, sub_parameters, Set.fromIter(Map.vals(_sub_godwins), Map.thash))){
      case(#err(err)) { return #err(err); };
      case(#ok()) {};
    };
  
    ExperimentalCycles.add(_create_sub_cycles);

    let new_sub = await (system GodwinSub.GodwinSub)(#new {settings = ?{ 
      controllers = ?[Principal.fromActor(this), _admin];
      compute_allocation = null;
      memory_allocation = null;
      freezing_threshold = null;
    }})(#init({ master = Principal.fromActor(this); sub_parameters; price_parameters = _price_parameters; }));

    let principal = Principal.fromActor(new_sub);

    Map.set(_sub_godwins, Map.phash, principal, identifier);

    #ok(principal);
  };

  // In anticipation of next versions
  public shared({caller}) func upgradeAllSubs(args: SubMigrationArgs) : async UpgradeAllSubsResult {
    
    switch(verifyAuthorizedAccess(caller, #ADMIN)){
      case(#err(err)) { return #err(err); };
      case(#ok()) {};
    };

    let update_results = Buffer.Buffer<(Principal, SingleSubUpgradeResult)>(0);

    for (principal in Map.keys(_sub_godwins)){
      
      let sub : GodwinSub = actor(Principal.toText(principal));

      ExperimentalCycles.add(_upgrade_sub_cycles);
      
      let single_sub_result = try {
        ignore await (system GodwinSub.GodwinSub)(#upgrade(sub))(args);
        #ok;
      } catch(e) {
        #err({code = Error.code(e); message = Error.message(e); });
      };
      
      update_results.add((principal, single_sub_result));
    };

    #ok(Buffer.toArray(update_results));
  };

  public query func listSubGodwins() : async [(Principal, Text)] {
    Iter.toArray(Map.entries(_sub_godwins));
  };

  public shared({caller}) func pullTokens(user: Principal, amount: Balance, subaccount: ?Blob) : async TransferResult {

    switch(verifyAuthorizedAccess(caller, #SUB)){
      case(#err(err)) { return #err(err); };
      case(#ok()) {};
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

    switch(verifyAuthorizedAccess(caller, #SUB)){
      case(#err(err)) { return #err(err); };
      case(#ok()) {};
    };

    toBaseResult(await GodwinToken.mint_batch(args));
  };

  public shared({caller}) func mint(args: GodwinToken.Mint) : async TransferResult {

    switch(verifyAuthorizedAccess(caller, #SUB)){
      case(#err(err)) { return #err(err); };
      case(#ok()) {};
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
    _validator.validateSubIdentifier(identifier, Set.fromIter(Map.vals(_sub_godwins), Map.thash));
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

  private func verifyAuthorizedAccess(principal: Principal, required_role: AccessControlRole) : Result<(), AccessControlError> {
    switch(required_role){
      case(#ADMIN) { if(principal == _admin) { return #ok; }; };
      case(#SUB) {
        if(Map.has(_sub_godwins, Map.phash, principal)){
          return #ok;
        };
      };
    };
    #err(#AccessDenied({required_role;}));
  };

};