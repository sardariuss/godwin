import Types "../../src/godwin_backend/model/Types";
import Controller "../../src/godwin_backend/model/controller/Controller";
import Factory "../../src/godwin_backend/model/Factory";
import State "../../src/godwin_backend/model/State";
import Duration "../../src/godwin_backend/utils/Duration";

import Random "Random";

import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

import Fuzz "mo:fuzz";
import Array "mo:base/Array";

module {

  type Principal = Principal.Principal;
  type Time = Int;
  type Controller = Controller.Controller;
  type Duration = Duration.Duration;
  type Fuzzer = Fuzz.Fuzzer;

  let SEED = 123456789;

  let NUM_USERS = 20;

  public func getPrincipals() : [Principal] {
    let fuzzer = Fuzz.fromSeed(SEED);
    Random.generatePrincipals(fuzzer, NUM_USERS);
  };

  public func run(controller: Controller, start_date: Time, end_date: Time, tick_duration: Duration) : async*() {

    let fuzzer = Fuzz.fromSeed(SEED);

    let principals = Random.generatePrincipals(fuzzer, NUM_USERS);

    var time = start_date;

    while (time < end_date) {
      time := time + Duration.toTime(tick_duration);

      if (Random.random(fuzzer) < 0.3) {
        Debug.print("Open question!");
        ignore await* controller.openQuestion(Random.randomUser(fuzzer, principals), Random.randomQuestion(fuzzer), time);
      };

      for (question_id in Array.vals(controller.getQuestions(#STATUS(#CANDIDATE), #FWD, 1000, null).keys)){
        for (principal in Array.vals(principals)) {
          if (Random.random(fuzzer) < 0.2){
            Debug.print("User '" # Principal.toText(principal) # "' gives his interest on " # Nat.toText(question_id));
            ignore await* controller.putInterestBallot(principal, question_id, time, Random.randomInterest(fuzzer));
          };
        };
      };

      for (question_id in Array.vals(controller.getQuestions(#STATUS(#OPEN), #FWD, 1000, null).keys)){
        for (principal in Array.vals(principals)) {
          if (Random.random(fuzzer) < 0.2){
            Debug.print("User '" # Principal.toText(principal) # "' gives his opinion on " # Nat.toText(question_id));
            ignore controller.putOpinionBallot(principal, question_id, time, Random.randomOpinion(fuzzer));
            
          };
          if (Random.random(fuzzer) < 0.1){
            Debug.print("User '" # Principal.toText(principal) # "' gives his categorization on " # Nat.toText(question_id));
            ignore await* controller.putCategorizationBallot(principal, question_id, time, Random.randomCategorization(fuzzer, controller.getCategories()));
          };
        };
      };

      for (question_id in Array.vals(controller.getQuestions(#STATUS(#CLOSED), #FWD, 1000, null).keys)){
        if (Random.random(fuzzer) < 0.1){
          let principal = Random.randomUser(fuzzer, principals);
          Debug.print("User '" # Principal.toText(principal) # "' reopens " # Nat.toText(question_id));
          ignore await* controller.reopenQuestion(principal, question_id, time);
        };
      };

      controller.run(time);

    };
  };

};