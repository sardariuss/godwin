dfx stop
dfx start --background --clean

# Deploy the backend
dfx deploy godwin_backend --argument '(record {
  scheduler = record {
    selection_rate = variant { HOURS = 4 };
    selection_duration = variant { DAYS = 5 };
    categorization_duration = variant { DAYS = 5 };
  };
  categories_definition = vec {
    record { "IDENTITY"; record { left = "CONSTRUCTIVISM"; right = "ESSENTIALISM"; } };
    record { "COOPERATION"; record { left = "INTERNATIONALISM"; right = "NATIONALISM"; } };
    record { "PROPERTY"; record { left = "COMMUNISM"; right = "CAPITALISM"; } };
    record { "ECONOMY"; record { left = "REGULATION"; right = "LAISSEZFAIRE"; } };
    record { "CULTURE"; record { left = "PROGRESSIVISM"; right = "CONSERVATISM"; } };
    record { "TECHNOLOGY"; record { left = "ECOLOGY"; right = "PRODUCTION"; } };
    record { "JUSTICE"; record { left = "REHABILITATION"; right = "PUNITION"; } };
    record { "CHANGE"; record { left = "REVOLUTION"; right = "REFORM"; } } };
})'