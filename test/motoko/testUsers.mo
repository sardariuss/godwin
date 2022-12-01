import Types "../../src/godwin_backend/types";
import Users "../../src/godwin_backend/users";
import Polarization "../../src/godwin_backend/representation/polarization";
import Questions "../../src/godwin_backend/questions/questions";
import StageHistory "../../src/godwin_backend/stageHistory";
import Categories "../../src/godwin_backend/categories";
import Opinions "../../src/godwin_backend/votes/opinions";
import Utils "../../src/godwin_backend/utils";
import TestableItems "testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types module
  type Question = Types.Question;
  // For convenience: from other modules
  type Users = Users.Users;
  
  public class TestUsers() = {

    // @todo: remove asserts, use matchers instead
    public func getSuite() : Suite.Suite {

      let tests = Buffer.Buffer<Suite.Suite>(0);

      let principals = [
        Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"),
        Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"),
        Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe")
      ];

      let categories = Categories.Categories(["IDENTITY", "ECONOMY", "CULTURE"]);
      let users = Users.empty(categories);
      let questions = Questions.empty(categories);

      let question = questions.createQuestion(principals[0], 0, "title0", "text0");

      // Get the anonymous user
      assert(users.findUser(Principal.fromText("2vxsx-fae")) == null);

      // Get the users (create them)
      for (principal in Array.vals(principals)){
        switch(users.findUser(principal)){
          case(null) { assert(false); };
          case(?user) { 
            assert(user.principal == principal);
            assert(user.name == null);
            assert(user.convictions.to_update);
            let convictions_trie = Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal);
            for ((_, conviction) in Trie.iter(convictions_trie)){
              assert(Polarization.isNil(conviction));
            };
          };
        };
      };

      // Get the users (retrieve them)
      for (principal in Array.vals(principals)){
        switch(users.findUser(principal)){
          case(null) { assert(false); };
          case(?user) { 
            assert(user.principal == principal);
            assert(user.name == null);
            assert(user.convictions.to_update);
            let convictions_trie = Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal);
            for ((_, conviction) in Trie.iter(convictions_trie)){
              assert(Polarization.isNil(conviction));
            };
          };
        };
      };

      // Update the convictions before having any opinion shall not return null, because
      // at user creation the flag is set to true
      for (principal in Array.vals(principals)){
        assert(not users.updateConvictions(principal, questions).convictions.to_update);
      };

      // Verify the convictions have been updated
      for (principal in Array.vals(principals)){
        switch(users.findUser(principal)){
          case(null) { assert(false); };
          case(?user) {
            // The convictions are still nil because no opinion has been given
            assert(not user.convictions.to_update);
            let convictions_trie = Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal);
            for ((_, conviction) in Trie.iter(convictions_trie)){
              assert(Polarization.isNil(conviction));
            };
          };
        };
      };

      // Users 0 and 1 give their opinions
      Opinions.put(users, principals[0], questions, question.id, 0.0); // totally neutral
      Opinions.put(users, principals[1], questions, question.id, 1.0); // totally agree

      // Update the question categorization stage to done with an arbitrate categorization
      questions.replaceQuestion({
        id = question.id;
        author = question.author;
        title = question.title;
        text = question.text;
        date = question.date;
        aggregates = question.aggregates;
        selection_stage = question.selection_stage;
        categorization_stage = StageHistory.setActiveStage(question.categorization_stage, { 
          stage = #DONE([
            ("IDENTITY", {left = 0.0; center = 0.0; right = 1.0;}),
            ("ECONOMY",  {left = 0.0; center = 0.5; right = 0.5;}),
            ("CULTURE",  {left = 0.0; center = 1.0; right = 0.0;})
          ]); 
          timestamp = 1000; 
        });
      });

      // Prune the convictions linked to users who answered this question
      // @todo: if an observer is used, one don't have to make this call
      users.pruneConvictions(question.id);

      // Verify the convictions shall be updated for users who answered this question
      // User 0
      var user = users.getUser(principals[0]);
      assert(user.convictions.to_update);
      user := users.updateConvictions(principals[0], questions);
      assert(not user.convictions.to_update);
      tests.add(test(
        "User 0 convictions",
        Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.5; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 1
      user := users.getUser(principals[1]);
      assert(user.convictions.to_update);
      user := users.updateConvictions(principals[1], questions);
      assert(not user.convictions.to_update);
      tests.add(test(
        "User 1 convictions",
        Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.5; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 2
      user := users.getUser(principals[2]);
      assert(not user.convictions.to_update);

      // Test adding a new category
      categories.add("JUSTICE");
      // User 0
      user := users.getUser(principals[0]);
      assert(user.convictions.to_update);
      user := users.updateConvictions(principals[0], questions);
      assert(not user.convictions.to_update);
      tests.add(test(
        "User 0 convictions",
        Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.5; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 1
      user := users.getUser(principals[1]);
      assert(user.convictions.to_update);
      user := users.updateConvictions(principals[1], questions);
      assert(not user.convictions.to_update);
      tests.add(test(
        "User 1 convictions",
        Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.5; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 2
      user := users.getUser(principals[2]);
      assert(user.convictions.to_update);
      user := users.updateConvictions(principals[2], questions);
      assert(not user.convictions.to_update);
      tests.add(test(
        "User 2 convictions",
        Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 0.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));

      // Test removing an old category
      categories.remove("ECONOMY");
      // User 0
      user := users.getUser(principals[0]);
      assert(user.convictions.to_update);
      user := users.updateConvictions(principals[0], questions);
      assert(not user.convictions.to_update);
      tests.add(test(
        "User 0 convictions",
        Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 1
      user := users.getUser(principals[1]);
      assert(user.convictions.to_update);
      user := users.updateConvictions(principals[1], questions);
      assert(not user.convictions.to_update);
      tests.add(test(
        "User 1 convictions",
        Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 2
      user := users.getUser(principals[2]);
      assert(user.convictions.to_update);
      user := users.updateConvictions(principals[2], questions);
      assert(not user.convictions.to_update);
      tests.add(test(
        "User 2 convictions",
        Utils.arrayToTrie(user.convictions.array, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      

      // @todo: need to have a more complete test on categorization computation

      suite("Test Users module", tests.toArray());
    };
  };

};