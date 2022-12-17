module {};

//import Types "../../src/godwin_backend/types";
//import Questions "../../src/godwin_backend/questions/questions";
//import Question "../../src/godwin_backend/questions/question";
//import Scheduler "../../src/godwin_backend/scheduler";
//import Users "../../src/godwin_backend/users";
//import Opinions "../../src/godwin_backend/votes/opinions";
//import Categorizations "../../src/godwin_backend/votes/categorizations";
//import Categories "../../src/godwin_backend/categories";
//
//import Matchers "mo:matchers/Matchers";
//import Suite "mo:matchers/Suite";
//
//import Principal "mo:base/Principal";
//import Array "mo:base/Array";
//
//module {
//
//  // For convenience: from base module
//  type Principal = Principal.Principal;
//  // For convenience: from matchers module
//  let { run;test;suite; } = Suite;
//  // For convenience: from types module
//  type Question = Types.Question;
//  type Category = Types.Category;
//  type SchedulerParams = Types.SchedulerParams;
//  // For convenience: from other modules
//  type Questions = Questions.Questions;
//  
//  public class TestScheduler() = {
//
//    let question_inputs_ = [
//      { date = 493; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Sexual orientation is a social construct";   text = ""; },
//      { date = 243; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Borders should eventually be abolished.";    text = ""; },
//      { date = 432; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "A good citizen is a patriot.";               text = ""; },
//      { date = 123; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "The labor market enslaves workers.";         text = ""; },
//      { date = 312; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "We should be retiring earlier.";             text = ""; },
//      { date = 132; author = Principal.fromText("lejdd-efwn5-h3qqe-4bunw-faabt-qwb7j-oiskz-c3dkg-3q5z5-ozrtn-dqe"); title = "Marriage should be abolished.";              text = ""; },
//      { date = 213; author = Principal.fromText("amerw-mz3nq-gfkbp-o3qgo-zldsl-upilh-zatjw-66nkr-527cf-m7hnq-pae"); title = "Euthanasia should be authorized.";           text = ""; },
//      { date = 532; author = Principal.fromText("gbvlf-igtmq-g5vs2-skrhr-txgij-4f2j3-v2jqy-re5cm-i6hsu-gpzcd-aae"); title = "We must fight against global warming.";      text = ""; },
//      { date = 711; author = Principal.fromText("mrdr7-aufxf-oiq6j-hyib2-rxb5m-cqrnb-uzgyq-durnt-75u4x-rrvow-iae"); title = "Exploitation of fossil fuels is necessary."; text = ""; },
//      { date = 102; author = Principal.fromText("zoyw4-o2dcy-xajcf-e2nvu-436rg-ghrbs-35bzk-nakpb-mvs7t-x4byt-nqe"); title = "The police should be armed.";                text = ""; },
//    ];
//
//    public func getSuite() : Suite.Suite {
//      
//      let categories = Categories.Categories([]);
//      let users = Users.empty(categories);
//      let opinions = Opinions.empty();
//      let categorizations = Categorizations.empty(categories);
//      let questions = Questions.empty();
//      
//      // Add some questions
//      for (index in Array.keys(question_inputs_)){
//        let question = question_inputs_[index];
//        ignore questions.createQuestion(question.author, question.date, question.title, question.text);
//      };
//      // Set a specific total of interests for each question
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(0), {ups = 0; downs = 0; score = 10; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(1), {ups = 0; downs = 0; score = 2; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(2), {ups = 0; downs = 0; score = 75; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(3), {ups = 0; downs = 0; score = 93; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(4), {ups = 0; downs = 0; score = 12; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(5), {ups = 0; downs = 0; score = 38; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(6), {ups = 0; downs = 0; score = 91; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(7), {ups = 0; downs = 0; score = 73; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(8), {ups = 0; downs = 0; score = 61; }));
//      questions.replaceQuestion(Question.updateTotalInterests(questions.getQuestion(9), {ups = 0; downs = 0; score = 31; }));
//
//      let scheduler_params : SchedulerParams = {
//        selection_rate = #NS(150);
//        opinion_duration = #NS(300);
//        categorization_duration = #NS(500);
//      };
//
//      let scheduler = Scheduler.Scheduler({
//        params = scheduler_params;
//        last_selection_date = 1000;
//      });
//
//      // 1.1 Select a first question
//      var question = scheduler.selectQuestion(questions, 900);
//      assert(question == null);
//      question := scheduler.selectQuestion(questions, 1100);
//      assert(question == null);
//      question := scheduler.selectQuestion(questions, 1200);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 3); };
//      };
//
//      // 1.2 Select a second question
//      question := scheduler.selectQuestion(questions, 1300);
//      assert(question == null);
//      question := scheduler.selectQuestion(questions, 1400);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 6); };
//      };
//
//      // 1.3 Select a third question
//      question := scheduler.selectQuestion(questions, 1450);
//      assert(question == null);
//      question := scheduler.selectQuestion(questions, 2000);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 2); };
//      };
//
//      // 1.4 Select a fourth question
//      question := scheduler.selectQuestion(questions, 2200);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 7); };
//      };
//
//      // 1.5 Select a third question
//      question := scheduler.selectQuestion(questions, 2400);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 8); };
//      };
//
//      // 5 questions have been selected at timestamp: 1200, 1400, 2000, 2200, 2400
//      // and selection duration is 300.
//
//      // 2.1 Archive a first question
//      question := scheduler.archiveQuestion(questions, opinions, 900);
//      assert(question == null);
//      question := scheduler.archiveQuestion(questions, opinions, 1300);
//      assert(question == null);
//      question := scheduler.archiveQuestion(questions, opinions, 1501);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 3); };
//      };
//
//      // 2.2 Archive a second question
//      question := scheduler.archiveQuestion(questions, opinions, 1600);
//      assert(question == null);
//      question := scheduler.archiveQuestion(questions, opinions, 1750);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 6); };
//      };
//      
//      // 2.3 Archive a third question
//      question := scheduler.archiveQuestion(questions, opinions, 2400);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 2); };
//      };
//
//      // 3 questions have been archived at timestamp: 1501, 1750, 2400
//      // and categorization duration is 500.
//
//      // 3.1 Close categorization of a first question
//      question := scheduler.closeCategorization(questions, users, opinions, categorizations, 1501);
//      assert(question == null);
//      question := scheduler.closeCategorization(questions, users, opinions, categorizations, 1900);
//      assert(question == null);
//      question := scheduler.closeCategorization(questions, users, opinions, categorizations, 2050);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 3); };
//      };
//
//      // 3.2 Close categorization of a second question
//      question := scheduler.closeCategorization(questions, users, opinions, categorizations, 2200);
//      assert(question == null);
//      question := scheduler.closeCategorization(questions, users, opinions, categorizations, 2260);
//      switch(question){
//        case(null) { assert(false); };
//        case(?question) { assert(question.id == 6); };
//      };
//      
//      suite("Test Scheduler module", []);
//    };
//  };
//
//};