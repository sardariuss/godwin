import TestQueries "questions/testQueries";
import TestQuestions "questions/testQuestions";
//import TestInterests "votes/testInterests";
//import TestOpinions "votes/testOpinions";
//import TestCategorizations "votes/testCategorizations";
//import TestScheduler "testmodel/questions/QuestionQueries";
//import TestUsers "testUsers";

import Status "mo:testing/Status";

import Debug "mo:base/Debug";

// @todo: fix unit tests

let status = Status.Status();
await* TestQueries.run(status);
await* TestQuestions.run(status);

Debug.print("Overall results: ");
status.printStatus();
//TestInterests.run();
//TestOpinions.run();
//TestCategorizations.run();
//Suite.run(TestScheduler.TestScheduler().getSuite());
//Suite.run(TestUsers.TestUsers().getSuite());
