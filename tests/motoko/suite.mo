import TestCategories "testCategories";
import TestConvictions "testConvictions";
import TestTotalVotes "testTotalVotes";

import Suite "mo:matchers/Suite";

let testCategories = TestCategories.TestCategories();
Suite.run(testCategories.suiteVerifyOrientedCategory);
Suite.run(testCategories.suiteComputeCategoriesAggregation);

let testConvictions = TestConvictions.TestConvictions();
Suite.run(testConvictions.suiteAddConviction);

let testTotalVotes = TestTotalVotes.TestTotalVotes();
Suite.run(testTotalVotes.suiteTotalVotes);
