import Types "../../../src/godwin_backend/Types";
import Questions "../../../src/godwin_backend/questions/Questions";
import Queries "../../../src/godwin_backend/questions/queries";
import Iteration "../../../src/godwin_backend/votes/iteration";
import Observers "../../../src/godwin_backend/Observers";
import TestableItems "../testableItems";

import Map "mo:map/Map";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Trie "mo:base/Trie";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  
  public class TestQuestions() = {

    let array_originals_ : [Question] = [
      { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Sexual orientation is a social construct";   text = ""; date = 8493; status = #INTEREST({ date = 8493; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Borders should eventually be abolished.";    text = ""; date = 8493; status = #INTEREST({ date = 8493; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "A good citizen is a patriot.";               text = ""; date = 2432; status = #INTEREST({ date = 2432; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "The labor market enslaves workers.";         text = ""; date = 5123; status = #INTEREST({ date = 5123; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "We should be retiring earlier.";             text = ""; date = 3132; status = #INTEREST({ date = 3132; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 5; author = Principal.fromText("lejdd-efwn5-h3qqe-4bunw-faabt-qwb7j-oiskz-c3dkg-3q5z5-ozrtn-dqe"); title = "Marriage should be abolished.";              text = ""; date = 3132; status = #INTEREST({ date = 3132; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 6; author = Principal.fromText("amerw-mz3nq-gfkbp-o3qgo-zldsl-upilh-zatjw-66nkr-527cf-m7hnq-pae"); title = "Euthanasia should be authorized.";           text = ""; date = 4213; status = #INTEREST({ date = 4213; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 7; author = Principal.fromText("gbvlf-igtmq-g5vs2-skrhr-txgij-4f2j3-v2jqy-re5cm-i6hsu-gpzcd-aae"); title = "We must fight against global warming.";      text = ""; date = 4213; status = #INTEREST({ date = 4213; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 8; author = Principal.fromText("mrdr7-aufxf-oiq6j-hyib2-rxb5m-cqrnb-uzgyq-durnt-75u4x-rrvow-iae"); title = "Exploitation of fossil fuels is necessary."; text = ""; date = 9711; status = #INTEREST({ date = 9711; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
      { id = 9; author = Principal.fromText("zoyw4-o2dcy-xajcf-e2nvu-436rg-ghrbs-35bzk-nakpb-mvs7t-x4byt-nqe"); title = "The police should be armed.";                text = ""; date = 9711; status = #INTEREST({ date = 9711; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 0; }; }); interests_history = []; vote_history = []; },
    ];

    let array_modified_ : [Question] = [
      { id = 0; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Sexual orientation is a social construct";   text = ""; date = 8493; status = #INTEREST({ date = 8493; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 13; }; }); interests_history = []; vote_history = []; },
      { id = 1; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Borders should eventually be abolished.";    text = ""; date = 6286; status = #INTEREST({ date = 6286; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 12; }; }); interests_history = []; vote_history = []; },
      { id = 2; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "A good citizen is a patriot.";               text = ""; date = 2432; status = #OPEN( { stage = #CATEGORIZATION; iteration = Iteration.openCategorization(Iteration.new(0), 2432, []) });                  interests_history = []; vote_history = []; },
      { id = 3; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "The labor market enslaves workers.";         text = ""; date = 1321; status = #OPEN( { stage = #CATEGORIZATION; iteration = Iteration.openCategorization(Iteration.new(0), 1321, []) });                  interests_history = []; vote_history = []; },
      { id = 4; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "We should be retiring earlier.";             text = ""; date = 7234; status = #OPEN( { stage = #OPINION; iteration = Iteration.new(7234); });                                                             interests_history = []; vote_history = []; },
      { id = 5; author = Principal.fromText("lejdd-efwn5-h3qqe-4bunw-faabt-qwb7j-oiskz-c3dkg-3q5z5-ozrtn-dqe"); title = "Marriage should be abolished.";              text = ""; date = 3132; status = #OPEN( { stage = #OPINION; iteration = Iteration.new(3132); });                                                             interests_history = []; vote_history = []; },
      { id = 6; author = Principal.fromText("amerw-mz3nq-gfkbp-o3qgo-zldsl-upilh-zatjw-66nkr-527cf-m7hnq-pae"); title = "Euthanasia should be authorized.";           text = ""; date = 4213; status = #INTEREST({ date = 4213; ballots = Trie.empty<Principal, Interest>(); aggregate = { ups = 0; downs = 0; score = 75; }; }); interests_history = []; vote_history = []; },
      { id = 7; author = Principal.fromText("gbvlf-igtmq-g5vs2-skrhr-txgij-4f2j3-v2jqy-re5cm-i6hsu-gpzcd-aae"); title = "We must fight against global warming.";      text = ""; date = 3421; status = #OPEN( { stage = #CATEGORIZATION; iteration = Iteration.openCategorization(Iteration.new(0), 4213, []) });                  interests_history = []; vote_history = []; },
      { id = 8; author = Principal.fromText("mrdr7-aufxf-oiq6j-hyib2-rxb5m-cqrnb-uzgyq-durnt-75u4x-rrvow-iae"); title = "Exploitation of fossil fuels is necessary."; text = ""; date = 5431; status = #OPEN( { stage = #OPINION; iteration = Iteration.new(5431); });                                                             interests_history = []; vote_history = []; },
      { id = 9; author = Principal.fromText("zoyw4-o2dcy-xajcf-e2nvu-436rg-ghrbs-35bzk-nakpb-mvs7t-x4byt-nqe"); title = "The police should be armed.";                text = ""; date = 9711; status = #OPEN( { stage = #OPINION; iteration = Iteration.new(9711); });                                                             interests_history = []; vote_history = []; },
    ];

    public func getSuite() : Suite.Suite {

      let tests = Buffer.Buffer<Suite.Suite>(array_originals_.size() * 4);
      
      let questions = Questions.build(Map.new<Nat, Question>(), { var v : Nat = 0; });

      let queries = Queries.build(Queries.initRegister());

      // Add observers to sync queries
      questions.addObs(#QUESTION_ADDED, queries.add);
      questions.addObs(#QUESTION_REMOVED, queries.remove);
      
      // Test that created questions are equal to original questions
      for (index in Array.keys(array_originals_)){
        let original = array_originals_[index];
        let new_question = questions.createQuestion(original.author, original.date, original.title, original.text);
        tests.add(test(
          "Create question " # Nat.toText(index), ?original, Matchers.equals(TestableItems.optQuestion(?new_question))));
      };
      
      // Test replacing the questions
      for (index in Array.keys(array_modified_)){
        questions.replaceQuestion(array_modified_[index]);
        tests.add(test(
          "Replace question " # Nat.toText(index),
          questions.findQuestion(index),
          Matchers.equals(TestableItems.optQuestion(?array_modified_[index]))));
      };
      
      // Test iterating on selection stage
      let iter_interest = queries.entries(#STATUS_DATE(#INTEREST), #fwd);
      tests.add(test("Iter on interest question (1)", questions.next(iter_interest), Matchers.equals(TestableItems.optQuestion(?array_modified_[6]))));
      tests.add(test("Iter on interest question (2)", questions.next(iter_interest), Matchers.equals(TestableItems.optQuestion(?array_modified_[1]))));
      tests.add(test("Iter on interest question (3)", questions.next(iter_interest), Matchers.equals(TestableItems.optQuestion(?array_modified_[0]))));
      // @todo: fix this
      //tests.add(test("Iter on interest question (4)", questions.next(iter_interest), Matchers.equals(TestableItems.optQuestion(null))));

      let iter_opinion = queries.entries(#STATUS_DATE(#OPEN(#OPINION)), #fwd);
      tests.add(test("Iter on opinioned question (1)", questions.next(iter_opinion), Matchers.equals(TestableItems.optQuestion(?array_modified_[5]))));
      tests.add(test("Iter on opinioned question (2)", questions.next(iter_opinion), Matchers.equals(TestableItems.optQuestion(?array_modified_[8]))));
      tests.add(test("Iter on opinioned question (3)", questions.next(iter_opinion), Matchers.equals(TestableItems.optQuestion(?array_modified_[4]))));
      tests.add(test("Iter on opinioned question (4)", questions.next(iter_opinion), Matchers.equals(TestableItems.optQuestion(?array_modified_[9]))));
      tests.add(test("Iter on opinioned question (5)", questions.next(iter_opinion), Matchers.equals(TestableItems.optQuestion(null))));

      let iter_categorization = queries.entries(#STATUS_DATE(#OPEN(#CATEGORIZATION)), #fwd);
      tests.add(test("Iter on categorized question (1)", questions.next(iter_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[3]))));
      tests.add(test("Iter on categorized question (2)", questions.next(iter_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[2]))));
      tests.add(test("Iter on categorized question (3)", questions.next(iter_categorization), Matchers.equals(TestableItems.optQuestion(?array_modified_[7]))));
      tests.add(test("Iter on categorized question (4)", questions.next(iter_categorization), Matchers.equals(TestableItems.optQuestion(null))));

      suite("Test Questions module", Buffer.toArray(tests));
    };
  };

};