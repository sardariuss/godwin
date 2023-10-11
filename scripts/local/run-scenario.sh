# Transfer btc to the deployer master subaccount to be able to create a sub
export GET_PRINCIPAL="dfx identity get-principal"
export DEPLOYER_PRINCIPAL=$(eval "$GET_PRINCIPAL")
export GET_MASTER_ACCOUNT="dfx canister call godwin_master getUserAccount '(principal \""${DEPLOYER_PRINCIPAL}"\")'"
export GET_MASTER_RESULT=$(eval "$GET_MASTER_ACCOUNT")
export DEPLOYER_MASTER_ACCOUNT=${GET_MASTER_RESULT:2:183}
export TRANSFER_TO_MASTER="dfx canister call ck_btc icrc1_transfer '(
  record {
    to = "${DEPLOYER_MASTER_ACCOUNT}";
    from_subaccount = null;
    amount = 50010;
    memo = null;
    created_at_time = null;
    fee = null;
  }
)'"
eval "$TRANSFER_TO_MASTER"

# Create sub godwin
export SUB_PARAMETERS=$(cat ./test/subs/8values.did)
export SUB_COMMAND="dfx canister call godwin_master createSubGodwin '(\"8values\", "$SUB_PARAMETERS", variant { BTC })'"
export SUB_RESULT=$(eval "$SUB_COMMAND")
export SUB=${SUB_RESULT:27:27}

# Transfer btc to the sub so the scenario is able to transfer them to the fake users
export TRANSFER_TO_SUB="dfx canister call ck_btc icrc1_transfer '(
  record {
    to = record {
      owner = principal \""${SUB}"\";
      subaccount = null;
    };
    from_subaccount = null;
    amount = 1_000_000_000;
    memo = null;
    created_at_time = null;
    fee = null;
  }
)'"
eval "$TRANSFER_TO_SUB"

# Scenario
export AIRDROP_SATS_PER_USER="100_000 : nat" # 100_000 tokens per user
# Put scenario wasm
export SUB_UPGRADE_1="dfx canister install "${SUB}" --wasm=\".dfx/local/canisters/scenario/scenario.wasm\" --mode=upgrade --yes"
eval "$SUB_UPGRADE_1"
# Run scenario
export RUN_SUB_SCENARIO="dfx canister call "${SUB}" runScenario '(variant { DAYS = 10 : nat }, variant { MINUTES = 50 : nat }, "${AIRDROP_SATS_PER_USER}" )'"
eval "$RUN_SUB_SCENARIO"
# Put back the original wasm
export SUB_UPGRADE_2="dfx canister install "${SUB}" --wasm=\".dfx/local/canisters/godwin_sub/godwin_sub.wasm\" --mode=upgrade --yes --argument='(variant {none})'"
eval "$SUB_UPGRADE_2"
