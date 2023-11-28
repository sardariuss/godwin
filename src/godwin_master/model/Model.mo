import StableTypes         "../stable/Types";
import SubParamsValidator   "SubParamsValidator";

import WRef                "../../godwin_sub/utils/wrappers/WRef";
import WMap                "../../godwin_sub/utils/wrappers/WMap";

module {

  type WRef<T>             = WRef.WRef<T>;
  type WMap<K, V>          = WMap.WMap<K, V>;
  
  type CyclesParameters    = StableTypes.Current.CyclesParameters;
  type BasePriceParameters = StableTypes.Current.BasePriceParameters;
  type SubParamsValidator  = SubParamsValidator.SubParamsValidator;

  // The model is the main data structure of the app. It contains all the classes used
  // by the controller, and referes to the stable types.
  public class Model(
    _token                   : WRef<Principal>,
    _admin                   : WRef<Principal>,
    _cycles_parameters       : WRef<CyclesParameters>,
    _sub_creation_price_e9s  : WRef<Nat>,
    _base_price_parameters   : WRef<BasePriceParameters>,
    _sub_params_validator    : SubParamsValidator,
    _sub_godwins             : WMap<Principal, Text>,
    _users                   : WMap<Principal, Text>
    ) {

    public func getToken() : Principal {
      _token.get();
    };

    public func setToken(token: Principal) {
      _token.set(token);
    };

    public func getAdmin() : Principal {
      _admin.get();
    };

    public func setAdmin(admin: Principal) {
      _admin.set(admin);
    };

    public func getCyclesParameters() : CyclesParameters {
      _cycles_parameters.get();
    };

    public func setCyclesParameters(cycles_parameters: CyclesParameters) {
      _cycles_parameters.set(cycles_parameters);
    };

    public func getSubCreationPriceE8s() : Nat {
      _sub_creation_price_e9s.get();
    };

    public func setSubCreationPriceE8s(sub_creation_price_e9s: Nat) {
      _sub_creation_price_e9s.set(sub_creation_price_e9s);
    };
    
    public func getBasePriceParameters() : BasePriceParameters {
      _base_price_parameters.get();
    };

    public func setBasePriceParameters(base_price_parameters: BasePriceParameters) {
      _base_price_parameters.set(base_price_parameters);
    };

    public func getSubParamsValidator() : SubParamsValidator {
      _sub_params_validator;
    };

    public func getSubGodwins() : WMap<Principal, Text> {
      _sub_godwins;
    };

    public func getUsers() : WMap<Principal, Text> {
      _users;
    };

  };

};