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
      categories = [
        "IDENTITY",
        "ECONOMY",
        "CULTURE" ];
      history = {
        convictions_half_life = null;
      };
      scheduler = {
        interest_pick_rate = #HOURS(2);
        interest_duration = #HOURS(6);
        opinion_duration = #HOURS(6);
        rejected_duration = #HOURS(6);
      };
    };

    var time = end_date - Duration.toTime(simulation_duration);

    let game = Factory.build(State.initState(Principal.fromText("aaaaa-aa"), time, parameters));

    let fuzzer = Fuzz.fromSeed(123456789);

    let principals = Random.generatePrincipals(fuzzer, num_users);

    while (time < end_date) {
      Debug.print("Tick: " # Int.toText(time));
      time := time + Duration.toTime(tick_duration);

      if (Random.random(fuzzer) < 0.2) {
        Debug.print("Open question!");
        ignore game.openQuestion(Random.randomUser(fuzzer, principals), Random.randomTitle(fuzzer), "", time);
      };

      for (question_id in Array.vals(game.getQuestions(#STATUS(#CANDIDATE), #FWD, 1000, null).keys)){
        for (principal in Array.vals(principals)) {
          if (Random.random(fuzzer) < 0.1){
            ignore game.putInterestBallot(principal, question_id, time, Random.randomInterest(fuzzer));
          };
        };
      };

      for (question_id in Array.vals(game.getQuestions(#STATUS(#OPEN), #FWD, 1000, null).keys)){
        for (principal in Array.vals(principals)) {
          if (Random.random(fuzzer) < 0.08){
            ignore game.putOpinionBallot(principal, question_id, time, Random.randomOpinion(fuzzer));
            Debug.print("User '" # Principal.toText(principal) # "' gave his opinion.");
          };
          if (Random.random(fuzzer) < 0.04){
            ignore game.putCategorizationBallot(principal, question_id, time, Random.randomCategorization(fuzzer, parameters.categories));
          };
        };
      };

      for (question_id in Array.vals(game.getQuestions(#STATUS(#CLOSED), #FWD, 1000, null).keys)){
        if (Random.random(fuzzer) < 0.01){
          ignore game.reopenQuestion(Random.randomUser(fuzzer, principals), question_id, time);
        };
      };

      game.run(time);

    };

    game;
  };

};