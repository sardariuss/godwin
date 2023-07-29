import Types          "../../../../src/godwin_sub/model/Types";
import MigrationTypes "../../../../src/godwin_sub/stable/Types";
import Migrations     "../../../../src/godwin_sub/stable/Migrations";
import Factory        "../../../../src/godwin_sub/model/Factory";

import Duration       "../../../../src/godwin_sub/utils/Duration";

import Scenario       "../../Scenario";

import GodwinMaster  "canister:godwin_master";

import Time          "mo:base/Time";
import Principal     "mo:base/Principal";
import Debug         "mo:base/Debug";

actor class GodwinSubScenario(
  sub_parameters: Types.SubParameters,
  price_parameters: Types.BasePriceParameters
){

  // For convenience: from base module
  type Time = Time.Time;

  stable var _state: MigrationTypes.State = Migrations.install(Time.now(), #none); // State already exists, so this line won't be run

  public shared func runScenario(
    scenario_duration: Types.Duration,
    tick_duration: Types.Duration
  ) : async () {
    let now = Time.now();

    // Reset the state where the start date is deduced from the scenario duration
    let start_date = now - Duration.toTime(scenario_duration);
    _state := Migrations.install(start_date, #init({master = Principal.fromActor(GodwinMaster); sub_parameters; price_parameters;}));

    let facade = switch(_state){
      case(#v0_1_0(state)) { Factory.build(state); };
      case(_) { Debug.trap("impossible"); }; // Required in anticipation of next versions
    };
    // Run the scenario
    await* Scenario.run(facade, start_date, now, tick_duration);
  };

};
