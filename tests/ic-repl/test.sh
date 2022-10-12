#!/usr/local/bin/ic-repl

load "common/install.sh";

// Install the backend canister
let arguments = record {
  scheduler = record {
    selection_interval = variant { SECONDS = 0 };
    reward_duration = variant { SECONDS = 1 };
    categorization_duration = variant { SECONDS = 1 };
  };
  categories_definition = vec {
    record { category = "IDENTITY"; sides = record { left = "CONSTRUCTIVISM"; right = "ESSENTIALISM"; } };
    record { category = "COOPERATION"; sides = record { left = "INTERNATIONALISM"; right = "NATIONALISM"; } };
    record { category = "PROPERTY"; sides = record { left = "COMMUNISM"; right = "CAPITALISM"; } };
    record { category = "ECONOMY"; sides = record { left = "REGULATION"; right = "LAISSEZFAIRE"; } };
    record { category = "CULTURE"; sides = record { left = "PROGRESSIVISM"; right = "CONSERVATISM"; } };
    record { category = "TECHNOLOGY"; sides = record { left = "ECOLOGY"; right = "PRODUCTION"; } };
    record { category = "JUSTICE"; sides = record { left = "REHABILITATION"; right = "PUNITION"; } };
    record { category = "CHANGE"; sides = record { left = "REVOLUTION"; right = "REFORM"; } } 
  };
};

let backend = installBackend(arguments);

// To use instead if wish to use the deployed backend
//identity default "~/.config/dfx/identity/default/identity.pem";
//import backend = "rrkah-fqaaa-aaaaa-aaaaq-cai";

call backend.createQuestion("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society.", "");
assert _ ~= record { id = (0 : nat); selection_stage = record { current = record { selection_stage = variant { SPAWN } }}};

call backend.getQuestion(0);
assert _ ~= variant { ok = record { id = (0 : nat); selection_stage = record { current = record { selection_stage = variant { SPAWN } }}}};

call backend.setEndorsement(0);
assert _ == variant { ok };
call backend.setOpinion(0, variant { AGREE = variant { ABSOLUTE } });
assert _ == variant { err = variant { WrongSelectionStage } };
call backend.setCategory(0, record { category = "IDENTITY"; direction = variant { LR }});
assert _ == variant { err = variant { WrongCategorizationState } };
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  selection_stage = record { current = record { selection_stage = variant { REWARD } }};
  categorization = record { 
    current = record { categorization = variant { PENDING } };
  };
}};

call backend.setOpinion(0, variant { AGREE = variant { ABSOLUTE } });
assert _ == variant { ok };
call backend.setCategory(0, record { category = "IDENTITY"; direction = variant { LR }});
assert _ == variant { err = variant { WrongCategorizationState } };
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  selection_stage = record { current = record { selection_stage = variant { ARCHIVE } }};
  categorization = record { 
    current = record { categorization = variant { ONGOING } };
  };
}};

call backend.setCategory(0, record { category = "IDENTITY"; direction = variant { LR }});
assert _ == variant { ok };
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  selection_stage = record { current = record { selection_stage = variant { ARCHIVE } }};
  categorization = record { 
    current = record { categorization = variant { DONE = vec { record { category = "IDENTITY"; direction = variant { LR }} } } };
  };
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

