#!/usr/local/bin/ic-repl

load "common/install.sh";

identity default;

// Install the backend canister
let arguments = record {
  scheduler = record {
    interest_pick_rate = variant { SECONDS = 0 };
    interest_duration = variant { DAYS = 1 }; // To prevent the questions to be rejected
    opinion_duration = variant { SECONDS = 0 };
    categorization_duration = variant { SECONDS = 0 };
    rejected_duration = variant { SECONDS = 0 };
  };
  users = record {
    convictions_half_life = null;
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
  id = (0 : nat);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status_info = record {
    current = record {
      status = variant { VOTING = variant { INTEREST } };
    };
  };
}};
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status_info = record {
    current = record {
      status = variant { VOTING = variant { INTEREST } };
    };
  };
}};

"Get the interest ballot";
call backend.getInterestBallot(default, 0, 0);
assert _ ~= variant { ok = null };
"Up vote the question";
call backend.putInterestBallot(0, 0, variant { UP } );
assert _ == variant { ok };
"Down vote the question: should fail";
call backend.putInterestBallot(0, 0, variant { DOWN } );
assert _ == variant { err = variant { AlreadyVoted } };
"Set opinion: should fail";
call backend.putOpinionBallot(0, 0, 0.5);
assert _ == variant { err = variant { InvalidPoll } };
"Set categorization: should fail";
call backend.putCategorizationBallot(0, 0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
assert _ == variant { err = variant { InvalidPoll } };

"Open up opinion vote";
call backend.run();

call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status_info = record {
    current = record {
      status = variant { VOTING = variant { OPINION } };
    };
  };
}};

"Get opinion ballot";
call backend.getOpinionBallot(default, 0, 0);
assert _ ~= variant { ok = null };
"Set opinion: should succeed";
call backend.putOpinionBallot(0, 0, -1.0);
assert _ == variant { ok };
"Set opinion again: should succeed";
call backend.putOpinionBallot(0, 0, 0.5);
assert _ == variant { ok };
"Up vote the question should fail";
call backend.putInterestBallot(0, 0, variant { UP } );
assert _ == variant { err = variant { InvalidPoll } };
"Set categorization: should fail";
call backend.putCategorizationBallot(0, 0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; });
assert _ == variant { err = variant { InvalidPoll } };

call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status_info = record {
    current = record {
      status = variant { VOTING = variant { CATEGORIZATION } };
    };
  };
}};

"Get categorization ballot";
call backend.getCategorizationBallot(default, 0, 0);
assert _ ~= variant { ok = null };
"Set categorization: should succeed";
call backend.putCategorizationBallot(0, 0, vec { record { "IDENTITY"; 1.0; }; record { "COOPERATION"; 0.0; }; } );
assert _ ~= variant { ok };
"Set categorization again: should fail";
call backend.putCategorizationBallot(0, 0, vec { record { "IDENTITY"; -1.0; }; record { "COOPERATION"; 0.0; }; } );
assert _ == variant { err = variant { AlreadyVoted } };
"Up vote the question should fail";
call backend.putInterestBallot(0, 0, variant { UP } );
assert _ == variant { err = variant { InvalidPoll } };
"Set opinion: should fail";
call backend.putOpinionBallot(0, 0, -1.0);
assert _ == variant { err = variant { InvalidPoll } };

"Close the question";
call backend.run();
call backend.getQuestion(0);
assert _ ~= variant { ok = record { 
  id = (0 : nat);
  title = ("All sciences, even chemistry and biology are not uncompromising and are conditioned by our society." : text);
  status_info = record {
    current = record {
      status = variant { CLOSED };
    };
  };
}};

"Get default user, convictions to update";
call backend.getUserConvictions(default);
assert _ == variant { ok = vec { 
    record { "IDENTITY"; record { left = 0.0; center = 0.5; right = 0.5; }; };
    record { "COOPERATION"; record { left = 0.0; center = 0.0; right = 0.0; }; };
} };
