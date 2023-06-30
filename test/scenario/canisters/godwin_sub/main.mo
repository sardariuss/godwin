import Types        "../../../../src/godwin_sub/model/Types";
import State        "../../../../src/godwin_sub/model/State";
import Factory      "../../../../src/godwin_sub/model/Factory";
import Facade       "../../../../src/godwin_sub/model/Facade";

import Duration     "../../../../src/godwin_sub/utils/Duration";

import Scenario     "../../Scenario";

import GodwinMaster "canister:godwin_master";

import Time         "mo:base/Time";
import Principal    "mo:base/Principal";

actor class GodwinSubScenario(parameters: Types.Parameters) = {

  // For convenience: from base module
  type Time = Time.Time;

  let _parameters = parameters;
  stable var _state = State.initState(Principal.fromActor(GodwinMaster), Time.now(), parameters);

  public shared func runScenario(
    scenario_duration: Types.Duration,
    tick_duration: Types.Duration
  ) : async () {
    // Reset the state where the start date is deduced from the scenario duration
    let start_date = Time.now() - Duration.toTime(scenario_duration);
    _state := State.initState(Principal.fromActor(GodwinMaster), start_date, _parameters);
    // Run the scenario
    await* Scenario.run(Factory.build(_state), start_date, Time.now(), tick_duration);
  };

};
