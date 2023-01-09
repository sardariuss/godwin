dfx stop
dfx start --background --clean

# Deploy the backend
dfx deploy godwin_backend --argument '(record {
  scheduler = record {
    selection_rate = variant { SECONDS = 0 };
    interest_duration = variant { SECONDS = 0 };
    opinion_duration = variant { SECONDS = 0 };
    categorization_duration = variant { SECONDS = 0 };
    rejected_duration = variant { DAYS = 1 };
  };
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
  convictions_half_life = null;
})'