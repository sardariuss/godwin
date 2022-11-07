import Types "../../src/godwin_backend/types";
import Users "../../src/godwin_backend/users";
import Questions "../../src/godwin_backend/questions/questions";
import StageHistory "../../src/godwin_backend/stageHistory";
import Opinions "../../src/godwin_backend/votes/opinions";
import Categorizations "../../src/godwin_backend/votes/categorizations";
import CategoryPolarizationTrie "../../src/godwin_backend/representation/categoryPolarizationTrie";
import Utils "../../src/godwin_backend/utils";
import TestableItems "testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";
import Testable "mo:matchers/Testable";

import Principal "mo:base/Principal";
import Text "mo:base/Text";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";

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

      let categories = TrieSet.fromArray(["IDENTITY", "ECONOMY", "CULTURE"], Text.hash, Text.equal);

      let users = Users.empty();

      let questions = Questions.empty();
      let question = questions.createQuestion(principals[0], 0, "Sexual orientation is a social construct", "");

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
            assert(user.convictions.categorization.size() == 0);
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
            assert(user.convictions.categorization.size() == 0);
          };
        };
      };

      // Update the convictions before having any opinion
      for (principal in Array.vals(principals)){
        switch(users.findUser(principal)){
          case(null) { assert(false); };
          case(?user) { 
            users.updateConvictions(user, questions, Opinions.empty());
          };
        };
      };

      // Verify the convictions have been updated
      for (principal in Array.vals(principals)){
        switch(users.findUser(principal)){
          case(null) { assert(false); };
          case(?user) {
            assert(not user.convictions.to_update);
            // The convictions are still empty because no opinion has been given
            assert(user.convictions.categorization.size() == 0);
          };
        };
      };

      // Users 0 and 1 give their opinions
      let opinions = Opinions.empty();
      opinions.put(principals[0], question.id, 0.0);
      opinions.put(principals[1], question.id, 1.0);

      // Update the question categorization stage to done with an arbitrate categorization
      questions.replaceQuestion({
        id = question.id;
        author = question.author;
        title = question.title;
        text = question.text;
        date = question.date;
        endorsements = question.endorsements;
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
      users.pruneConvictions(opinions, question.id);

      // Verify the convictions shall be updated for users who answered this question
      var user = users.getUser(principals[0]);
      assert(user.convictions.to_update);
      user := users.getUser(principals[1]);
      assert(user.convictions.to_update);
      user := users.getUser(principals[2]);
      assert(not user.convictions.to_update);

      // Update the convictions
      user := users.getUser(principals[0]);
      users.updateConvictions(user, questions, opinions);
      user := users.getUser(principals[0]);
      tests.add(test(
        "Convictions after update",
        Utils.arrayToTrie(user.convictions.categorization, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 1.0; right = 0.0; }),
          ("ECONOMY",  { left = 0.0; center = 1.0; right = 0.0; }),
          ("CULTURE",  { left = 0.0; center = 1.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      user := users.getUser(principals[1]);
      users.updateConvictions(user, questions, opinions);
      user := users.getUser(principals[1]);
      tests.add(test(
        "Convictions after update",
        Utils.arrayToTrie(user.convictions.categorization, Types.keyText, Text.equal),
        Matchers.equals(TestableItems.categoryPolarizationTrie(Utils.arrayToTrie([
          ("IDENTITY", { left = 0.0; center = 0.0; right = 1.0; }),
          ("ECONOMY",  { left = 0.0; center = 0.0; right = 1.0; }),
          ("CULTURE",  { left = 0.0; center = 1.0; right = 0.0; })
        ], Types.keyText, Text.equal)))));
      user := users.getUser(principals[2]);
      users.updateConvictions(user, questions, opinions);
      user := users.getUser(principals[2]);
      assert(user.convictions.categorization.size() == 0);

      // @todo: need to have a more complete test on categorization computation

      suite("Test Users module", tests.toArray());
    };
  };

};