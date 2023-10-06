import StableTypes         "../stable/Types";
import SubParamsValidator   "SubParamsValidator";

import WRef                "../../godwin_sub/utils/wrappers/WRef";
import WMap                "../../godwin_sub/utils/wrappers/WMap";

module {

  type WRef<T>             = WRef.WRef<T>;
  type WMap<K, V>          = WMap.WMap<K, V>;
  
  type CyclesParameters    = StableTypes.Current.CyclesParameters;
  type PriceParameters     = StableTypes.Current.PriceParameters;
  type SubParamsValidator  = SubParamsValidator.SubParamsValidator;

  public class Model(
    _token                   : WRef<Principal>,
    _admin                   : WRef<Principal>,
    _cycles_parameters       : WRef<CyclesParameters>,
    _price_parameters        : WRef<PriceParameters>,
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
    
    public func getPriceParameters() : PriceParameters {
      _price_parameters.get();
    };

    public func setPriceParameters(brice_parameters: PriceParameters) {
      _price_parameters.set(brice_parameters);
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