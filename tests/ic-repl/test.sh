#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default;

// Install the backend canister
let arguments = record {
  moderate_opinion_coef = 0.5;
  pools_parameters = record {
    spawn = record { ratio_max_endorsement = 0.5; time_elapsed_in_pool = 0; next_pool = variant { REWARD }; };
    fission = record { ratio_max_endorsement = 0.0; time_elapsed_in_pool = 0; next_pool = variant { ARCHIVE }; };
    archive = record { ratio_max_endorsement = 0.8; time_elapsed_in_pool = 0; next_pool = variant { REWARD }; };
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
};

let backend = installBackend(arguments);

call backend.createQuestion("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society.", "");
assert _ ~= record { id = (0 : nat); pool = record { current = record { pool = variant { SPAWN } }}};

call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { id = (0 : nat); pool = record { current = record { pool = variant { SPAWN } }}}};

call backend.setEndorsement(0);
assert _ == variant { ok };
call backend.setOpinion(0, variant { AGREE = variant { ABSOLUTE } });
assert _ == variant { err = variant { WrongPool } };
call backend.setCategory(0, record { category = "IDENTITY"; direction = variant { LR }});
assert _ == variant { err = variant { WrongPool } };

call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { id = (0 : nat); pool = record { current = record { pool = variant { REWARD } }}}};

call backend.setOpinion(0, variant { AGREE = variant { ABSOLUTE } });
assert _ == variant { ok };
call backend.setCategory(0, record { category = "IDENTITY"; direction = variant { LR }});
assert _ == variant { ok };

call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  pool = record { current = record { pool = variant { ARCHIVE }}};
  categories = vec { record { category = "IDENTITY"; direction = variant { LR }}}
}};

call backend.getOrCreateUser(default);
assert _ == variant { ok = record { "principal" = default; name = null : opt record{}; convictions = record { to_update = true; array = vec {}; }}};

call backend.computeUserConvictions(default);
assert _ == variant { ok = record { 
  "principal" = default; 
  name = null : opt record{};
  convictions = record { 
    array = vec { record { 
      category = "IDENTITY"; 
      conviction = record { left = 1.0 : float64; center = 0.0 : float64; right = 0.0 : float64;};
    };};
    to_update = false; 
  };
}};

