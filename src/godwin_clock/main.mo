import Timer        "mo:base/Timer";

import GodwinMaster "canister:godwin_master";

actor GodwinClock {

  func runSubGodwins() : async () {
    //let master = await Master.get();
    //await master.subGodwins();
  };

  stable let _timer = Timer.recurringTimer(#seconds(60), runSubGodwins);

};
