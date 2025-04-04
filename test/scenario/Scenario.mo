import EightValues "EightValues";
import Types       "../../src/godwin_sub/model/Types";
import Controller  "../../src/godwin_sub/model/controller/Controller";
import Factory     "../../src/godwin_sub/model/Factory";
import Duration    "../../src/godwin_sub/utils/Duration";

import Utils       "../../src/godwin_sub/utils/Utils";

import Random      "../motoko/common/Random";

import Map         "mo:map/Map";

import Principal   "mo:base/Principal";
import Debug       "mo:base/Debug";
import Nat         "mo:base/Nat";
import Result      "mo:base/Result";
import Error       "mo:base/Error";
import Array       "mo:base/Array";

import Fuzz        "mo:fuzz";

module {

  type Principal         = Principal.Principal;
  type Time              = Int;
  type Controller        = Controller.Controller;
  type Duration          = Types.Duration;
  type QueryQuestionItem = Types.QueryQuestionItem;
  type VoteKind          = Types.VoteKind;
  type VoteId            = Types.VoteId;
  type Fuzzer            = Fuzz.Fuzzer;

  let SEED = 0;

  let NUM_USERS = 15;

  public func getPrincipals() : [Principal] {
    let fuzzer = Fuzz.fromSeed(SEED);
    Random.generatePrincipals(fuzzer, NUM_USERS);
  };

  public func run(controller: Controller, start_date: Time, end_date: Time, tick_duration: Duration) : async*() {

    let fuzzer = Fuzz.fromSeed(SEED);

    let eight_values = EightValues.EightValues();
    let categorizations = Map.new<Nat, [(Text, Float)]>(Map.nhash);

    let principals = Random.generatePrincipals(fuzzer, NUM_USERS);

    let categories = controller.getSubInfo().categories;

    var time = start_date;

    while (time + Duration.toTime(tick_duration) < end_date) {
      
      time := time + Duration.toTime(tick_duration);

      if (Random.random(fuzzer) < 0.15) {
        let principal = Random.randomUser(fuzzer, principals);
        let { text; categorization; } = eight_values.pickQuestion(fuzzer);
        switch(await* controller.openQuestion(principal, text, time)){
          case(#ok(question_id)){ 
            Debug.print(Principal.toText(principal) # " opened question " # Nat.toText(question_id));
            Map.set(categorizations, Map.nhash, question_id, categorization);
          };
          case(#err(err)) { Debug.print("Fail to open question: " # openQuestionErrorToString(err)); };
        };
      };

      for (principal in Array.vals(principals)) {
        for ({vote} in Array.vals(controller.queryFreshVotes(principal, #INTEREST, #FWD, 10, null).keys)){
          if (Random.random(fuzzer) < 0.2 and Result.isErr(controller.revealBallot(#INTEREST, principal, principal, vote.1.id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his interest on " # Nat.toText(vote.1.id));
            switch(await* controller.putBallot(#INTEREST, principal, vote.1.id, time, #INTEREST(Random.randomInterest(fuzzer)))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put interest ballot: " # putBallotErrorToString(err)); };
            };
          };
        };
        for ({vote} in Array.vals(controller.queryFreshVotes(principal, #OPINION, #FWD, 10, null).keys)){
          if (Random.random(fuzzer) < 0.2 and Result.isErr(controller.revealBallot(#OPINION, principal, principal, vote.1.id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his opinion on " # Nat.toText(vote.1.id));
            switch(await* controller.putBallot(#OPINION, principal, vote.1.id, time, #OPINION(Random.randomOpinion(fuzzer)))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put opinion ballot: " # putBallotErrorToString(err)); };
            };
          };
        };
        for ({question_id; vote;} in Array.vals(controller.queryFreshVotes(principal, #CATEGORIZATION, #FWD, 10, null).keys)){
          if (Random.random(fuzzer) < 0.1 and Result.isErr(controller.revealBallot(#CATEGORIZATION, principal, principal, vote.1.id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his categorization on " # Nat.toText(vote.1.id));
            let categorization = switch(Map.get(categorizations, Map.nhash, question_id)) { case(?cat) { cat }; case(null) { Debug.trap("Categorization not found"); } };
            switch(await* controller.putBallot(#CATEGORIZATION, principal, vote.1.id, time, #CATEGORIZATION(Random.randomCategorization(fuzzer, categorization)))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put categorization ballot: " # putBallotErrorToString(err)); };
            };
          };
        };
      };

      for (queried_question in Array.vals(controller.queryQuestions(#STATUS(#CLOSED), #FWD, 1000, null).keys)){
        let question_id = queried_question.question.id;
        if (Random.random(fuzzer) < 0.1){
          let principal = Random.randomUser(fuzzer, principals);
          Debug.print("User '" # Principal.toText(principal) # "' reopens " # Nat.toText(question_id));
          ignore await* controller.reopenQuestion(principal, question_id, time);
        };
      };

      await* controller.run(time, Principal.fromText("aaaaa-aa"));
    };
  };

  func putBallotErrorToString(putBallotError: Types.PutBallotError) : Text {
    switch(putBallotError){
      case(#VoteLocked)                     { "VoteLocked";             };
      case(#VoteNotFound)                   { "VoteNotFound";           };
      case(#ChangeBallotNotAllowed)         { "ChangeBallotNotAllowed"; };
      case(#NoSubacountLinked)              { "NoSubacountLinked";      };
      case(#PayinError(_))                  { "PayinError";             };
      case(#PrincipalIsAnonymous)           { "PrincipalIsAnonymous";   };
      case(#VoteClosed)                     { "VoteClosed";             };
      case(#InvalidBallot)                  { "InvalidBallot";          };
      case(#BallotKindMismatch)             { "BallotKindMismatch";     };
    };
  };

  func openQuestionErrorToString(openQuestionError: Types.OpenQuestionError) : Text {
    switch(openQuestionError){
      case(#TextTooLong)              { "TextTooLong";                                   };
      case(#PrincipalIsAnonymous)     { "PrincipalIsAnonymous";                          };
      case(#CanisterCallError(code))  { "CanisterCallError: " # errorCodeToString(code); };
      case(#TooOld)                   { "TooOld";                                        };
      case(#CreatedInFuture(_))       { "CreatedInFuture";                               };
      case(#BadFee(_))                { "BadFee";                                        };
      case(#BadBurn(_))               { "BadBurn";                                       };
      case(#InsufficientFunds(_))     { "InsufficientFunds";                             };
      case(#Duplicate(_))             { "Duplicate";                                     };
      case(#TemporarilyUnavailable)   { "TemporarilyUnavailable";                        };
      case(#GenericError(_))          { "GenericError";                                  };
      case(#AccessDenied(_))          { "AccessDenied";                                  };
    };
  };

  func errorCodeToString(code: Error.ErrorCode) : Text {
    switch(code){
      case(#system_fatal)       { "system_fatal";        };
      case(#system_transient)   { "system_transient";    };
      case(#destination_invalid){ "destination_invalid"; };
      case(#canister_reject)    { "canister_reject";     };
      case(#canister_error)     { "canister_error";      };
      case(#future(_))          { "future";              };
      case(#call_error(_))      { "call_error";          };
    };
  };

};