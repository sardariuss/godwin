import TestCategories "testCategories";
import TestConvictions "testConvictions";

import Suite "mo:matchers/Suite";

let testCategories = TestCategories.TestCategories();
Suite.run(testCategories.suiteVerifyOrientedCategory);
Suite.run(testCategories.suiteComputeCategoriesAggregation);

let testConvictions = TestConvictions.TestConvictions();
Suite.run(testConvictions.suiteAddConviction);
