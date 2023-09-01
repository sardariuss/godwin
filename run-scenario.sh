# Airdrop scenario
export AIRDROP_PER_USER="10_000_000_000_000 : nat" # 10_000 tokens per user, for 1000 users
export AIRDROP_ALLOW_SELF="true"
export AIRDROP_CANISTER=$(dfx canister id godwin_airdrop)

export AIRDROP_UPGRADE_1="dfx canister install "${AIRDROP_CANISTER}" --wasm=\".dfx/local/canisters/scenario_airdrop/scenario_airdrop.wasm\" --mode=upgrade --yes --argument='("${AIRDROP_PER_USER}", "${AIRDROP_ALLOW_SELF}")'"
eval "$AIRDROP_UPGRADE_1"
export RUN_AIRDROP_SCENARIO="dfx canister call "${AIRDROP_CANISTER}" runScenario"
eval "$RUN_AIRDROP_SCENARIO"
export AIRDROP_UPGRADE_2="dfx canister install "${AIRDROP_CANISTER}" --wasm=\".dfx/local/canisters/godwin_airdrop/godwin_airdrop.wasm\" --mode=upgrade --yes --argument='("${AIRDROP_PER_USER}", "${AIRDROP_ALLOW_SELF}")'"
eval "$AIRDROP_UPGRADE_2"

# Creating a sub requires tokens in caller's subaccount on the master canister
export GET_PRINCIPAL="dfx identity get-principal"
export DEPLOYER_PRINCIPAL=$(eval "$GET_PRINCIPAL")
export GET_MASTER_ACCOUNT="dfx canister call godwin_master getUserAccount '(principal \""${DEPLOYER_PRINCIPAL}"\")'"
export GET_MASTER_RESULT=$(eval "$GET_MASTER_ACCOUNT")
export DEPLOYER_MASTER_ACCOUNT=${GET_MASTER_RESULT:2:183}
export TRANSFER_TO_MASTER="dfx canister call godwin_token icrc1_transfer '(
  record {
    to = "${DEPLOYER_MASTER_ACCOUNT}";
    from_subaccount = null;
    amount = 50_000_000_100_000;
    memo = null;
    created_at_time = null;
    fee = opt 100_000;
  }
)'"
eval "$TRANSFER_TO_MASTER"

# Create first sub godwin
export SUB_PARAMETERS=$(cat ./test/scenario/parameters/8values.did)
export SUB_COMMAND="dfx canister call godwin_master createSubGodwin '(\"8values\", "$SUB_PARAMETERS")'"
export SUB_RESULT=$(eval "$SUB_COMMAND")
export SUB=${SUB_RESULT:27:27}

export SUB_UPGRADE_1="dfx canister install "${SUB}" --wasm=\".dfx/local/canisters/scenario_sub/scenario_sub.wasm\" --mode=upgrade --yes"
eval "$SUB_UPGRADE_1"
export RUN_SUB_SCENARIO="dfx canister call "${SUB}" runScenario '(variant { DAYS = 10 : nat } , variant { MINUTES = 50 : nat } )'"
eval "$RUN_SUB_SCENARIO"
export SUB_UPGRADE_2="dfx canister install "${SUB}" --wasm=\".dfx/local/canisters/godwin_sub/godwin_sub.wasm\" --mode=upgrade --yes --argument='(variant {none})'"
eval "$SUB_UPGRADE_2"

## Create second sub godwin
##export SUB_2_PARAMETERS=$(cat ./test/scenario/parameters/uspolitics.did)
##export SUB_2_COMMAND="dfx canister call godwin_master createSubGodwin '("uspolitics", "$SUB_2_PARAMETERS")')"
##export SUB_2_RESULT=$(eval "$SUB_2_COMMAND")
##export SUB_2=${SUB_2_RESULT:27:27}
##echo $SUB_2
