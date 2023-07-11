dfx stop
dfx start --background --clean

dfx canister create --all

dfx build --all

# Token settings
export NAME="Godwin"
export SYMBOL="GDW"
export DEMICALS="8"
export FEE="10_000" # 0.0001
export MAX_SUPPLY="100_000_000_000_000_000" # 1 billion
export MIN_BURN_AMOUNT="10_000" # Same as fee

# Deployer
export DEPLOYER_PRINCIPAL=$(dfx identity get-principal)
export DEPLOYER_AMOUNT="30_000_000_000_000_000" # 300 million

# Airdrop
export AIRDROP_CANISTER=$(dfx canister id godwin_airdrop)
export AIRDROP_AMOUNT="100_000_000_000_000" # 1 million
export AIRDROP_PER_USER="8_000_000_000" # 80 per user, 12.5k users
export AIRDROP_ALLOW_SELF="true"

# Master
export MASTER_CANISTER=$(dfx canister id godwin_master)

dfx canister install godwin_token

#dfx canister install godwin_token --argument '( record {
#  name              = "'${NAME}'";
#  symbol            = "'${SYMBOL}'";
#  decimals          = '${DEMICALS}';
#  fee               = '${FEE}';
#  max_supply        = '${MAX_SUPPLY}';
#  min_burn_amount   = '${MIN_BURN_AMOUNT}';
#  initial_balances  = vec {
#    record {
#      record {
#        owner = principal "'${DEPLOYER_PRINCIPAL}'";
#        subaccount = null
#      };
#      '${DEPLOYER_AMOUNT}'
#    };
#    record {
#      record {
#        owner = principal "'${AIRDROP_CANISTER}'";
#        subaccount = null
#      };
#      '${AIRDROP_AMOUNT}'
#    }
#  };
#  minting_account   = opt record { 
#    owner = principal "'${MASTER_CANISTER}'";
#    subaccount = null; 
#  };
#  advanced_settings = null;
#})'

dfx canister install godwin_airdrop --argument '('${AIRDROP_PER_USER}', '${AIRDROP_ALLOW_SELF}')'

dfx canister install godwin_master

dfx canister install internet_identity

dfx canister install godwin_clock

# @todo: Deploy the frontend
dfx canister create godwin_frontend

# Generate the candid files
dfx generate
