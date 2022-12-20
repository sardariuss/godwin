#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default;

// Install the backend canister
let arguments = record {
  scheduler = record {
    selection_rate = variant { SECONDS = 0 };
    interest_duration = variant { DAYS = 1 };
    opinion_duration = variant { SECONDS = 0 };
    categorization_duration = variant { SECONDS = 0 };
    rejected_duration = variant { SECONDS = 0 };
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
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status = variant { CANDIDATE = record { aggregate = record { ups = 0 : int; downs = 0 : int; score = 0 : int; }; } };
  interests_history = vec {};
  vote_history = vec {};
}};
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status = variant { CANDIDATE = record { aggregate = record { ups = 0 : nat; downs = 0 : nat; score = 0 : int; }; } };
  interests_history = vec {};
  vote_history = vec {};
}};

"Up vote the question";
call backend.setInterest(0, variant { UP } );
assert _ == variant { ok };
"Set opinion: should fail";
call backend.setOpinion(0, 1.0);
assert _ == variant { err = variant { InvalidVotingStage } };
"Set categorization: should fail";
call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
assert _ == variant { err = variant { InvalidVotingStage } };

call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  status = variant { CANDIDATE = record { aggregate = record { ups = 1 : nat; downs = 0 : nat; score = 1 : int; }; } };
  interests_history = vec {};
  vote_history = vec {};
}};

"Open up opinion vote";
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  status = variant { OPEN = record { stage = variant { OPINION }; } };
  interests_history = vec { record { aggregate = record { ups = 1 : nat; downs = 0 : nat; score = 1 : int; }; } };
  vote_history = vec {};
}};

"Up vote the question: should fail";
call backend.setInterest(0, variant { UP } );
assert _ == variant { err = variant { InvalidVotingStage } };
"Set opinion: should succeed";
call backend.setOpinion(0, 1.0);
assert _ == variant { ok };
"Set categorization: should fail";
call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
assert _ == variant { err = variant { InvalidVotingStage } };

call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  status = variant { OPEN = record { stage = variant { OPINION }; iteration = record {
    opinion = record { aggregate = record { left = 0.0; center = 0.0; right = 1.0; } } 
  } } };
  interests_history = vec { record { aggregate = record { ups = 1 : nat; downs = 0 : nat; score = 1 : int; }; } };
  vote_history = vec {};
}};

"Open up categorization vote";
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  status = variant { OPEN = record { stage = variant { CATEGORIZATION }; } };
  interests_history = vec { record { aggregate = record { ups = 1 : nat; downs = 0 : nat; score = 1 : int; }; } };
  vote_history = vec {};
}};

"Up vote the question: should fail";
call backend.setInterest(0, variant { UP } );
assert _ == variant { err = variant { InvalidVotingStage } };
"Set opinion: should fail";
call backend.setOpinion(0, 1.0);
assert _ == variant { err = variant { InvalidVotingStage } };
"Set categorization: should succeed";
call backend.setCategorization(0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
assert _ == variant { ok };

call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  status = variant { OPEN = record { stage = variant { CATEGORIZATION }; } };
  interests_history = vec { record { aggregate = record { ups = 1 : nat; downs = 0 : nat; score = 1 : int; }; } };
  vote_history = vec {};
}};

"Close the question";
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat32);
  //status = variant { CLOSED };
  interests_history = vec { record { aggregate = record { ups = 1 : nat; downs = 0 : nat; score = 1 : int; }; } };
  vote_history = vec { record { opinion = record { aggregate = record { left = 0.0; center = 0.0; right = 1.0; } } } };
}};

//"Get default user, convictions to update";
//call backend.findUser(default);
//assert _ == variant { ok = record { 
//  "principal" = default;
//  name = null : opt record{};
//  convictions = record { to_update = true; array = vec { 
//    record { "IDENTITY"; record { left = 0.0; center = 0.0; right = 0.0; }; };
//    record { "COOPERATION"; record { left = 0.0; center = 0.0; right = 0.0; }; }; }; };
//} };
