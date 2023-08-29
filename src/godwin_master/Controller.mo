import Types              "Types";
import Model              "model/Model";

import GodwinSub          "../godwin_sub/main";
import SubTypes           "../godwin_sub/model/Types";
import UtilsTypes         "../godwin_sub/utils/Types";
import Account            "../godwin_sub/utils/Account";
import SubMigrationTypes  "../godwin_sub/stable/Types";

import Map                "mo:map/Map";
import Set                "mo:map/Set";

import Result             "mo:base/Result";
import Principal          "mo:base/Principal";
import Nat64              "mo:base/Nat64";
import Int                "mo:base/Int";
import Iter               "mo:base/Iter";
import ExperimentalCycles "mo:base/ExperimentalCycles";
import Buffer             "mo:base/Buffer";
import Error              "mo:base/Error";

import GodwinToken        "canister:godwin_token";

module {

  type Model = Model.Model;

  type Result<Ok, Err>        = Result.Result<Ok, Err>;
  type Map<K, V>              = Map.Map<K, V>;

  type Time                   = Int;
  type CategoryArray          = SubTypes.CategoryArray;
  type SubParameters          = SubTypes.SubParameters;
  type SubMigrationArgs       = SubMigrationTypes.Args;
  type Balance                = Types.Balance;
  type CreateSubGodwinResult  = Types.CreateSubGodwinResult;
  type TransferResult         = Types.TransferResult;
  type Principals             = Types.Principals;
  type AccessControlRole      = Types.AccessControlRole;
  type AccessControlError     = Types.AccessControlError;
  type UpgradeAllSubsResult   = Types.UpgradeAllSubsResult;
  type SingleSubUpgradeResult = Types.SingleSubUpgradeResult;
  type RemoveSubResult        = Types.RemoveSubResult;
  type MintBatchResult        = Types.MintBatchResult;
  type CreateSubGodwinError   = Types.CreateSubGodwinError;
  type SetUserNameError       = Types.SetUserNameError;
  type CyclesParameters       = Types.CyclesParameters;
  type BasePriceParameters    = Types.BasePriceParameters;
  type ValidationParams       = Types.ValidationParams;
  type Duration               = UtilsTypes.Duration;
  type GodwinSub              = GodwinSub.GodwinSub;

  let { toBaseResult; } = Types;

  public class Controller(_model: Model) {

    public func getAdmin() : Principal {
      _model.getAdmin();
    };

    public func setAdmin(caller: Principal, admin: Principal) : Result<(), AccessControlError> {
      Result.mapOk<(), (), AccessControlError>(verifyAuthorizedAccess(caller, #ADMIN), func() {
        _model.setAdmin(admin); 
      });
    };

    public func getCyclesParameters() : CyclesParameters {
      _model.getCyclesParameters();
    };

    public func setCyclesParameters(caller: Principal, cycles_parameters: CyclesParameters) : Result<(), AccessControlError> {
      Result.mapOk<(), (), AccessControlError>(verifyAuthorizedAccess(caller, #ADMIN), func() {
        _model.setCyclesParameters(cycles_parameters); 
      });
    };

    public func getSubCreationPriceE8s() : Balance {
      _model.getSubCreationPriceE8s();
    };

    public func setSubCreationPriceE8s(caller: Principal, price: Balance) : Result<(), AccessControlError> {
      Result.mapOk<(), (), AccessControlError>(verifyAuthorizedAccess(caller, #ADMIN), func() {
        _model.setSubCreationPriceE8s(price); 
      });
    };

    public func getBasePriceParameters() : BasePriceParameters {
      _model.getBasePriceParameters();
    };

    public func setBasePriceParameters(caller: Principal, base_price_parameters: BasePriceParameters) : async Result<(), AccessControlError> {
      switch(verifyAuthorizedAccess(caller, #ADMIN)){
        case(#err(err)) { return #err(err); };
        case(#ok) {};
      };
      
      _model.setBasePriceParameters(base_price_parameters);
      
      // Update the base price for all the subs
      // @todo: do not ignore the returned results, return an array of results instead
      for (principal in _model.getSubGodwins().keys()){
        let sub : GodwinSub = actor(Principal.toText(principal));
        ignore await sub.setBasePriceParameters(base_price_parameters);
      };

      #ok;
    };

    public func getSubValidationParams() : ValidationParams {
      _model.getSubParamsValidator().getParams();
    };
    
    public func setSubValidationParams(caller: Principal, params: ValidationParams) : Result<(), AccessControlError> {
      Result.mapOk<(), (), AccessControlError>(verifyAuthorizedAccess(caller, #ADMIN), func() {
        _model.getSubParamsValidator().setParams(params); 
      });
    };

    public func getCyclesBalance() : Nat {
      ExperimentalCycles.balance();
    };

    // @todo: it is dangerous to have the master and caller as parameters, use a named Principal inside a record instead
    public func createSubGodwin(principals: Principals, identifier: Text, sub_parameters: SubParameters, time: Time) : async CreateSubGodwinResult  {

      let { master; user; } = principals;

      // Verify the parameters
      switch(_model.getSubParamsValidator().validateSubGodwinParams(identifier, sub_parameters)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      // Proceed with the payment
      switch(await GodwinToken.burn({
        from_subaccount = ?Account.toSubaccount(user);
        amount = _model.getSubCreationPriceE8s();
        memo = null;
        created_at_time = ?Nat64.fromNat(Int.abs(time));
      })){
        case(#Err(err)) { return #err(err); };
        case(#Ok(_)) {};
      };
    
      ExperimentalCycles.add(_model.getCyclesParameters().create_sub_cycles);

      let new_sub = await (system GodwinSub.GodwinSub)(#new {settings = ?{ 
        controllers = ?[master, _model.getAdmin()];
        compute_allocation = null; // @todo: add this parameters in the model
        memory_allocation = null;
        freezing_threshold = null;
      }})(#init({ master; creator = user; sub_parameters; price_parameters = _model.getBasePriceParameters(); }));

      let principal = Principal.fromActor(new_sub);

      _model.getSubGodwins().set(principal, identifier);

      #ok(principal);
    };

    // In anticipation of next versions
    public func upgradeAllSubs(caller: Principal, args: SubMigrationArgs) : async UpgradeAllSubsResult {
      
      switch(verifyAuthorizedAccess(caller, #ADMIN)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      let update_results = Buffer.Buffer<(Principal, SingleSubUpgradeResult)>(0);

      for (principal in _model.getSubGodwins().keys()){
        
        let sub : GodwinSub = actor(Principal.toText(principal));

        ExperimentalCycles.add(_model.getCyclesParameters().upgrade_sub_cycles);
        
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

    public func removeSub(caller: Principal, identifier: Text) : RemoveSubResult {
      switch(verifyAuthorizedAccess(caller, #ADMIN)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      switch(_model.getSubGodwins().find(func(p: Principal, id: Text) : Bool { id == identifier; })){
        case(null) { return #err(#SubNotFound); };
        case(?(principal, _)) {
          // @todo: remove cycles, delete the canister
          _model.getSubGodwins().delete(principal);
          #ok(principal);
        };
      };
    };

    public func listSubGodwins() : [(Principal, Text)] {
      Iter.toArray(_model.getSubGodwins().entries());
    };

    public func pullTokens(caller: Principal, user: Principal, amount: Balance, subaccount: ?Blob, time: Time) : async TransferResult {

      switch(verifyAuthorizedAccess(caller, #SUB)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      toBaseResult(
        await GodwinToken.icrc1_transfer({
          amount;
          created_at_time = ?Nat64.fromNat(Int.abs(time));
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

    public func mintBatch(caller: Principal, args: GodwinToken.MintBatchArgs) : async MintBatchResult {

      switch(verifyAuthorizedAccess(caller, #SUB)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      toBaseResult(await GodwinToken.mint_batch(args));
    };

    public func mint(caller: Principal, args: GodwinToken.Mint) : async TransferResult {

      switch(verifyAuthorizedAccess(caller, #SUB)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      toBaseResult(await GodwinToken.mint(args));
    };

    public func getUserAccount(principals: Principals) : GodwinToken.Account {
      let { master; user; } = principals;
      { owner = master; subaccount = ?Account.toSubaccount(user) };
    };

    public func getUserName(user: Principal) : ?Text {
      _model.getUsers().getOpt(user);
    };

    public func setUserName(caller: Principal, name: Text) : Result<(), SetUserNameError> {
      Result.mapOk<(), (), SetUserNameError>(_model.getSubParamsValidator().validateUserName(caller, name), func() {
        _model.getUsers().set(caller, name);
      });
    };

    // Validation functions

    public func validateSubIdentifier(identifier: Text) : Result<(), CreateSubGodwinError> {
      _model.getSubParamsValidator().validateSubIdentifier(identifier);
    };

    public func validateSubName(name: Text) : Result<(), CreateSubGodwinError> {
      _model.getSubParamsValidator().validateSubName(name);
    };

    public func validateCategories(categories: CategoryArray) : Result<(), CreateSubGodwinError> {
      _model.getSubParamsValidator().validateCategories(categories);
    };

    public func validateSchedulerDuration(duration: Duration) : Result<(), CreateSubGodwinError> {
      _model.getSubParamsValidator().validateSchedulerDuration(duration);
    };

    public func validateConvictionDuration(duration: Duration) : Result<(), CreateSubGodwinError> {
      _model.getSubParamsValidator().validateConvictionDuration(duration);
    };

    public func validateCharacterLimit(character_limit: Nat) : Result<(), CreateSubGodwinError> {
      _model.getSubParamsValidator().validateCharacterLimit(character_limit);
    };

    public func validateMinimumInterestScore(minimum_interest_score: Float) : Result<(), CreateSubGodwinError> {
      _model.getSubParamsValidator().validateMinimumInterestScore(minimum_interest_score);
    };

    public func validateUserName(principal: Principal, name: Text) : Result<(), SetUserNameError> {
      _model.getSubParamsValidator().validateUserName(principal, name);
    };

    private func verifyAuthorizedAccess(principal: Principal, required_role: AccessControlRole) : Result<(), AccessControlError> {
      switch(required_role){
        case(#ADMIN) { if(principal == _model.getAdmin()) { return #ok; }; };
        case(#SUB) {
          if(_model.getSubGodwins().has(principal)){
            return #ok;
          };
        };
      };
      #err(#AccessDenied({required_role;}));
    };
  };

};