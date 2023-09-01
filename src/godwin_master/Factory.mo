import Controller             "Controller";
import Model                  "model/Model";
import SubParamsValidator     "model/SubParamsValidator";
import StableTypes            "stable/Types";

import Map                    "mo:map/Map";

import WRef                   "../godwin_sub/utils/wrappers/WRef";
import WMap                   "../godwin_sub/utils/wrappers/WMap";

module {

  type State               = StableTypes.Current.State;
  type BasePriceParameters = StableTypes.Current.BasePriceParameters;
  type ValidationParams    = StableTypes.Current.ValidationParams;
  type CyclesParameters    = StableTypes.Current.CyclesParameters;
  type Controller          = Controller.Controller;

  public func build(state: State) : Controller {
    let token                  = WRef.WRef<Principal>                 (state.token                                                                 );
    let admin                  = WRef.WRef<Principal>                 (state.admin                                                                 );
    let sub_godwins            = WMap.WMap<Principal, Text>           (state.sub_godwins, Map.phash                                                );
    let users                  = WMap.WMap<Principal, Text>           (state.users, Map.phash                                                      );
    let cycles_parameters      = WRef.WRef<CyclesParameters>          (state.cycles_parameters                                                     );
    let sub_creation_price_e9s = WRef.WRef<Nat>                       (state.sub_creation_price_e9s                                                );
    let base_price_parameters  = WRef.WRef<BasePriceParameters>       (state.base_price_parameters                                                 );
    let sub_params_validator   = SubParamsValidator.SubParamsValidator(WRef.WRef<ValidationParams>(state.validation_parameters), sub_godwins, users);
    let model = Model.Model(
      token,
      admin,
      cycles_parameters,
      sub_creation_price_e9s,
      base_price_parameters,
      sub_params_validator,
      sub_godwins,
      users,
    );
    Controller.Controller(model);
  };
  
};