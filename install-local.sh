dfx stop
dfx start --background --clean

# It is required to create the master first to be able to set it as the token owner
dfx canister create godwin_master

dfx deploy godwin_token

dfx deploy godwin_master
dfx canister call godwin_master runScenario

# The backend needs to be created and built to be able to generate the types later
dfx canister create godwin_backend
dfx build godwin_backend

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
  history = record {
    convictions_half_life = null;
  };
  scheduler = record {
    interest_pick_rate = variant { HOURS = 1 };
    interest_duration = variant { HOURS = 4 };
    opinion_duration = variant { HOURS = 1 };
    rejected_duration = variant { HOURS = 6 };
  };
  questions = record {
    character_limit = 240;
  };
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
  history = record {
    convictions_half_life = null;
  };
  scheduler = record {
    interest_pick_rate = variant { HOURS = 1 };
    interest_duration = variant { HOURS = 4 };
    opinion_duration = variant { HOURS = 1 };
    rejected_duration = variant { HOURS = 6 };
  };
  questions = record {
    character_limit = 240;
  };
})'

# Deploy the internet identity
dfx deploy internet_identity

# @todo: Deploy the frontend
dfx canister create godwin_frontend

# Generate the candid files
dfx generate
