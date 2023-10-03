export DEPLOYER_PRINCIPAL=$(dfx identity get-principal)
export TOKEN_CANISTER=$(dfx canister id godwin_token --network=ic)

dfx canister install godwin_master --network=ic --argument='( variant { init = record {
  token = principal "'${TOKEN_CANISTER}'";
  admin = principal "'${DEPLOYER_PRINCIPAL}'";
  cycles_parameters = record {
    create_sub_cycles  = 50_000_000_000;
    upgrade_sub_cycles = 10_000_000_000;
  };
  sub_creation_price_e9s = 25_000_000_000_000;
  base_price_parameters = record {
    base_selection_period         = variant { DAYS = 1 : nat };
    open_vote_price_e9s           =  10_000_000_000_000;
    reopen_vote_price_e9s         =   5_000_000_000_000;
    interest_vote_price_e9s       =   1_000_000_000_000;
    categorization_vote_price_e9s =   3_000_000_000_000;
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