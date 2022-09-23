dfx stop
dfx start --background --clean

# Deploy the backend
dfx deploy godwin_backend --argument '(record {
  selection_interval = variant { HOURS = 4 };
  reward_duration = variant { DAYS = 5 };
  categorization_duration = variant { DAYS = 5 };
  moderate_opinion_coef = 0.5;
  categories_definition = vec {
    record { category = "IDENTITY"; sides = record { left = "CONSTRUCTIVISM"; right = "ESSENTIALISM"; } };
    record { category = "COOPERATION"; sides = record { left = "INTERNATIONALISM"; right = "NATIONALISM"; } };
    record { category = "PROPERTY"; sides = record { left = "COMMUNISM"; right = "CAPITALISM"; } };
    record { category = "ECONOMY"; sides = record { left = "REGULATION"; right = "LAISSEZFAIRE"; } };
    record { category = "CULTURE"; sides = record { left = "PROGRESSIVISM"; right = "CONSERVATISM"; } };
    record { category = "TECHNOLOGY"; sides = record { left = "ECOLOGY"; right = "PRODUCTION"; } };
    record { category = "JUSTICE"; sides = record { left = "REHABILITATION"; right = "PUNITION"; } };
    record { category = "CHANGE"; sides = record { left = "REVOLUTION"; right = "REFORM"; } } };
  aggregation_parameters = record {
    direction_threshold = 0.65;
    category_threshold = 0.35;
  };
})'