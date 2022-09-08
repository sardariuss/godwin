#!/usr/local/bin/ic-repl

function install(wasm, args, cycle) {
  identity default;
  let id = call ic.provisional_create_canister_with_cycles(record { settings = null; amount = opt (cycle : nat) });
  let S = id.canister_id;
  call ic.install_code(
    record {
      arg = args;
      wasm_module = wasm;
      mode = variant { install };
      canister_id = S;
    }
  );
  S
};

function installGodwin(){
  import interface = "2vxsx-fae" as "../../.dfx/local/canisters/godwin_backend/godwin_backend.did";
  let args = encode interface.__init_args();
  let wasm = file("../../.dfx/local/canisters/godwin_backend/godwin_backend.wasm");
  install(wasm, args, 0);
};
