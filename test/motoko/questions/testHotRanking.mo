import Types "../../../src/godwin_backend/types";
import Queries "../../../src/godwin_backend/questions/queries";
import TestableItems "../testableItems";

import Matchers "mo:matchers/Matchers";
import Suite "mo:matchers/Suite";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";

module {

  public class TestHotRanking() = {

    // For convenience: from base module
    type Principal = Principal.Principal;
    // For convenience: from matchers module
    let { run;test;suite; } = Suite;
    // For convenience: from types module
    type Question = Types.Question;
    // For convenience: from queries module
    type QuestionRBTs = Queries.QuestionRBTs;
    let testQuery = TestableItems.testQueryQuestionsResult;

    let question_0 =        { id = 0; date = 10000; interests = { ups = 0; downs = 0; score = 0;    }; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Selfishness is the overriding drive in the human species, no matter the context."; text = ""; selection_stage = [{ timestamp = 8493; stage = #CREATED;                                              }]; categorization_stage = [{ timestamp = 1283; stage = #PENDING;  }]; };
    let question_0_update = { id = 0; date = 0;     interests = { ups = 0; downs = 0; score = 45;   }; author = Principal.fromText("sixzy-7pdha-xesaj-edo76-wuzat-gdfeh-eihfz-5b6on-eqcu2-4p23j-qqe"); title = "Above all is selfishness is the overriding drive in the human species";            text = ""; selection_stage = [{ timestamp = 8493; stage = #CREATED;                                              }]; categorization_stage = [{ timestamp = 1283; stage = #PENDING;  }]; };
    let question_1 =        { id = 1; date = 8000;  interests = { ups = 0; downs = 0; score = 0;    }; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; selection_stage = [{ timestamp = 2432; stage = #ARCHIVED { left = 0.0; center = 10.0; right = 0.0; }; }]; categorization_stage = [{ timestamp = 9372; stage = #ONGOING;  }]; };
    let question_1_update = { id = 1; date = 0;     interests = { ups = 0; downs = 0; score = 90;   }; author = Principal.fromText("2an7n-c4inx-7otxp-f4gmm-lz4yk-z6rvd-ogxe4-fype3-icqva-w5ylq-sae"); title = "Patents should not exist.";                                                        text = ""; selection_stage = [{ timestamp = 2432; stage = #ARCHIVED { left = 0.0; center = 10.0; right = 0.0; }; }]; categorization_stage = [{ timestamp = 9372; stage = #ONGOING;  }]; };
    let question_2 =        { id = 2; date = 6000;  interests = { ups = 0; downs = 0; score = 0;    }; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; selection_stage = [{ timestamp = 3132; stage = #SELECTED;                                             }]; categorization_stage = [{ timestamp = 3610; stage = #DONE([]); }]; };
    let question_2_update = { id = 2; date = 0;     interests = { ups = 0; downs = 0; score = 250;  }; author = Principal.fromText("zl5om-yevaq-syyny-vn5bl-ahjnu-cc2qx-b7oqi-ojbct-xrxjw-ivql6-uqe"); title = "Marriage should be abolished.";                                                    text = ""; selection_stage = [{ timestamp = 3132; stage = #SELECTED;                                             }]; categorization_stage = [{ timestamp = 3610; stage = #DONE([]); }]; };
    let question_3 =        { id = 3; date = 4000;  interests = { ups = 0; downs = 0; score = 0;    }; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; selection_stage = [{ timestamp = 4213; stage = #CREATED;                                              }]; categorization_stage = [{ timestamp = 4721; stage = #PENDING;  }]; };
    let question_3_update = { id = 3; date = 0;     interests = { ups = 0; downs = 0; score = 720;  }; author = Principal.fromText("ytsdx-ddotz-rkcxu-mfivi-nvtwo-cv5ip-uw5jh-7om6u-gano3-ev6sl-3qe"); title = "It is necessary to massively invest in research to improve productivity.";         text = ""; selection_stage = [{ timestamp = 4213; stage = #ARCHIVED { left = 0.0; center = 10.0; right = 0.0; }; }]; categorization_stage = [{ timestamp = 4721; stage = #PENDING;  }]; };
    let question_4 =        { id = 4; date = 2000;  interests = { ups = 0; downs = 0; score = 0;    }; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; selection_stage = [{ timestamp = 9711; stage = #SELECTED;                                             }]; categorization_stage = [{ timestamp = 9473; stage = #DONE([]); }]; };
    let question_4_update = { id = 4; date = 0;     interests = { ups = 0; downs = 0; score = 1000; }; author = Principal.fromText("zzzno-jyjub-5bu5a-nnvpt-w52zs-chfkz-bd4ar-ztjzy-xjz24-i4r3g-gae"); title = "Insurrection is necessary to deeply change society.";                              text = ""; selection_stage = [{ timestamp = 9711; stage = #SELECTED;                                             }]; categorization_stage = [{ timestamp = 9473; stage = #PENDING;  }]; };

    public func getSuite() : Suite.Suite {
      let tests = Buffer.Buffer<Suite.Suite>(0);

      var rbts = Queries.init();
      rbts := Queries.addOrderBy(rbts, #CREATION_HOT);
      
      // Add questions
      rbts := Queries.add(rbts, question_0);
      rbts := Queries.add(rbts, question_1);
      rbts := Queries.add(rbts, question_2);
      rbts := Queries.add(rbts, question_3);
      rbts := Queries.add(rbts, question_4);
      tests.add(test("Query by #CREATION_HOT, interest 0", { ids = [4, 3, 2, 1, 0]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #CREATION_HOT, null, null, #fwd, 10)))));
      
      // Replace questions      
      rbts := Queries.replace(rbts, question_0, question_0_update);
      rbts := Queries.replace(rbts, question_1, question_1_update);
      rbts := Queries.replace(rbts, question_2, question_2_update);
      rbts := Queries.replace(rbts, question_3, question_3_update);
      rbts := Queries.replace(rbts, question_4, question_4_update);
      tests.add(test("Query by #CREATION_HOT, date 0", { ids = [0, 1, 2, 3, 4]; next_id = null; }, Matchers.equals(testQuery(Queries.queryQuestions(rbts, #CREATION_HOT, null, null, #fwd, 10)))));

      suite("Test Hot ranking", tests.toArray());
    };

  };

};