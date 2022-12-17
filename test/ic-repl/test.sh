#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default;

// Install the backend canister
let arguments = record {
  scheduler = record {
    selection_rate = variant { SECONDS = 0 };
    interest_duration = variant { SECONDS = 0 };
    opinion_duration = variant { SECONDS = 0 };
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
call backend.openQuestion("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society.", "");
assert _ ~= record { 
  id = (0 : nat32);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status = variant { CANDIDATE = record { aggregate = record { ups = 0 : int; downs = 0 : int; score = 0 : int; }; } };
  interest_history = vec {};
  vote_history = vec {};
};
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status = variant { CANDIDATE = record { aggregate = record { ups = 0 : int; downs = 0 : int; score = 0 : int; }; } };
  interest_history = vec {};
  vote_history = vec {};
}};

//"Up vote the question: should always succeed";
//call backend.setInterest(0, variant { UP } );
//assert _ == variant { ok };
//"Set opinion: should fail";
//call backend.setOpinion(0, 1.0);
//assert _ == variant { err = variant { WrongSelectionStage } };
//"Set categorization: should fail";
//call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
//assert _ == variant { err = variant { WrongCategorizationStage } };
//
//"Select the question";
//call backend.run();
//call backend.getQuestion(0);
//assert _ ~= variant { ok = record { 
//  id = (0 : nat);
//  interests = record { ups = 1 : int; downs = 0 : int; score = 1 : int; };
//  //selection_stage = vec { record { stage = variant { CREATED }; }; record { stage = variant { SELECTED }; }; };
//  //categorization_stage = vec { record { stage = variant { PENDING }; }; }; 
//}};
//"Up vote the question: should always succeed";
//call backend.setInterest(0, variant { UP } );
//assert _ == variant { ok };
//"Set opinion: should succeed";
//call backend.setOpinion(0, 1.0);
//assert _ == variant { ok };
//"Set categorization: should fail";
//call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
//assert _ == variant { err = variant { WrongCategorizationStage } };
//
//"Archive the question and start categorization";
//call backend.run();
//call backend.getQuestion(0);
//assert _ ~= variant { ok = record { 
//  id = (0 : nat);
//  //selection_stage = vec { record { stage = variant { ARCHIVED = record { total = 1; cursor = 1.0; confidence = 1.0; }; }; }; };
//  //categorization_stage = vec { record { stage = variant { ONGOING }; }; }; 
//}};
//
//"Up vote the question: should always succeed";
//call backend.setInterest(0, variant { UP } );
//assert _ == variant { ok };
//"Set opinion: should fail";
//call backend.setOpinion(0, 1.0);
//assert _ == variant { err = variant { WrongSelectionStage } };
//"Set categorization: should succeed";
//call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
//assert _ == variant { ok };
//
//"End categorization";
//call backend.run();
//call backend.getQuestion(0);
//assert _ ~= variant { ok = record { 
//  id = (0 : nat);
//  //selection_stage = vec { record { stage = variant { ARCHIVED = record { total = 1; cursor = 1.0; confidence = 1.0; }; }; }; };
//  //categorization_stage = vec { record { stage = variant { DONE }; }; }; 
//}};
//
//"Get default user, convictions to update";
//call backend.findUser(default);
//assert _ == variant { ok = record { 
//  "principal" = default;
//  name = null : opt record{};
//  convictions = record { to_update = true; array = vec { 
//    record { "IDENTITY"; record { left = 0.0; center = 0.0; right = 0.0; }; };
//    record { "COOPERATION"; record { left = 0.0; center = 0.0; right = 0.0; }; }; }; };
//} };
//
//"Compute user convictions";
//call backend.updateConvictions(default);
//assert _ == variant { ok = record { 
//  "principal" = default;
//  name = null : opt record{};
//  convictions = record { to_update = false; array = vec { 
//    record { "IDENTITY"; record { left = 0.0; center = 0.0; right = 1.0; }; };
//    record { "COOPERATION"; record { left = 0.0; center = 0.0; right = 0.0; }; }; }; };
//} };