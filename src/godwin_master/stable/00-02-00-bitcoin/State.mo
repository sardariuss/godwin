import V0_2_0          "Types";
import V0_1_0          "../00-01-00-initial/Types";
import MigrationTypes  "../Types";

import Ref             "../../../godwin_sub/utils/Ref";

import Map             "mo:map/Map";

import Debug           "mo:base/Debug";

module {

  type Map<K, V>           = Map.Map<K, V>;
  type Time                = Int;
  type State               = MigrationTypes.State;
  type InitArgs            = V0_2_0.InitArgs;
  type UpgradeArgs         = V0_2_0.UpgradeArgs;
  type DowngradeArgs       = V0_2_0.DowngradeArgs;
  type PriceParameters     = V0_2_0.PriceParameters;
  type CyclesParameters    = V0_2_0.CyclesParameters;
  type ValidationParams    = V0_2_0.ValidationParams;

  public func init(date: Time, args: InitArgs) : State {
    
    let { token; admin; cycles_parameters; price_parameters; validation_parameters; } = args;

    #v0_2_0({
      token                   = Ref.init<Principal>(token);
      admin                   = Ref.init<Principal>(admin);
      cycles_parameters       = Ref.init<CyclesParameters>(cycles_parameters);
      price_parameters        = Ref.init<PriceParameters>(price_parameters);
      validation_parameters   = Ref.init<ValidationParams>(validation_parameters);
      sub_godwins             = Map.new<Principal, Text>(Map.phash);
      users                   = Map.new<Principal, Text>(Map.phash);
    });
  };

  // From 0.1.0 to 0.2.0
  public func upgrade(migration_state: State, date: Time, args: UpgradeArgs): State {
    // Access current state
    let state = switch(migration_state){
      case(#v0_1_0(state)) state;
      case(_)              Debug.trap("Unexpected migration state (v0_1_0 expected)");
    };

    #v0_2_0({ state with
      price_parameters = Ref.init<PriceParameters>(args.price_parameters)
    });
  };

  // From 0.2.0 to 0.1.0
  public func downgrade(migration_state: State, date: Time, args: DowngradeArgs): State {
    Debug.trap("Downgrade not supported");
  };

};