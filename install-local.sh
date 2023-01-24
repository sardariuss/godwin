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
  users = record {
    convictions_half_life = null;
  };
  scheduler = record {
    selection_rate = variant { SECONDS = 0 };
    status_durations = vec {
      record { variant { INTEREST }; variant { SECONDS = 0 }; };
      record { variant { OPEN = variant { OPINION } }; variant { SECONDS = 0 }; };
      record { variant { OPEN = variant { CATEGORIZATION } }; variant { SECONDS = 0 }; };
      record { variant { CLOSED }; variant { SECONDS = 0 }; };
      record { variant { REJECTED }; variant { DAYS = 1 }; };
    };
  };
})'