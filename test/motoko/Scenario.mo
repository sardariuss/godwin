import Types "../../src/godwin_backend/model/Types";
import Interests "../../src/godwin_backend/model/votes/Interests";
import Game "../../src/godwin_backend/model/Game";
import Factory "../../src/godwin_backend/model/Factory";
import State "../../src/godwin_backend/model/State";
import Duration "../../src/godwin_backend/utils/Duration";

import WSet "../../src/godwin_backend/utils/wrappers/WSet";

import TestableItems "testableItems";
import Principals "Principals";
import Random "Random";

import Principal "mo:base/Principal";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";
import Debug "mo:base/Debug";
import Nat32 "mo:base/Nat32";
import Nat "mo:base/Nat";

import Fuzz "mo:fuzz";
import Blob "mo:base/Blob";
import Bool "mo:base/Bool";
import Array "mo:base/Array";
import Int "mo:base/Int";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;
  type Game = Game.Game;
  type Duration = Duration.Duration;
  type Fuzzer = Fuzz.Fuzzer;

  public func run(end_date: Time, simulation_duration: Duration, tick_duration: Duration, num_users: Nat) : Game {

    let parameters = {
      master = Principal.fromText("aaaaa-aa"); // @todo
      categories = [
        ("IDENTITY", { left = { name = "CONSTRUCTIVISM";   symbol = "🧩"; color = "#f26c0d"; }; right = { name = "ESSENTIALISM"; symbol = "💎"; color = "#f2a60d"; }; }),
        ("ECONOMY",  { left = { name = "SOCIALISM";        symbol = "🌹"; color = "#0fca02"; }; right = { name = "CAPITALISM";   symbol = "🎩"; color = "#02ca27"; }; }),
        ("CULTURE",  { left = { name = "PROGRESSIVISM";    symbol = "🌊"; color = "#2c00cc"; }; right = { name = "CONSERVATISM"; symbol = "🧊"; color = "#5f00cc"; }; }),
      ];
      history = {
        convictions_half_life = null;
      };
      scheduler = {
        interest_pick_rate = #HOURS(1);
        interest_duration = #HOURS(4);
        opinion_duration = #HOURS(1);
        rejected_duration = #HOURS(6);
      };
    };

    var time = end_date - Duration.toTime(simulation_duration);

    let game = Factory.build(State.initState(Principal.fromText("aaaaa-aa"), time, parameters));

    let fuzzer = Fuzz.fromSeed(123456789);

    let principals = Random.generatePrincipals(fuzzer, num_users);

    // @todo: fix this

//    while (time < end_date) {
//      time := time + Duration.toTime(tick_duration);
//
//      if (Random.random(fuzzer) < 0.3) {
//        Debug.print("Open question!");
//        ignore game.openQuestion(Random.randomUser(fuzzer, principals), Random.randomQuestion(fuzzer), time);
//      };
//
//      for (question_id in Array.vals(game.getQuestions(#STATUS(#CANDIDATE), #FWD, 1000, null).keys)){
//        for (principal in Array.vals(principals)) {
//          if (Random.random(fuzzer) < 0.2){
//            Debug.print("User '" # Principal.toText(principal) # "' gives his interest on " # Nat.toText(question_id));
//            ignore game.putInterestBallot(principal, question_id, time, Random.randomInterest(fuzzer));
//          };
//        };
//      };
//
//      for (question_id in Array.vals(game.getQuestions(#STATUS(#OPEN), #FWD, 1000, null).keys)){
//        for (principal in Array.vals(principals)) {
//          if (Random.random(fuzzer) < 0.2){
//            Debug.print("User '" # Principal.toText(principal) # "' gives his opinion on " # Nat.toText(question_id));
//            ignore game.putOpinionBallot(principal, question_id, time, Random.randomOpinion(fuzzer));
//            
//          };
//          if (Random.random(fuzzer) < 0.1){
//            Debug.print("User '" # Principal.toText(principal) # "' gives his categorization on " # Nat.toText(question_id));
//            ignore game.putCategorizationBallot(principal, question_id, time, Random.randomCategorization(fuzzer, parameters.categories));
//          };
//        };
//      };
//
//      for (question_id in Array.vals(game.getQuestions(#STATUS(#CLOSED), #FWD, 1000, null).keys)){
//        if (Random.random(fuzzer) < 0.1){
//          let principal = Random.randomUser(fuzzer, principals);
//          Debug.print("User '" # Principal.toText(principal) # "' reopens " # Nat.toText(question_id));
//          ignore game.reopenQuestion(principal, question_id, time);
//        };
//      };
//
//      game.run(time);
//
//    };

    game;
  };

};