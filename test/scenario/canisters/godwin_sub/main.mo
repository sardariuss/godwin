import Types          "../../../../src/godwin_sub/model/Types";
import MigrationTypes "../../../../src/godwin_sub/stable/Types";
import Migrations     "../../../../src/godwin_sub/stable/Migrations";
import Factory        "../../../../src/godwin_sub/model/Factory";

import Duration       "../../../../src/godwin_sub/utils/Duration";

import Scenario       "../../Scenario";

import GodwinMaster  "canister:godwin_master";

import Map           "mo:map/Map";

import Time          "mo:base/Time";
import Principal     "mo:base/Principal";
import Debug         "mo:base/Debug";
import Iter          "mo:base/Iter";

actor class GodwinSubScenario(){

  // For convenience: from base module
  type Time = Time.Time;

  // The state shall already exist, so this line won't be run
  stable var _state: MigrationTypes.State = Migrations.install(Time.now(), #none);

  public shared func runScenario(
    scenario_duration: Types.Duration,
    tick_duration: Types.Duration
  ) : async () {
    let now = Time.now();
    
    let args = switch(_state){
      case(#v0_1_0(state)) { {
          master = state.master.v;
          token = state.token.v;
          creator = state.creator;
          sub_parameters = {
            name = state.name.v;
            categories = Iter.toArray(Map.entries(state.categories));
            scheduler = state.scheduler_params.v;
            character_limit = state.questions.character_limit;
            convictions = {
              vote_half_life = state.votes.opinion.vote_decay_params.v.half_life;
              late_ballot_half_life = state.votes.opinion.late_ballot_decay_params.v.half_life;
            };
            selection = state.selection_params.v;
          };
          price_parameters = state.base_price_params.v;
        };
      };
    };

    // Reset the state where the start date is deduced from the scenario duration
    let start_date = now - Duration.toTime(scenario_duration);
    _state := Migrations.install(start_date, #init(args));

    let facade = switch(_state){
      case(#v0_1_0(state)) { Factory.build(state); };
    };
    // Run the scenario
    await* Scenario.run(facade, start_date, now, tick_duration);
  };

};
