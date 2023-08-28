import Types              "Types";
import Migrations         "stable/Migrations";
import Factory            "Factory";
import Controller         "Controller";

// Sub types import master types, so we need to import them here to avoid circular dependencies
import SubTypes           "../godwin_sub/model/Types";

import Result             "mo:base/Result";
import Principal          "mo:base/Principal";
import Time               "mo:base/Time";
import Debug              "mo:base/Debug";

import GodwinToken        "canister:godwin_token";

shared actor class GodwinMaster(args: Types.MigrationArgs) : async Types.MasterInterface = this {

  type Result<Ok, Err>        = Result.Result<Ok, Err>;

  type CategoryArray          = SubTypes.CategoryArray;
  type SubParameters          = SubTypes.SubParameters;
  type SubMigrationArgs       = Types.SubMigrationArgs;
  type Balance                = Types.Balance;
  type Duration               = Types.Duration;
  type CyclesParameters       = Types.CyclesParameters;
  type BasePriceParameters    = Types.BasePriceParameters;
  type ValidationParams       = Types.ValidationParams;
  type CreateSubGodwinResult  = Types.CreateSubGodwinResult;
  type TransferResult         = Types.TransferResult;
  type UpgradeAllSubsResult   = Types.UpgradeAllSubsResult;
  type MintBatchResult        = Types.MintBatchResult;
  type RemoveSubResult        = Types.RemoveSubResult;
  type CreateSubGodwinError   = Types.CreateSubGodwinError;
  type SetUserNameError       = Types.SetUserNameError;
  type AccessControlError     = Types.AccessControlError;
  type Controller             = Controller.Controller;

  stable var _state = Migrations.install(Time.now(), args);

  _state := Migrations.migrate(_state, Time.now(), args);

  // In subsequent versions, the controller will be set to null if the version of the state is not the last one
  let _controller = switch(_state){
    case(#v0_1_0(state)) { ?Factory.build(state); };
  };

  public shared query func getAdmin() : async Principal {
    getController().getAdmin();
  };

  public shared({caller}) func setAdmin(admin: Principal) : async Result<(), AccessControlError> {
    getController().setAdmin(caller, admin);
  };

  public shared query func getCyclesParameters() : async CyclesParameters {
    getController().getCyclesParameters();
  };

  public shared({caller}) func setCyclesParameters(cycles_parameters: CyclesParameters) : async Result<(), AccessControlError> {
    getController().setCyclesParameters(caller, cycles_parameters);
  };

  public query func getSubCreationPriceE8s() : async Balance {
    getController().getSubCreationPriceE8s();
  };

  public shared({caller}) func setSubCreationPriceE8s(sub_creation_price_e8s: Balance) : async Result<(), AccessControlError> {
    getController().setSubCreationPriceE8s(caller, sub_creation_price_e8s);
  };

  public shared query func getBasePriceParameters() : async BasePriceParameters {
    getController().getBasePriceParameters();
  };

  public shared({caller}) func setBasePriceParameters(base_price_parameters: BasePriceParameters) : async Result<(), AccessControlError> {
    await getController().setBasePriceParameters(caller, base_price_parameters);
  };

  public shared query func getSubValidationParams() : async ValidationParams {
    getController().getSubValidationParams();
  };

  public shared({caller}) func setSubValidationParams(params: ValidationParams) : async Result<(), AccessControlError> {
    getController().setSubValidationParams(caller, params);
  };
  
  public query func getCyclesBalance() : async Nat {
    getController().getCyclesBalance();
  };

  public shared({caller}) func createSubGodwin(identifier: Text, sub_parameters: SubParameters) : async CreateSubGodwinResult  {
    await getController().createSubGodwin({ master = Principal.fromActor(this); user = caller; }, identifier, sub_parameters, Time.now());
  };

  public shared({caller}) func upgradeAllSubs(args: SubMigrationArgs) : async UpgradeAllSubsResult {
    await getController().upgradeAllSubs(caller, args);
  };

  public shared({caller}) func removeSub(identifier: Text) : async RemoveSubResult {
    getController().removeSub(caller, identifier);
  };

  public query func listSubGodwins() : async [(Principal, Text)] {
    getController().listSubGodwins();
  };

  public shared({caller}) func pullTokens(user: Principal, amount: Balance, subaccount: ?Blob) : async TransferResult {
    await getController().pullTokens(caller, user, amount, subaccount, Time.now());
  };

  public shared({caller}) func mintBatch(args: GodwinToken.MintBatchArgs) : async MintBatchResult {
    await getController().mintBatch(caller, args);
  };

  public shared({caller}) func mint(args: GodwinToken.Mint) : async TransferResult {
    await getController().mint(caller, args);
  };

  public query func getUserAccount(user: Principal) : async GodwinToken.Account {
    getController().getUserAccount({ master = Principal.fromActor(this); user;});
  };

  public query func getUserName(user: Principal) : async ?Text {
    getController().getUserName(user);
  };

  public shared({caller}) func setUserName(name: Text) : async Result<(), SetUserNameError> {
    getController().setUserName(caller, name);
  };

  public query func validateSubIdentifier(identifier: Text) : async Result<(), CreateSubGodwinError> {
    getController().validateSubIdentifier(identifier: Text);
  };

  public query func validateSubName(name: Text) : async Result<(), CreateSubGodwinError> {
    getController().validateSubName(name: Text);
  };

  public query func validateCategories(categories: CategoryArray) : async Result<(), CreateSubGodwinError> {
    getController().validateCategories(categories: CategoryArray);
  };

  public query func validateSchedulerDuration(duration: Duration) : async Result<(), CreateSubGodwinError> {
    getController().validateSchedulerDuration(duration: Duration);
  };

  public query func validateConvictionDuration(duration: Duration) : async Result<(), CreateSubGodwinError> {
    getController().validateConvictionDuration(duration: Duration);
  };

  public query func validateCharacterLimit(character_limit: Nat) : async Result<(), CreateSubGodwinError> {
    getController().validateCharacterLimit(character_limit: Nat);
  };

  public query func validateMinimumInterestScore(minimum_interest_score: Float) : async Result<(), CreateSubGodwinError> {
    getController().validateMinimumInterestScore(minimum_interest_score: Float);
  };

  public query func validateUserName(principal: Principal, name: Text) : async Result<(), SetUserNameError> {
    getController().validateUserName(principal: Principal, name: Text);
  };

  func getController() : Controller {
    switch(_controller){
      case (?c) { c; };
      case (null) { Debug.trap("Controller is null"); };
    };
  };

};