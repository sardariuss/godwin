import Types "../../src/godwin_backend/types";
import Users "../../src/godwin_backend/users";
import Polarization "../../src/godwin_backend/representation/polarization";
import Questions "../../src/godwin_backend/questions/questions";
import Question "../../src/godwin_backend/questions/question";
import Categories "../../src/godwin_backend/categories";
import Utils "../../src/godwin_backend/utils";
import TestableItems "testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types module
  type Question = Types.Question;
  // For convenience: from other modules
  type Users = Users.Register;
  
  public class TestUsers() = {

    public func getSuite() : Suite.Suite {

      let tests = Buffer.Buffer<Suite.Suite>(0);

      let principals = [
        Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"),
        Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"),
        Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe")
      ];

      let categories = Categories.fromArray(["IDENTITY", "ECONOMY", "CULTURE"]);

      var users = Users.empty();

      var questions = Questions.empty();
      questions := Questions.createQuestion(questions, principals[0], 0, "Sexual orientation is a social construct", "").0;
      questions := Questions.replaceQuestion(questions, Question.openOpinionVote(Questions.getQuestion(questions, 0), 0, 0));

      // Create the users
      for (principal in Array.vals(principals)){
        let (updated_users, user) = Users.getOrCreateUser(users, principal, Categories.toArray(categories)); 
        users := updated_users;
        assert(user.principal == principal);
        assert(user.name == null);
        for ((_, conviction) in Trie.iter(user.convictions)){
          assert(Polarization.isNil(conviction));
        };
      };

      // Find the users
      for (principal in Array.vals(principals)){
        switch(Users.findUser(users, principal)){
          case(null) { assert(false); };
          case(?user) { 
            assert(user.principal == principal);
            assert(user.name == null);
            for ((_, conviction) in Trie.iter(user.convictions)){
              assert(Polarization.isNil(conviction));
            };
          };
        };
      };

      // Users 0 and 1 give their opinions
      Result.iterate(Question.putOpinion(Questions.getQuestion(questions, 0), principals[0], 0.0), func(question: Question) {
        questions := Questions.replaceQuestion(questions, question);
      });
      
      Result.iterate(Question.putOpinion(Questions.getQuestion(questions, 0), principals[1], 1.0), func(question: Question) {
        questions := Questions.replaceQuestion(questions, question);
      });

      // Categorize the question
      var iteration = Question.unwrapIteration(Questions.getQuestion(questions, 0));
      var categorization = iteration.categorization;
      categorization := { categorization with aggregate = Utils.arrayToTrie([
            ("IDENTITY", {left = 0.0; center = 0.0; right = 1.0;}),
            ("ECONOMY",  {left = 0.0; center = 0.5; right = 0.5;}),
            ("CULTURE",  {left = 0.0; center = 1.0; right = 0.0;})
          ], Types.keyText, Text.equal); };
      iteration := { iteration with categorization; };
      questions := Questions.replaceQuestion(questions, { Questions.getQuestion(questions, 0) with status = #OPEN({ stage = #CATEGORIZATION; iteration;}) });

      users := Users.updateConvictions(users, iteration, [], null);

      // Verify the convictions shall be updated for users who answered this question
      // User 0
      tests.add(test(
        "User 0 convictions",
        Users.getUser(users, principals[0]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.5; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 1
      tests.add(test(
        "User 1 convictions",
        Users.getUser(users, principals[1]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.5; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 2
      tests.add(test(
        "User 1 convictions",
        Users.getUser(users, principals[2]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 0.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));

      // Test adding a new category
      users := Users.addCategory(users, "JUSTICE");
      // User 0
      tests.add(test(
        "User 0 convictions",
        Users.getUser(users, principals[0]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.5; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 1
      tests.add(test(
        "User 1 convictions",
        Users.getUser(users, principals[1]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.5; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 2
      tests.add(test(
        "User 2 convictions",
        Users.getUser(users, principals[2]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 0.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));

      // Test removing an old category
      users := Users.removeCategory(users, "ECONOMY");
      // User 0
      tests.add(test(
        "User 0 convictions",
        Users.getUser(users, principals[0]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 1
      tests.add(test(
        "User 1 convictions",
        Users.getUser(users, principals[1]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      // User 2
      tests.add(test(
        "User 2 convictions",
        Users.getUser(users, principals[2]).convictions,
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      

      // @todo: need to have a more complete test on categorization computation
      // @todo: have a test for the user name

      suite("Test Users module", tests.toArray());
    };
  };

};