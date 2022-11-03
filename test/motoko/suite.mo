import TestQueries "questions/testQueries";
import TestQuestions "questions/testQuestions";
import TestEndorsements "votes/testEndorsements";
import TestOpinions "votes/testOpinions";
import TestCategorizations "votes/testCategorizations";
import TestScheduler "testScheduler";
import TestUsers "testUsers";

import Suite "mo:matchers/Suite";

Suite.run(TestQueries.TestQueries().getSuite());
Suite.run(TestQuestions.TestQuestions().getSuite());
Suite.run(TestEndorsements.TestEndorsements().getSuite());
Suite.run(TestOpinions.TestOpinions().getSuite());
Suite.run(TestCategorizations.TestCategorizations().getSuite());
Suite.run(TestScheduler.TestScheduler().getSuite());
Suite.run(TestUsers.TestUsers().getSuite());
// @todo: test perCategorizationStage module
// @todo: test perSelectionStage module
// @todo: test stageHistory module