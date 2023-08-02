import Types           "Types";
import MigrationTypes  "../Types";
import Ref             "../../../godwin_sub/utils/Ref";

import Map             "mo:map/Map";

import Debug           "mo:base/Debug";

module {

  type Map<K, V>           = Map.Map<K, V>;
  type Time                = Int;
  type State               = MigrationTypes.State;
  type InitArgs            = Types.InitArgs;
  type UpgradeArgs         = Types.UpgradeArgs;
  type DowngradeArgs       = Types.DowngradeArgs;
  type BasePriceParameters = Types.BasePriceParameters;
  type CyclesParameters    = Types.CyclesParameters;
  type ValidationParams    = Types.ValidationParams;

  public func init(date: Time, args: InitArgs) : State {
    
    let { admin; cycles_parameters; sub_creation_price_e8s; base_price_parameters; validation_parameters; } = args;

    #v0_1_0({
      admin                   = Ref.init<Principal>(admin);
      cycles_parameters       = Ref.init<CyclesParameters>(cycles_parameters);
      sub_creation_price_e8s  = Ref.init<Nat>(sub_creation_price_e8s);
      base_price_parameters   = Ref.init<BasePriceParameters>(base_price_parameters);
      validation_parameters   = Ref.init<ValidationParams>(validation_parameters);
      sub_godwins             = Map.new<Principal, Text>(Map.phash);
      users                   = Map.new<Principal, Text>(Map.phash);
    });
  };

  // From nothing to 0.1.0
  public func upgrade(migration_state: State, date: Time, args: UpgradeArgs): State {
    Debug.trap("Cannot upgrade to initial version");
  };

  // From 0.1.0 to nothing
  public func downgrade(migration_state: State, date: Time, args: DowngradeArgs): State {
    Debug.trap("Cannot downgrade from initial version");
  };

};