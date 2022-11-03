#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default;

// Install the backend canister
let arguments = record {
  scheduler = record {
    selection_rate = variant { SECONDS = 0 };
    selection_duration = variant { SECONDS = 0 };
    categorization_duration = variant { SECONDS = 0 };
  };
  categories = vec {
    "IDENTITY";
    "COOPERATION";
  };
};

let backend = installBackend(arguments);

// To use instead if wish to use the deployed backend
//identity default "~/.config/dfx/identity/default/identity.pem";
//import backend = "rrkah-fqaaa-aaaaa-aaaaq-cai";

// @todo: one should not be able to ask a question as the anonymous user "2vxsx-fae"
// @todo: find a way to test partial vec to uncomment the tests on current stage

"Create the question";
call backend.createQuestion("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society.", "");
assert _ ~= record { 
  id = (0 : nat);
  endorsements = (0 : nat);
  selection_stage = vec { record { stage = variant { CREATED }; }; };
  categorization_stage = vec { record { stage = variant { PENDING }; }; }; 
};
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  endorsements = (0 : nat);
  selection_stage = vec { record { stage = variant { CREATED }; }; };
  categorization_stage = vec { record { stage = variant { PENDING }; }; }; 
}};

"Endorse the question: should succeed";
call backend.setEndorsement(0);
assert _ == variant { ok };
"Set opinion: should fail";
call backend.setOpinion(0, 1.0);
assert _ == variant { err = variant { WrongSelectionStage } };
"Set categorization: should fail";
call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
assert _ == variant { err = variant { WrongCategorizationStage } };

"Select the question";
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  endorsements = (1 : nat);
  //selection_stage = vec { record { stage = variant { CREATED }; }; record { stage = variant { SELECTED }; }; };
  //categorization_stage = vec { record { stage = variant { PENDING }; }; }; 
}};
"Set opinion: should succeed";
call backend.setOpinion(0, 1.0);
assert _ == variant { ok };
"Set categorization: should fail";
call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
assert _ == variant { err = variant { WrongCategorizationStage } };

"Archive the question and start categorization";
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  //selection_stage = vec { record { stage = variant { ARCHIVED = record { total = 1; cursor = 1.0; confidence = 1.0; }; }; }; };
  //categorization_stage = vec { record { stage = variant { ONGOING }; }; }; 
}};

"Set categorization: should succeed";
call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
assert _ == variant { ok };

"End categorization";
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  //selection_stage = vec { record { stage = variant { ARCHIVED = record { total = 1; cursor = 1.0; confidence = 1.0; }; }; }; };
  //categorization_stage = vec { record { stage = variant { DONE }; }; }; 
}};

"Get default user, convictions to update";
call backend.findUser(default);
assert _ == variant { ok = record { 
  "principal" = default;
  name = null : opt record{};
  convictions = record { to_update = true; categorization = vec {}; }
} };

"Compute user convictions";
call backend.updateConvictions(default);
assert _ == variant { ok };

"Get default user, updated convictions";
call backend.findUser(default);
assert _ == variant { ok = record { 
  "principal" = default;
  name = null : opt record{};
  convictions = record { to_update = false; categorization = vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; }; };
} };