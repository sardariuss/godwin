# Token settings
export NAME="GodwinCoin"
export SYMBOL="GDWC"
export DEMICALS="9"
export FEE="100_000"
export MAX_SUPPLY="1_000_000_000_000_000_000" # 1 billion
export MIN_BURN_AMOUNT="100_000" # Same as fee

# Deployer
export DEPLOYER_PRINCIPAL=$(dfx identity get-principal --network=ic)
export DEPLOYER_AMOUNT="300_000_000_000_000_000" # 300 million

# Airdrop
export AIRDROP_CANISTER=$(dfx canister id godwin_airdrop --network=ic)
export AIRDROP_AMOUNT="10_000_000_000_000_000" # 10 million
export AIRDROP_PER_USER="10_000_000_000_000" # 10_000 tokens per user, for 1000 users
export AIRDROP_ALLOW_SELF="true"

# Master
export MASTER_CANISTER=$(dfx canister id godwin_master --network=ic)

dfx canister install godwin_token --network=ic --argument '( record {
  name              = "'${NAME}'";
  symbol            = "'${SYMBOL}'";
  decimals          = '${DEMICALS}';
  fee               = '${FEE}';
  max_supply        = '${MAX_SUPPLY}';
  min_burn_amount   = '${MIN_BURN_AMOUNT}';
  initial_balances  = vec {
    record {
      record {
        owner = principal "'${DEPLOYER_PRINCIPAL}'";
        subaccount = null
      };
      '${DEPLOYER_AMOUNT}'
    };
    record {
      record {
        owner = principal "'${AIRDROP_CANISTER}'";
        subaccount = null
      };
      '${AIRDROP_AMOUNT}'
    }
  };
  minting_account   = opt record { 
    owner = principal "'${MASTER_CANISTER}'";
    subaccount = null; 
  };
  advanced_settings = null;
})'