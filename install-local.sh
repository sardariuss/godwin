dfx stop
dfx start --background --clean

# Deploy the backend
dfx deploy godwin_backend --argument '(record {
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
    interest_pick_rate = variant { SECONDS = 0 };
    interest_duration = variant { DAYS = 1 };
    opinion_duration = variant { SECONDS = 0 };
    categorization_duration = variant { SECONDS = 0 };
    rejected_duration = variant { DAYS = 1 };
  };
})'

# Deploy the internet identity
dfx deploy internet_identity

# @todo: Deploy the frontend
dfx canister create godwin_frontend

# Generate the candid files
dfx generate
