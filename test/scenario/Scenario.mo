import Types     "../../src/godwin_sub/model/Types";
import Facade    "../../src/godwin_sub/model/Facade";
import Factory   "../../src/godwin_sub/model/Factory";
import State     "../../src/godwin_sub/model/State";
import Duration  "../../src/godwin_sub/utils/Duration";

import Utils     "../../src/godwin_sub/utils/Utils";

import Random    "../motoko/Random";

import Principal "mo:base/Principal";
import Debug     "mo:base/Debug";
import Nat       "mo:base/Nat";
import Result    "mo:base/Result";
import Error     "mo:base/Error";

import Fuzz      "mo:fuzz";
import Array     "mo:base/Array";

module {

  type Principal = Principal.Principal;
  type Time      = Int;
  type Facade    = Facade.Facade;
  type Duration  = Types.Duration;
  type Fuzzer    = Fuzz.Fuzzer;

  let SEED = 0;

  let NUM_USERS = 20;

  public func getPrincipals() : [Principal] {
    let fuzzer = Fuzz.fromSeed(SEED);
    Random.generatePrincipals(fuzzer, NUM_USERS);
  };

  public func run(facade: Facade, start_date: Time, end_date: Time, tick_duration: Duration) : async*() {

    let fuzzer = Fuzz.fromSeed(SEED);

    let principals = Random.generatePrincipals(fuzzer, NUM_USERS);

    var time = start_date;

    while (time + Duration.toTime(tick_duration) < end_date) {
      
      time := time + Duration.toTime(tick_duration);

      if (Random.random(fuzzer) < 0.3) {
        let principal = Random.randomUser(fuzzer, principals);
        switch(await* facade.openQuestion(principal, Random.randomQuestion(fuzzer), time)){
          case(#ok(question_id)){ Debug.print(Principal.toText(principal) # " opened question " # Nat.toText(question_id));};
          case(#err(err)) { Debug.print("Fail to open question: " # openQuestionErrorToString(err)); };
        };
      };

      for (question_id in Array.vals(facade.queryQuestions(#STATUS(#CANDIDATE), #FWD, 1000, null).keys)){
        let status_history = Utils.unwrapOk(facade.getStatusHistory(question_id));
        let iteration = status_history[status_history.size() - 1].iteration;
        let interest_vote_id = Utils.unwrapOk(facade.findInterestVoteId(question_id, iteration));
        for (principal in Array.vals(principals)) {
          if (Random.random(fuzzer) < 0.2 and Result.isErr(facade.getInterestBallot(principal, interest_vote_id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his interest on " # Nat.toText(interest_vote_id));
            switch(await* facade.putInterestBallot(principal, interest_vote_id, time, Random.randomInterest(fuzzer))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put interest ballot: " # putBallotErrorToString(err)); };
            };
          };
        };
      };

      for (question_id in Array.vals(facade.queryQuestions(#STATUS(#OPEN), #FWD, 1000, null).keys)){
        let status_history = Utils.unwrapOk(facade.getStatusHistory(question_id));
        let iteration = status_history[status_history.size() - 1].iteration;
        let opinion_vote_id = Utils.unwrapOk(facade.findOpinionVoteId(question_id, iteration));
        let categorization_vote_id = Utils.unwrapOk(facade.findCategorizationVoteId(question_id, iteration));
        for (principal in Array.vals(principals)) {
          if (Random.random(fuzzer) < 0.2 and Result.isErr(facade.getOpinionBallot(principal, opinion_vote_id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his opinion on " # Nat.toText(opinion_vote_id));
            switch(await* facade.putOpinionBallot(principal, opinion_vote_id, time, Random.randomOpinion(fuzzer))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put opinion ballot: " # putBallotErrorToString(err)); };
            };
          };
          if (Random.random(fuzzer) < 0.1 and Result.isErr(facade.getCategorizationBallot(principal, categorization_vote_id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his categorization on " # Nat.toText(categorization_vote_id));
            switch(await* facade.putCategorizationBallot(principal, categorization_vote_id, time, Random.randomCategorization(fuzzer, facade.getCategories()))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put categorization ballot: " # putBallotErrorToString(err)); };
            };
          };
        };
      };

      for (question_id in Array.vals(facade.queryQuestions(#STATUS(#CLOSED), #FWD, 1000, null).keys)){
        if (Random.random(fuzzer) < 0.1){
          let principal = Random.randomUser(fuzzer, principals);
          Debug.print("User '" # Principal.toText(principal) # "' reopens " # Nat.toText(question_id));
          ignore await* facade.reopenQuestion(principal, question_id, time);
        };
      };

      await* facade.run(time);

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
      case(#NotAllowed)               { "NotAllowed";                                    };
    };
  };

  func errorCodeToString(code: Error.ErrorCode) : Text {
    switch(code){
      case(#system_fatal){ "system_fatal" ; };
      case(#system_transient){ "system_transient" ; };
      case(#destination_invalid){ "destination_invalid" ; };
      case(#canister_reject){ "canister_reject" ; };
      case(#canister_error){ "canister_error" ; };
      case(#future(_)){ "future" ; };
      case(#call_error(_)){ "call_error" ; };
    };
  };

};