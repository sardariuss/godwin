import Types "../../src/godwin_backend/types";
import Questions "../../src/godwin_backend/questions/questions";
import Scheduler "../../src/godwin_backend/scheduler";
import Categories "../../src/godwin_backend/categories";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Option "mo:base/Option";

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
  
  public class TestScheduler() = {

    var questions_ = Questions.empty();

    var on_closing_called_ : Bool = false;

    func onClosingQuestion(question: Question) {
      on_closing_called_ := true;
    };

    func resetOnClosing() : Bool {
      let to_return = on_closing_called_;
      on_closing_called_ := false;
      to_return;
    };

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

    func updateQuestions(update: (Questions, ?Question)) : ?Question {
      Option.iterate(update.1, func(question: Question) {
        questions_ := Questions.replaceQuestion(update.0, question);
      });
      update.1;
    };

    public func getSuite() : Suite.Suite {
      
      let categories = Categories.fromArray([]);
      
      // Add the questions
      for (index in Array.keys(question_inputs_)){
        let question = question_inputs_[index];
        questions_ := Questions.createQuestion(questions_, question.author, question.date, question.title, question.text).0;
      };

      // Set a specific total of interests for each question
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 0) with status = #CANDIDATE({ date = 493; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 10; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 1) with status = #CANDIDATE({ date = 243; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 2; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 2) with status = #CANDIDATE({ date = 432; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 75; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 3) with status = #CANDIDATE({ date = 123; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 93; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 4) with status = #CANDIDATE({ date = 312; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 12; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 5) with status = #CANDIDATE({ date = 132; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 38; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 6) with status = #CANDIDATE({ date = 213; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 91; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 7) with status = #CANDIDATE({ date = 532; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 73; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 8) with status = #CANDIDATE({ date = 711; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 61; } }) });
      questions_ := Questions.replaceQuestion(questions_, { Questions.getQuestion(questions_, 9) with status = #CANDIDATE({ date = 102; ballots = Trie.empty<Principal, Interest>(); aggregate = {ups = 0; downs = 0; score = 31; } }) });

      let scheduler_params : SchedulerParams = {
        selection_rate = #NS(150);
        interest_duration = #NS(300);
        opinion_duration = #NS(300);
        categorization_duration = #NS(500);
      };

      let scheduler = Scheduler.Scheduler({
        params = scheduler_params;
        last_selection_date = 1000;
      }, onClosingQuestion);

      // 1.1 Select a first question
      var question = updateQuestions(scheduler.openOpinionVote(questions_, 900));
      assert(question == null);
      question := updateQuestions(scheduler.openOpinionVote(questions_, 1100));
      assert(question == null);
      question := updateQuestions(scheduler.openOpinionVote(questions_, 1200));
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 3); };
      };

      // 1.2 Select a second question
      question := updateQuestions(scheduler.openOpinionVote(questions_, 1300));
      assert(question == null);
      question := updateQuestions(scheduler.openOpinionVote(questions_, 1400));
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 6); };
      };

      // 1.3 Select a third question
      question := updateQuestions(scheduler.openOpinionVote(questions_, 1450));
      assert(question == null);
      question := updateQuestions(scheduler.openOpinionVote(questions_, 2000));
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 2); };
      };

      // 1.4 Select a fourth question
      question := updateQuestions(scheduler.openOpinionVote(questions_, 2200));
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 7); };
      };

      // 1.5 Select a fifth question
      question := updateQuestions(scheduler.openOpinionVote(questions_, 2400));
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 8); };
      };

      // 5 questions have been selected at timestamp: 1200, 1400, 2000, 2200, 2400
      // and selection duration is 300.

      // 2.1 Archive a first question
      question := updateQuestions(scheduler.openCategorizationVote(questions_, 900, Categories.toArray(categories)));
      assert(question == null);
      question := updateQuestions(scheduler.openCategorizationVote(questions_, 1300, Categories.toArray(categories)));
      assert(question == null);
      question := updateQuestions(scheduler.openCategorizationVote(questions_, 1501, Categories.toArray(categories)));
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 3); };
      };

      // 2.2 Archive a second question
      question := updateQuestions(scheduler.openCategorizationVote(questions_, 1600, Categories.toArray(categories)));
      assert(question == null);
      question := updateQuestions(scheduler.openCategorizationVote(questions_, 1750, Categories.toArray(categories)));
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 6); };
      };
      
      // 2.3 Archive a third question
      question := updateQuestions(scheduler.openCategorizationVote(questions_, 2400, Categories.toArray(categories)));
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 2); };
      };

      // 3 questions have been archived at timestamp: 1501, 1750, 2400
      // and categorization duration is 500.

      // 3.1 Close categorization of a first question
      question := updateQuestions(scheduler.closeQuestion(questions_, 1501));
      assert(not resetOnClosing());
      assert(question == null);
      question := updateQuestions(scheduler.closeQuestion(questions_, 1900));
      assert(not resetOnClosing());
      assert(question == null);
      question := updateQuestions(scheduler.closeQuestion(questions_, 2050));
      assert(resetOnClosing());
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 3); };
      };

      // 3.2 Close categorization of a second question
      question := updateQuestions(scheduler.closeQuestion(questions_, 2200));
      assert(not resetOnClosing());
      assert(question == null);
      question := updateQuestions(scheduler.closeQuestion(questions_, 2260));
      assert(resetOnClosing());
      switch(question){
        case(null) { assert(false); };
        case(?question) { assert(question.id == 6); };
      };
      
      suite("Test Scheduler module", []);
    };
  };

};