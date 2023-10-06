import V0_2_0         "./00-02-00-bitcoin/State";
import MigrationTypes "Types";

import Debug          "mo:base/Debug";

module {

  type Time  = Int;

  type Args  = MigrationTypes.Args;
  type State = MigrationTypes.State;
  type Versions = MigrationTypes.Versions;

  // do not forget to change current migration when you add a new one
  let { init; upgrade; downgrade; } = V0_2_0;

  public func getVersions(state: State) : Versions {
    {
      expected = #v0_2_0;
      actual  = switch(state) {
        case(#v0_2_0(_)){ #v0_2_0; };
        case(#v0_1_0(_)){ #v0_1_0; };
      };
    };
  };

  public func install(date: Time, args: Args) : State {
    switch(args){
      case(#init(init_args)){ 
        init(date, init_args);
      };
      case(_){
        Debug.trap("Unexpected install args: only #init args are supported"); 
      };
    };
  };

  public func migrate(prevState: State, date: Time, args: Args): State {
    var state = prevState;

    switch(args){
      case(#upgrade(upgrade_args)){ 
        Debug.print("Upgrading state to next version");
        state := upgrade(state, date, upgrade_args); 
      };
      case(#downgrade(downgrade_args)){ 
        Debug.print("Downgrading state to previous version");
        state := downgrade(state, date, downgrade_args); 
      };
      case(_){ 
        Debug.print("Migration ignored: use #upgrade or #downgrade args to effectively migrate state");
      };
    };

    state;
  };

};