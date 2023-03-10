//import TestQueries "questions/testQueries";
import TestQuestions "questions/testQuestions";
//import TestHotRanking "questions/testHotRanking";
import TestInterests "votes/testInterests";
import TestOpinions "votes/testOpinions";
import TestCategorizations "votes/testCategorizations";
//import TestScheduler "testmodel/QuestionQueries";
//import TestUsers "testUsers";

// @todo: fix unit tests

//Suite.run(TestQueries.TestQueries().getSuite());
TestQuestions.run();
TestInterests.run();
TestOpinions.run();
TestCategorizations.run();
//Suite.run(TestScheduler.TestScheduler().getSuite());
//Suite.run(TestUsers.TestUsers().getSuite());
//Suite.run(TestHotRanking.TestHotRanking().getSuite());
