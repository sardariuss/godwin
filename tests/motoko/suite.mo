//import TestCategories "testCategories";
//import TestConvictions "testConvictions";
//import TestTotalVotes "testTotalVotes";
import TestQueries "questions/testQueries";

import Suite "mo:matchers/Suite";

// @todo: test perCategorizationStage and perSelectionStage modules ?

// @todo: test questions module

// @todo: test scheduler module

// @todo: test stageHistory module

// @todo: test users module

// @todo: test utils module

// @todo: rename testCategories into testCategorization and update the test with new "continuous" aggregation
//let testCategories = TestCategories.TestCategories();
//Suite.run(testCategories.suiteVerifyOrientedCategory);
//Suite.run(testCategories.suiteComputeCategoriesAggregation);

// @todo: rename testConvictions into testUsers and add the missing function and update on convictions
//let testConvictions = TestConvictions.TestConvictions();
//Suite.run(testConvictions.suiteAddConviction);

// @todo: rename testTotalVotes into testOpinions and use new aggregation
//let testTotalVotes = TestTotalVotes.TestTotalVotes();
//Suite.run(testTotalVotes.suiteTotalVotes);

let testQueries = TestQueries.TestQueries();
Suite.run(testQueries.suiteAddQuestions);
Suite.run(testQueries.suiteReplaceQuestions);
Suite.run(testQueries.suiteRemoveQuestions);
