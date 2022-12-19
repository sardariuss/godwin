import TestQueries "questions/testQueries";
import TestQuestions "questions/testQuestions";
import TestHotRanking "questions/testHotRanking";
import TestInterests "votes/testInterests";
import TestOpinions "votes/testOpinions";
import TestCategorizations "votes/testCategorizations";
import TestScheduler "testScheduler";
import TestUsers "testUsers";

import Suite "mo:matchers/Suite";

Suite.run(TestQueries.TestQueries().getSuite());
Suite.run(TestQuestions.TestQuestions().getSuite());
Suite.run(TestInterests.TestInterests().getSuite());
Suite.run(TestOpinions.TestOpinions().getSuite());
Suite.run(TestCategorizations.TestCategorizations().getSuite());
Suite.run(TestScheduler.TestScheduler().getSuite());
Suite.run(TestUsers.TestUsers().getSuite());
//Suite.run(TestHotRanking.TestHotRanking().getSuite());
