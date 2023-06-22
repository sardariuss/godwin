import Timer        "mo:base/Timer";

import GodwinMaster "canister:godwin_master";

import Array        "mo:base/Array";
import Principal    "mo:base/Principal";

actor GodwinClock {

  type SubInterface = actor {
    run : shared() -> async();
  };

  func runSubGodwins() : async () {
    let subs = await GodwinMaster.listSubGodwins();
    for ((principal, _) in Array.vals(subs)){
      let sub : SubInterface = actor(Principal.toText(principal));
      ignore sub.run();
    };
  };

  stable let _timer = Timer.recurringTimer(#seconds(60), runSubGodwins);

};
