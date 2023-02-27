dfx stop
dfx start --background --clean

# Deploy the backend
dfx deploy godwin_backend --argument '(record {
  categories = vec {
    "IDENTITY";
    "COOPERATION";
    "PROPERTY";
    "ECONOMY";
    "CULTURE";
    "TECHNOLOGY";
    "JUSTICE";
    "CHANGE";
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
