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
export GODWIN_CANISTER=$(dfx canister id godwin_token)

dfx canister install godwin_token --argument '( record {
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

dfx canister install godwin_airdrop --argument '('${AIRDROP_PER_USER}', '${AIRDROP_ALLOW_SELF}')'

dfx canister install godwin_master --argument='( variant { init = record {
  token = principal "'${GODWIN_CANISTER}'";
  admin = principal "'${DEPLOYER_PRINCIPAL}'";
  cycles_parameters = record {
    create_sub_cycles  = 50_000_000_000;
    upgrade_sub_cycles = 10_000_000_000;
  };
  sub_creation_price_e8s = 8_000_000_000;
  base_price_parameters = record {
    base_selection_period         = variant { DAYS = 1 : nat };
    open_vote_price_e8s           =  1_000_000_000;
    reopen_vote_price_e8s         =    500_000_000;
    interest_vote_price_e8s       =    100_000_000;
    categorization_vote_price_e8s =    300_000_000;
  };
  validation_parameters = record {
    username = record {
      min_length = 3;
      max_length = 32;
    };
    subgodwin = record {
      identifier = record {
        min_length = 3;
        max_length = 32;
      };
      subname = record {
        min_length = 3;
        max_length = 60;
      };
      scheduler_params =  record {
        minimum_duration = variant { MINUTES  = 10  };
        maximum_duration = variant { YEARS    = 1   };
      };
      convictions_params =  record {
        minimum_duration = variant { DAYS     = 1   };
        maximum_duration = variant { YEARS    = 100 };
      };
      question_char_limit =  record {
        maximum = 4000;
      };
      minimum_interest_score = record {
        minimum = 1.0;
      };
    };
  };
}})'

dfx canister install internet_identity

dfx canister install godwin_clock

# Generate the candid files
dfx generate

dfx canister install godwin_frontend