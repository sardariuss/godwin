import Types "../../src/godwin_backend/types";
import Questions "../../src/godwin_backend/questions/questions";
import Queries "../../src/godwin_backend/questions/queries";
import Scheduler "../../src/godwin_backend/scheduler";
import Users "../../src/godwin_backend/users";
import Categories "../../src/godwin_backend/categories";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Trie<K, V> = Trie.Trie<K, V>;
  // For convenience: from matchers module
  let { run;test;suite; } = Suite;
  // For convenience: from types module
  type Question = Types.Question;
  type Category = Types.Category;
  type SchedulerParams = Types.SchedulerParams;
  type Interest = Types.Interest;
  // For convenience: from other modules
  type Questions = Questions.Register;
  
  // @todo: This test is too complex to follow through, it needs to be simplified
  // @todo: Needs to test that the convictions are updated
  public class TestScheduler() = {

    let questions_ = Questions.Questions(Questions.initRegister());
    let users_ = Users.Users(Users.initRegister());
    let queries_ = Queries.Queries(Queries.initRegister());

    // Add observers to sync queries
    questions_.addObs(#QUESTION_ADDED, queries_.add);
    questions_.addObs(#QUESTION_REMOVED, queries_.remove);

    let question_inputs_ = [
      { date = 493; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Sexual orientation is a social construct";   text = ""; },
      { date = 243; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Borders should eventually be abolished.";    text = ""; },
      { date = 432; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "A good citizen is a patriot.";               text = ""; },
      { date = 123; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "The labor market enslaves workers.";         text = ""; },
      { date = 312; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "We should be retiring earlier.";             text = ""; },
      { date = 132; author = Principal.fromText("lejdd-efwn5-h3qqe-4bunw-faabt-qwb7j-oiskz-c3dkg-3q5z5-ozrtn-dqe"); title = "Marriage should be abolished.";              text = ""; },
      { date = 213; author = Principal.fromText("amerw-mz3nq-gfkbp-o3qgo-zldsl-upilh-zatjw-66nkr-527cf-m7hnq-pae"); title = "Euthanasia should be authorized.";           text = ""; },
      { date = 532; author = Principal.fromText("gbvlf-igtmq-g5vs2-skrhr-txgij-4f2j3-v2jqy-re5cm-i6hsu-gpzcd-aae"); title = "We must fight against global warming.";      text = ""; },
      { date = 711; author = Principal.fromText("mrdr7-aufxf-oiq6j-hyib2-rxb5m-cqrnb-uzgyq-durnt-75u4x-rrvow-iae"); title = "Exploitation of fossil fuels is necessary."; text = ""; },
      { date = 102; author = Principal.fromText("zoyw4-o2dcy-xajcf-e2nvu-436rg-ghrbs-35bzk-nakpb-mvs7t-x4byt-nqe"); title = "The police should be armed.";                text = ""; },
    ];

    func updateOptQuestions(opt_question: ?Question) : ?Question {
      Option.iterate(opt_question, func(question: Question) {
        questions_.replaceQuestion(question);
      });
      opt_question
    };

    public func getSuite() : Suite.Suite {
      
      let categories = Categories.fromArray([]);
      
      // Add the questions
      for (index in Array.keys(question_inputs_)){
        let question = question_inputs_[index];
        ignore questions_.createQuestion(question.author, question.date, question.title, question.text);
      };

      // Set a specific total of interests for each question
      questions_.replaceQuestion({ questions_.getQuestion(0) with status = #CANDIDATE({ date = 493; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 10; } }) });
      questions_.replaceQuestion({ questions_.getQuestion(1) with status = #CANDIDATE({ date = 243; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 2;  } }) });
      questions_.replaceQuestion({ questions_.getQuestion(2) with status = #CANDIDATE({ date = 432; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 75; } }) });
      questions_.replaceQuestion({ questions_.getQuestion(3) with status = #CANDIDATE({ date = 123; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 93; } }) });
      questions_.replaceQuestion({ questions_.getQuestion(4) with status = #CANDIDATE({ date = 312; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 12; } }) });
      questions_.replaceQuestion({ questions_.getQuestion(5) with status = #CANDIDATE({ date = 132; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 38; } }) });
      questions_.replaceQuestion({ questions_.getQuestion(6) with status = #CANDIDATE({ date = 213; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 91; } }) });
      questions_.replaceQuestion({ questions_.getQuestion(7) with status = #CANDIDATE({ date = 532; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 73; } }) });
      questions_.replaceQuestion({ questions_.getQuestion(8) with status = #CANDIDATE({ date = 711; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 61; } }) });
      questions_.replaceQuestion({ questions_.getQuestion(9) with status = #CANDIDATE({ date = 102; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 31; } }) });

      let scheduler_params : SchedulerParams = {
        selection_rate          = #NS(150);
        interest_duration       = #NS(500);
        opinion_duration        = #NS(300);
        categorization_duration = #NS(500);
        rejected_duration       = #NS(400);
      };

      let scheduler = Scheduler.Scheduler(Scheduler.initRegister(scheduler_params, 1000), questions_, users_, queries_, null);

      // 1.1 Select a first question
      assert(updateOptQuestions(scheduler.openOpinionVote(900)) == null);
      assert(updateOptQuestions(scheduler.openOpinionVote(1100)) == null);
      switch(updateOptQuestions(scheduler.openOpinionVote(1200))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 3); };
      };

      // 1.2 Select a second question
      assert(updateOptQuestions(scheduler.openOpinionVote(1300)) == null);
      switch(updateOptQuestions(scheduler.openOpinionVote(1400))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 6); };
      };

      // 1.3 Select a third question
      assert(updateOptQuestions(scheduler.openOpinionVote(1450)) == null);
      switch(updateOptQuestions(scheduler.openOpinionVote(2000))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 2); };
      };

      // 1.4 Select a fourth question
      switch(updateOptQuestions(scheduler.openOpinionVote(2200))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 7); };
      };

      // 1.5 Select a fifth question
      switch(updateOptQuestions(scheduler.openOpinionVote(2400))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 8); };
      };

      // 2.1 Reject some questions
      let rejected_questions_1 = scheduler.rejectQuestions(700);

      assert(rejected_questions_1[0].id == 9);
      assert(rejected_questions_1[1].id == 5);

      // 2.2 Reject additional questions
      let rejected_questions_2 = scheduler.rejectQuestions(1200);
      assert(rejected_questions_2[0].id == 1);
      assert(rejected_questions_2[1].id == 4);
      assert(rejected_questions_2[2].id == 0);

      // 3.1. Delete rejected questions (1)
      let delete_questions_1 = scheduler.deleteQuestions(1150);
      assert(delete_questions_1.size() == 2);

      // 3.2 Delete rejected questions (2)
      let delete_questions_2 = scheduler.deleteQuestions(1400);
      assert(delete_questions_2.size() == 0);

      // 3.3 Delete rejected questions (3)
      let delete_questions_3 = scheduler.deleteQuestions(1800);
      assert(delete_questions_3.size() == 3);

      // 5 questions have been selected at timestamp: 1200, 1400, 2000, 2200, 2400
      // and selection duration is 300.

      // 4.1 Archive a first question
      assert(updateOptQuestions(scheduler.openCategorizationVote(900, Categories.toArray(categories))) == null);
      assert(updateOptQuestions(scheduler.openCategorizationVote(1300, Categories.toArray(categories))) == null);
      switch(updateOptQuestions(scheduler.openCategorizationVote(1501, Categories.toArray(categories)))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 3); };
      };

      // 4.2 Archive a second question
      assert(updateOptQuestions(scheduler.openCategorizationVote(1600, Categories.toArray(categories))) == null);
      switch(updateOptQuestions(scheduler.openCategorizationVote(1750, Categories.toArray(categories)))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 6); };
      };
      
      // 4.3 Archive a third question
      switch(updateOptQuestions(scheduler.openCategorizationVote(2400, Categories.toArray(categories)))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 2); };
      };

      // 3 questions have been archived at timestamp: 1501, 1750, 2400
      // and categorization duration is 500.

      // 5.1 Close categorization of a first question
      assert(updateOptQuestions(scheduler.closeQuestion(1501)) == null);
      assert(updateOptQuestions(scheduler.closeQuestion(1900)) == null);
      switch(updateOptQuestions(scheduler.closeQuestion(2050))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 3); };
      };

      // 5.2 Close categorization of a second question
      assert(updateOptQuestions(scheduler.closeQuestion(2200)) == null);
      switch(updateOptQuestions(scheduler.closeQuestion(2260))){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 6); };
      };
      
      suite("Test Scheduler module", []);
    };
  };

};