#dfx stop
#dfx start --background --clean

#dfx canister create --all

#dfx build --all

export DEPLOYER_PRINCIPAL=$(dfx identity get-principal)
export SCENARIO_ID=$(dfx canister id scenario_sub)
export MASTER_ID=$(dfx canister id godwin_master)
export TOKEN_ID=$(dfx canister id godwin_token)

# Local deployement parameters
# ckBTC
export CK_BTC_MINTER=${DEPLOYER_PRINCIPAL} # The deployer is the minter in local environment
export CK_BTC_SCENARIO_PRE_MINT_AMOUNT="1_000_000_000" # The scenario canister requires some BTC to transfer to the users so they can participate
# Godwin token
export TOKEN_NAME="GodwinCoin"
export TOKEN_SYMBOL="GDWC"
export TOKEN_DEMICALS="9"
export TOKEN_FEE="100_000"
export TOKEN_MAX_SUPPLY="1_000_000_000_000_000_000" # 1 billion
export TOKEN_MIN_BURN_AMOUNT="100_000" # Same as fee
export TOKEN_MINTER=${DEPLOYER_PRINCIPAL} # The deployer is the minter in local environment
export TOKEN_MASTER_PRE_MINT_AMOUNT="300_000_000_000_000_000" # 300 million pre-mined
# Godwin master
export MASTER_ADMIN=${DEPLOYER_PRINCIPAL} # The deployer is the admin in local environment, will become SNS in production
export MASTER_REWARD_TOKEN=${TOKEN_ID};
export MASTER_CYCLES_CREATE_SUB="200_000_000_000"
export MASTER_CYCLES_UPGRADE_SUB="10_000_000_000"
export MASTER_PRICE_SATS_OPEN_VOTE="2_000"
export MASTER_PRICE_SATS_REOPEN_VOTE="1_000"
export MASTER_PRICE_SATS_INTEREST_VOTE="200"
export MASTER_PRICE_SATS_CATEGORIZATION_VOTE="500"
export MASTER_PRICE_SATS_SUB_CREATION="50_000"

dfx canister install ck_btc --argument '( record {
  name              = "ckBTC";
  symbol            = "ckBTC";
  decimals          = 8;
  fee               = 10;
  max_supply        = 2_100_000_000_000_000;
  min_burn_amount   = 1_000;
  initial_balances  = vec {
    record {
      record {
        owner = principal "'${SCENARIO_ID}'";
        subaccount = null
      };
      '${CK_BTC_SCENARIO_PRE_MINT_AMOUNT}'
    }
  };
  minting_account   = opt record { 
    owner = principal "'${CK_BTC_MINTER}'";
    subaccount = null; 
  };
  advanced_settings = null;
})'

dfx canister install godwin_token --argument '( record {
  name              = "'${TOKEN_NAME}'";
  symbol            = "'${TOKEN_SYMBOL}'";
  decimals          = '${TOKEN_DEMICALS}';
  fee               = '${TOKEN_FEE}';
  max_supply        = '${TOKEN_MAX_SUPPLY}';
  min_burn_amount   = '${TOKEN_MIN_BURN_AMOUNT}';
  initial_balances  = vec {
    record {
      record {
        owner = principal "'${MASTER_ID}'";
        subaccount = null
      };
      '${TOKEN_MASTER_PRE_MINT_AMOUNT}'
    };
  };
  minting_account   = opt record { 
    owner = principal "'${TOKEN_MINTER}'";
    subaccount = null; 
  };
  advanced_settings = null;
})'

dfx canister install godwin_master --argument='( variant { init = record {
  token = principal "'${TOKEN_ID}'";
  admin = principal "'${DEPLOYER_PRINCIPAL}'";
  cycles_parameters = record {
    create_sub_cycles  = '${MASTER_CYCLES_CREATE_SUB}';
    upgrade_sub_cycles = '${MASTER_CYCLES_UPGRADE_SUB}';
  };
  price_parameters = record {
    open_vote_price_sats           = '${MASTER_PRICE_SATS_OPEN_VOTE}';
    reopen_vote_price_sats         = '${MASTER_PRICE_SATS_REOPEN_VOTE}';
    interest_vote_price_sats       = '${MASTER_PRICE_SATS_INTEREST_VOTE}';
    categorization_vote_price_sats = '${MASTER_PRICE_SATS_CATEGORIZATION_VOTE}';
    sub_creation_price_sats        = '${MASTER_PRICE_SATS_SUB_CREATION}';
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