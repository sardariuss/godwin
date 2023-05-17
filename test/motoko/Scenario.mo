import Types     "../../src/godwin_backend/model/Types";
import Facade    "../../src/godwin_backend/model/Facade";
import Factory   "../../src/godwin_backend/model/Factory";
import State     "../../src/godwin_backend/model/State";
import Duration  "../../src/godwin_backend/utils/Duration";

import Utils     "../../src/godwin_backend/utils/Utils";

import Random    "Random";

import Principal "mo:base/Principal";
import Debug     "mo:base/Debug";
import Nat       "mo:base/Nat";

import Fuzz      "mo:fuzz";
import Array     "mo:base/Array";

module {

  type Principal = Principal.Principal;
  type Time      = Int;
  type Facade    = Facade.Facade;
  type Duration  = Types.Duration;
  type Fuzzer    = Fuzz.Fuzzer;

  let SEED = 123456789;

  let NUM_USERS = 20;

  public func getPrincipals() : [Principal] {
    let fuzzer = Fuzz.fromSeed(SEED);
    Random.generatePrincipals(fuzzer, NUM_USERS);
  };

  public func run(facade: Facade, start_date: Time, end_date: Time, tick_duration: Duration) : async*() {

    let fuzzer = Fuzz.fromSeed(SEED);

    let principals = Random.generatePrincipals(fuzzer, NUM_USERS);

    var time = start_date;

    while (time < end_date) {
      time := time + Duration.toTime(tick_duration);

      if (Random.random(fuzzer) < 0.3) {
        Debug.print("Open question!");
        ignore await* facade.openQuestion(Random.randomUser(fuzzer, principals), Random.randomQuestion(fuzzer), time);
      };

      for (question_id in Array.vals(facade.getQuestions(#STATUS(#CANDIDATE), #FWD, 1000, null).keys)){
        let iteration_history = Utils.unwrapOk(facade.getIterationHistory(question_id));
        let interest_vote_id = Utils.unwrapOk(facade.findInterestVoteId(question_id, iteration_history.size() - 1));
        for (principal in Array.vals(principals)) {
          if (Random.random(fuzzer) < 0.2){
            Debug.print("User '" # Principal.toText(principal) # "' gives his interest on " # Nat.toText(question_id));
            ignore await* facade.putInterestBallot(principal, interest_vote_id, time, Random.randomInterest(fuzzer));
          };
        };
      };

      for (question_id in Array.vals(facade.getQuestions(#STATUS(#OPEN), #FWD, 1000, null).keys)){
        let iteration_history = Utils.unwrapOk(facade.getIterationHistory(question_id));
        let opinion_vote_id = Utils.unwrapOk(facade.findOpinionVoteId(question_id, iteration_history.size() - 1));
        let categorization_vote_id = Utils.unwrapOk(facade.findCategorizationVoteId(question_id, iteration_history.size() - 1));
        for (principal in Array.vals(principals)) {
          if (Random.random(fuzzer) < 0.2){
            Debug.print("User '" # Principal.toText(principal) # "' gives his opinion on " # Nat.toText(question_id));
            ignore facade.putOpinionBallot(principal, opinion_vote_id, time, Random.randomOpinion(fuzzer));
            
          };
          if (Random.random(fuzzer) < 0.1){
            Debug.print("User '" # Principal.toText(principal) # "' gives his categorization on " # Nat.toText(question_id));
            ignore await* facade.putCategorizationBallot(principal, categorization_vote_id, time, Random.randomCategorization(fuzzer, facade.getCategories()));
          };
        };
      };

      for (question_id in Array.vals(facade.getQuestions(#STATUS(#CLOSED), #FWD, 1000, null).keys)){
        if (Random.random(fuzzer) < 0.1){
          let principal = Random.randomUser(fuzzer, principals);
          Debug.print("User '" # Principal.toText(principal) # "' reopens " # Nat.toText(question_id));
          ignore await* facade.reopenQuestion(principal, question_id, time);
        };
      };

      await* facade.run(time);

    };
  };

};