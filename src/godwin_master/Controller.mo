import Types              "Types";
import Model              "model/Model";

import GodwinSub          "../godwin_sub/main";
import SubTypes           "../godwin_sub/model/Types";
import UtilsTypes         "../godwin_sub/utils/Types";
import Account            "../godwin_sub/utils/Account";
import SubMigrationTypes  "../godwin_sub/stable/Types";

import TokenTypes         "../godwin_token/Types";

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
import Blob               "mo:base/Blob";
import Option             "mo:base/Option";
import Debug              "mo:base/Debug";
import Array              "mo:base/Array";

import ckBTC              "canister:ck_btc";

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
  type PullBtcResult          = Types.PullBtcResult;
  type AccessControlRole      = Types.AccessControlRole;
  type AccessControlError     = Types.AccessControlError;
  type UpgradeAllSubsResult   = Types.UpgradeAllSubsResult;
  type SingleSubUpgradeResult = Types.SingleSubUpgradeResult;
  type RemoveSubResult        = Types.RemoveSubResult;
  type RewardGwcResult        = Types.RewardGwcResult;
  type CreateSubGodwinError   = Types.CreateSubGodwinError;
  type SetUserNameError       = Types.SetUserNameError;
  type CyclesParameters       = Types.CyclesParameters;
  type PriceParameters        = Types.PriceParameters;
  type ValidationParams       = Types.ValidationParams;
  type LedgerType             = Types.LedgerType;
  type RewardGwcReceiver      = Types.RewardGwcReceiver;
  type CanisterCallError      = Types.CanisterCallError;
  type TransferResult         = Types.TransferResult;
  type Account                = Types.Account;
  type Duration               = UtilsTypes.Duration;
  type GodwinSub              = GodwinSub.GodwinSub;

  let { toBaseResult; } = Types;

  public class Controller(_model: Model) {

    let _token : TokenTypes.FullInterface = actor(Principal.toText(_model.getToken()));

    var _self_id : ?Principal = null;

    public func setSelfId(self_id: Principal) {
      _self_id := ?self_id;
    };

    func unwrapSelfId() : Principal {
      switch(_self_id){
        case(null) { Debug.trap("Self principal is not set"); };
        case(?self_id) { self_id; };
      };
    };

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

    public func getPriceParameters() : PriceParameters {
      _model.getPriceParameters();
    };

    public func setPriceParameters(caller: Principal, base_price_parameters: PriceParameters) : async Result<(), AccessControlError> {
      switch(verifyAuthorizedAccess(caller, #ADMIN)){
        case(#err(err)) { return #err(err); };
        case(#ok) {};
      };
      
      _model.setPriceParameters(base_price_parameters);
      
      // Update the base price for all the subs
      // @todo: do not ignore the returned results, return an array of results instead
      for (principal in _model.getSubGodwins().keys()){
        let sub : GodwinSub = actor(Principal.toText(principal));
        ignore await sub.setPriceParameters(base_price_parameters);
      };

      #ok;
    };

    public func setBtcToGwcRewardRate(caller: Principal, rate: Float) : async Result<(), AccessControlError> {
      await setPriceParameters(caller, { _model.getPriceParameters() with btc_to_gwc_reward_rate = rate; });
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
    public func createSubGodwin(user: Principal, identifier: Text, sub_parameters: SubParameters, time: Time, ledger: LedgerType) : async CreateSubGodwinResult  {

      // Verify the parameters
      switch(_model.getSubParamsValidator().validateSubGodwinParams(identifier, sub_parameters)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      // Proceed with the payment
      let transfer = switch(ledger){
        case(#BTC) {
          try{
            await ckBTC.icrc1_transfer({
              from_subaccount = ?Blob.toArray(Account.toSubaccount(user));
              to = { owner = getAdmin(); subaccount = null; };
              fee = ?10; // @todo: remove hard-coded fee
              amount = _model.getPriceParameters().sub_creation_price_sats;
              memo = null;
              created_at_time = ?Nat64.fromNat(Int.abs(time));
            });
          } catch(e){
            #Err(toCanisterCallError(Principal.fromActor(ckBTC), "icrc1_transfer", e));
          };
        };
        case(#GWC) {
          try{
            await _token.icrc1_transfer({
              from_subaccount = ?Account.toSubaccount(user);
              to = { owner = getAdmin(); subaccount = null; };
              fee = ?100_000; // @todo: remove hard-coded fee
              amount = _model.getPriceParameters().sub_creation_price_gwc_e9s;
              memo = null;
              created_at_time = ?Nat64.fromNat(Int.abs(time));
            });
          } catch(e){
            #Err(toCanisterCallError(Principal.fromActor(_token), "icrc1_transfer", e));
          };
        };
      };
     
      switch(transfer){
        case(#Err(err)) { return #err(err); };
        case(#Ok(_)) {};
      };
    
      ExperimentalCycles.add(_model.getCyclesParameters().create_sub_cycles);

      let new_sub = try {
        await (system GodwinSub.GodwinSub)(#new {settings = ?{ 
          controllers = ?[unwrapSelfId(), _model.getAdmin()];
          compute_allocation = null; // @todo: add this parameters in the model
          memory_allocation = null;
          freezing_threshold = null;
        }})(#init({ master = unwrapSelfId(); token = Principal.fromActor(_token); creator = user; sub_parameters; price_parameters = _model.getPriceParameters(); }));
      } catch(e){
        return #err(toCanisterCallError(Principal.fromText("aaaaa-aa"), "new GodwinSub", e));
      };

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
          #err(toCanisterCallError(Principal.fromText("aaaaa-aa"), "update GodwinSub", e));
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

    public func pullBtc(caller: Principal, user: Principal, amount: Balance, subaccount: ?Blob, time: Time) : async PullBtcResult {

      switch(verifyAuthorizedAccess(caller, #SUB)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      toBaseResult(
        await ckBTC.icrc1_transfer({
          amount;
          created_at_time = ?Nat64.fromNat(Int.abs(time));
          fee = ?10; // @todo: remove hard-coded fee
          from_subaccount = ?Blob.toArray(Account.toSubaccount(user));
          memo = null;
          to = {
            owner = caller;
            subaccount = Option.map(subaccount, Blob.toArray);
          };
        })
      );
    };

    public func rewardGwc(caller: Principal, time: Time, receivers: [RewardGwcReceiver]) : async RewardGwcResult {

      switch(verifyAuthorizedAccess(caller, #SUB)){
        case(#err(err)) { return #err(err); };
        case(#ok()) {};
      };

      let results = Buffer.Buffer<(RewardGwcReceiver, TransferResult)>(0);

      for (receiver in Array.vals(receivers)){
        let result = try {
          toBaseResult(await _token.icrc1_transfer({
            from_subaccount = null;
            to = { owner = unwrapSelfId(); subaccount = ?Account.toSubaccount(receiver.to) };
            fee = ?100_000;
            amount = receiver.amount;
            memo = null;
            created_at_time = ?Nat64.fromNat(Int.abs(time));
          }));
        } catch(e) {
          #err(toCanisterCallError(Principal.fromActor(_token), "icrc1_transfer", e));
        };
        results.add((receiver, result));
      };

      #ok(Buffer.toArray(results));
    };

    public func getUserAccount(user: Principal) : Account {
      { owner = unwrapSelfId(); subaccount = ?Account.toSubaccount(user) };
    };

    public func getUserName(user: Principal) : ?Text {
      _model.getUsers().getOpt(user);
    };

    public func setUserName(caller: Principal, name: Text) : Result<(), SetUserNameError> {
      Result.mapOk<(), (), SetUserNameError>(_model.getSubParamsValidator().validateUserName(caller, name), func() {
        _model.getUsers().set(caller, name);
      });
    };

    public func cashOut(caller: Principal, to: Account, amount: Nat, ledger: LedgerType, time: Time) : async TransferResult {
      // Proceed with the payment
      switch(ledger){
        case(#BTC) {
          try{
            toBaseResult(await ckBTC.icrc1_transfer({
              from_subaccount = ?Blob.toArray(Account.toSubaccount(caller));
              to = { owner = to.owner; subaccount = Option.map(to.subaccount, Blob.toArray); };
              fee = ?10; // @todo: remove hard-coded fee
              amount;
              memo = null;
              created_at_time = ?Nat64.fromNat(Int.abs(time));
            }));
          } catch(e){
            #err(toCanisterCallError(Principal.fromActor(ckBTC), "icrc1_transfer", e));
          };
        };
        case(#GWC) {
          try{
            toBaseResult(await _token.icrc1_transfer({
              from_subaccount = ?Account.toSubaccount(caller);
              to;
              fee = ?100_000; // @todo: remove hard-coded fee
              amount;
              memo = null;
              created_at_time = ?Nat64.fromNat(Int.abs(time));
            }));
          } catch(e){
            #err(toCanisterCallError(Principal.fromActor(_token), "icrc1_transfer", e));
          };
        };
      };
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

  private func toCanisterCallError(principal: Principal, method: Text, error: Error) : CanisterCallError {
    #CanisterCallError({ canister = principal; method; code = Error.code(error); message = Error.message(error); });
  };

};