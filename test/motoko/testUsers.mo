import Types "../../src/godwin_backend/model/Types";
import Users "../../src/godwin_backend/model/Users";
import Polarization "../../src/godwin_backend/representation/Polarization";
import Questions "../../src/godwin_backend/Questions";
import Question "../../src/godwin_backend/questions/question";
import Utils "../../src/godwin_backend/utils/Utils";
import TestableItems "testableItems";

import Map "mo:map/Map";
import Set "mo:map/Set";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types module
  type Question = Types.Question;
  type User = Types.User;
  
  public class TestUsers() = {

    public func getSuite() : Suite.Suite {

      let tests = Buffer.Buffer<Suite.Suite>(0);

      let principals = [
        Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"),
        Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"),
        Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe")
      ];

      let categories = Set.new<Text>();
      Set.add(categories, Set.thash, "IDENTITY");
      Set.add(categories, Set.thash, "ECONOMY");
      Set.add(categories, Set.thash, "CULTURE");

      let users = Users.build(Map.new<Principal, User>(), null);

      let questions = Questions.build(Map.new<Nat, Question>(), { var v : Nat = 0; });
      ignore questions.createQuestion(principals[0], 0, "Sexual orientation is a social construct", "");
      questions.replaceQuestion(Question.openOpinionVote(questions.getQuestion(0), 0));

      // Create the users
      for (principal in Array.vals(principals)){
        let user = users.getOrCreateUser(principal, Iter.toArray(Set.keys(categories))); 
        assert(user.principal == principal);
        assert(user.name == null);
        for ((_, conviction) in Trie.iter(user.convictions)){
          assert(Polarization.isNil(conviction));
        };
      };

      // Find the users
      for (principal in Array.vals(principals)){
        switch(users.findUser(principal)){
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

  // @todo: reactivate the tests

//      // Users 0 and 1 give their opinions
//      Result.iterate(Question.putOpinion(questions.getQuestion(0), principals[0], 0.0), func(question: Question) {
//        questions.replaceQuestion(question);
//      });
//      
//      Result.iterate(Question.putOpinion(questions.getQuestion(0), principals[1], 1.0), func(question: Question) {
//        questions.replaceQuestion(question);
//      });
//
//      // Categorize the question
//      var iteration = Question.unwrapIteration(questions.getQuestion(0));
//      var categorization = iteration.categorization;
//      categorization := { categorization with aggregate = Utils.arrayToTrie([
//            ("IDENTITY", {left = 0.0; center = 0.0; right = 1.0;}),
//            ("ECONOMY",  {left = 0.0; center = 0.5; right = 0.5;}),
//            ("CULTURE",  {left = 0.0; center = 1.0; right = 0.0;})
//          ], Categories.key, Categories.equal); };
//      iteration := { iteration with categorization; };
//      questions.replaceQuestion({ questions.getQuestion(0) with status = #VOTING({ stage = #CATEGORIZATION; iteration;}) });
//
//      users.updateConvictions(iteration, [], null);
//
//      // Verify the convictions shall be updated for users who answered this question
//      // User 0
//      tests.add(test(
//        "User 0 convictions",
//        users.getUser(principals[0]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
//          ("ECONOMY",  { left = 0.0; center = 0.5; right = 0.0; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//      // User 1
//      tests.add(test(
//        "User 1 convictions",
//        users.getUser(principals[1]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
//          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.5; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//      // User 2
//      tests.add(test(
//        "User 1 convictions",
//        users.getUser(principals[2]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 0.0; right = 0.0; }),
//          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.0; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//
//      // Test adding a new category
//      users.addCategory("JUSTICE");
//      // User 0
//      tests.add(test(
//        "User 0 convictions",
//        users.getUser(principals[0]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
//          ("ECONOMY",  { left = 0.0; center = 0.5; right = 0.0; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
//          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//      // User 1
//      tests.add(test(
//        "User 1 convictions",
//        users.getUser(principals[1]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
//          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.5; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
//          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//      // User 2
//      tests.add(test(
//        "User 2 convictions",
//        users.getUser(principals[2]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 0.0; right = 0.0; }),
//          ("ECONOMY",  { left = 0.0; center = 0.0; right = 0.0; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
//          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//
//      // Test removing an old category
//      users.removeCategory("ECONOMY");
//      // User 0
//      tests.add(test(
//        "User 0 convictions",
//        users.getUser(principals[0]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
//          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//      // User 1
//      tests.add(test(
//        "User 1 convictions",
//        users.getUser(principals[1]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
//          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//      // User 2
//      tests.add(test(
//        "User 2 convictions",
//        users.getUser(principals[2]).convictions,
//        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
//          ("IDENTITY", { left = 0.0; center = 0.0; right = 0.0; }),
//          ("CULTURE",  { left = 0.0; center = 0.0; right = 0.0; }),
//          ("JUSTICE",  { left = 0.0; center = 0.0; right = 0.0; })
//        ], Categories.key, Categories.equal)))));
//      

      // @todo: need to have a more complete test on categorization computation
      // @todo: have a test for the user name

      suite("Test Users module", Buffer.toArray(tests));
    };
  };

};