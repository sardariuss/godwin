dfx stop
dfx start --background --clean

# It is required to create the master first to be able to set it as the token owner
dfx canister create godwin_master

dfx deploy godwin_token

dfx deploy godwin_master
dfx canister call godwin_master runScenario

# The backend needs to be created and built to be able to generate the types later
dfx canister create godwin_sub
dfx build godwin_sub

# Create first sub godwin
dfx canister call godwin_master createSubGodwin '("classic6", record {
  name = "Classic 6 values ⚖️";
  categories = vec {
    record {
      "IDENTITY"; 
      record { left  = record { name = "CONSTRUCTIVISM"; symbol = "🧩"; color = "#f26c0d"; }; 
               right = record { name = "ESSENTIALISM";   symbol = "💎"; color = "#f2a60d"; }; }
    };
    record {
      "ECONOMY";  
      record { left  = record { name = "SOCIALISM";      symbol = "🌹"; color = "#0fca02"; }; 
               right = record { name = "CAPITALISM";     symbol = "🎩"; color = "#02ca27"; }; }
    };
    record {
      "CULTURE";  
      record { left  = record { name = "PROGRESSIVISM";  symbol = "🌊"; color = "#2c00cc"; }; 
               right = record { name = "CONSERVATISM";   symbol = "🧊"; color = "#5f00cc"; }; }
    };
  };
  scheduler = record {
    question_pick_rate        = variant { HOURS = 2    };
    censor_timeout            = variant { MINUTES = 30 };
    candidate_status_duration = variant { HOURS = 8    };
    open_status_duration      = variant { HOURS = 4    };
    rejected_status_duration  = variant { HOURS = 8    };
  };
  questions = record {
    character_limit = 240;
  };
  prices = record {
    open_vote_price_e8s = 1_000_000_000;
    interest_vote_price_e8s = 100_000_000;
    categorization_vote_price_e8s =  350_000_000;
  };
  decay_half_life = variant { DAYS = 365 };
  minimum_interest_score = 1.0;
})'
# Run the scenario @todo for some reason this does not work, one shall use ic-repl instead
#export SUB_6_VALUES_PRINCIPAL=${SUB_6_VALUES_ID:1:29}
#dfx canister call ${SUB_6_VALUES_PRINCIPAL} runScenario

# Create second sub godwin
dfx canister call godwin_master createSubGodwin '("uspolitics", record {
  name = "US politics 🇺🇸";
  categories = vec {
    record {
      "PARTISANSHIP"; 
      record { left  = record { name = "DEMOCRAT";   symbol = "🦓"; color = "#1404BD"; }; 
               right = record { name = "REPUBLICAN"; symbol = "🐘"; color = "#DE0100"; }; }
    };
  };
  scheduler = record {
    question_pick_rate        = variant { HOURS = 1    };
    censor_timeout            = variant { MINUTES = 20 };
    candidate_status_duration = variant { HOURS = 4    };
    open_status_duration      = variant { HOURS = 1    };
    rejected_status_duration  = variant { HOURS = 6    };
  };
  questions = record {
    character_limit = 240;
  };
  prices = record {
    open_vote_price_e8s = 1_000_000_000;
    interest_vote_price_e8s = 100_000_000;
    categorization_vote_price_e8s =  350_000_000;
  };
  decay_half_life = variant { DAYS = 365 };
  minimum_interest_score = 1.0;
})'

# Deploy the internet identity
dfx deploy internet_identity

# @todo: Deploy the frontend
dfx canister create godwin_frontend

# Generate the candid files
dfx generate

# @todo: need to deploy the clock, but run the scenario first
