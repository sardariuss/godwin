dfx stop
dfx start --background --clean

# Deploy the backend
dfx deploy godwin_backend --argument '(record {
  moderate_opinion_coef = 0.5;
  pools_parameters = record {
    spawn = record { ratio_max_endorsement = 0.5; time_elapsed_in_pool = 0; next_pool = variant { REWARD }; };
    fission = record { ratio_max_endorsement = 0.0; time_elapsed_in_pool = 86_400_000_000_000; next_pool = variant { ARCHIVE }; };
    archive = record { ratio_max_endorsement = 0.8; time_elapsed_in_pool = 259_200_000_000_000; next_pool = variant { REWARD }; };
  };
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