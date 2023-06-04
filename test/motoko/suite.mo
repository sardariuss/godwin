import TestQueries "questions/testQueries";
import TestQuestions "questions/testQuestions";
//import TestInterests "votes/testInterests";
import TestOpinions "votes/testOpinions";

import Status "mo:testing/Status";

import Debug "mo:base/Debug";

// @todo: fix unit tests

let status = Status.Status();
await* TestQueries.run(status);
await* TestQuestions.run(status);
await* TestOpinions.run(status);

Debug.print("Overall results: ");
status.printStatus();
