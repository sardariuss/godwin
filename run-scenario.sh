# Airdrop scenario
export AIRDROP_PER_USER="100_000_000_000 : nat" # 1 thousand per user, 10 thousands users
export AIRDROP_ALLOW_SELF="true"
export AIRDROP_CANISTER=$(dfx canister id godwin_airdrop)

export AIRDROP_UPGRADE_1="dfx canister install "${AIRDROP_CANISTER}" --wasm=\".dfx/local/canisters/scenario_airdrop/scenario_airdrop.wasm\" --mode=upgrade --yes --argument='("${AIRDROP_PER_USER}", "${AIRDROP_ALLOW_SELF}")'"
eval "$AIRDROP_UPGRADE_1"
export RUN_AIRDROP_SCENARIO="dfx canister call "${AIRDROP_CANISTER}" runScenario"
eval "$RUN_AIRDROP_SCENARIO"
export AIRDROP_UPGRADE_2="dfx canister install "${AIRDROP_CANISTER}" --wasm=\".dfx/local/canisters/godwin_airdrop/godwin_airdrop.wasm\" --mode=upgrade --yes --argument='("${AIRDROP_PER_USER}", "${AIRDROP_ALLOW_SELF}")'"
eval "$AIRDROP_UPGRADE_2"

# Create first sub godwin
export SUB_PARAMETERS=$(cat ./test/scenario/parameters/classic6.did)
export SUB_COMMAND="dfx canister call godwin_master createSubGodwin '(\"classic6\", "$SUB_PARAMETERS")'"
export SUB_RESULT=$(eval "$SUB_COMMAND")
export SUB=${SUB_RESULT:27:27}

export SUB_UPGRADE_1="dfx canister install "${SUB}" --wasm=\".dfx/local/canisters/scenario_sub/scenario_sub.wasm\" --mode=upgrade --yes --argument='("${SUB_PARAMETERS}")'"
eval "$SUB_UPGRADE_1"
export RUN_SUB_SCENARIO="dfx canister call "${SUB}" runScenario '(variant { MINUTES = 830 : nat } , variant { MINUTES = 10 : nat } )'"
eval "$RUN_SUB_SCENARIO"
export SUB_UPGRADE_2="dfx canister install "${SUB}" --wasm=\".dfx/local/canisters/godwin_sub/godwin_sub.wasm\" --mode=upgrade --yes --argument='(variant {none})'"
eval "$SUB_UPGRADE_2"

# Create second sub godwin
#export SUB_2_PARAMETERS=$(cat ./test/scenario/parameters/uspolitics.did)
#export SUB_2_COMMAND="dfx canister call godwin_master createSubGodwin '("uspolitics", "$SUB_2_PARAMETERS")')"
#export SUB_2_RESULT=$(eval "$SUB_2_COMMAND")
#export SUB_2=${SUB_2_RESULT:27:27}
#echo $SUB_2
