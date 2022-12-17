dfx stop
dfx start --background --clean

# Deploy the backend
dfx deploy godwin_backend --argument '(record {
  scheduler = record {
    selection_rate = variant { HOURS = 4 };
    interest_duration = variant { DAYS = 3 };
    opinion_duration = variant { DAYS = 2 };
    categorization_duration = variant { DAYS = 5 };
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
  convictions_decay = null;
})'