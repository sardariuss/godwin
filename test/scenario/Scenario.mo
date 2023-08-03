import Types     "../../src/godwin_sub/model/Types";
import Facade    "../../src/godwin_sub/model/Facade";
import Factory   "../../src/godwin_sub/model/Factory";
import Duration  "../../src/godwin_sub/utils/Duration";

import Utils     "../../src/godwin_sub/utils/Utils";

import Random    "../motoko/common/Random";

import Principal "mo:base/Principal";
import Debug     "mo:base/Debug";
import Nat       "mo:base/Nat";
import Result    "mo:base/Result";
import Error     "mo:base/Error";
import Array     "mo:base/Array";

import Fuzz      "mo:fuzz";

module {

  type Principal         = Principal.Principal;
  type Time              = Int;
  type Facade            = Facade.Facade;
  type Duration          = Types.Duration;
  type QueryQuestionItem = Types.QueryQuestionItem;
  type VoteKind          = Types.VoteKind;
  type VoteId            = Types.VoteId;
  type Fuzzer            = Fuzz.Fuzzer;

  let SEED = 0;

  let NUM_USERS = 20;

  public func getPrincipals() : [Principal] {
    let fuzzer = Fuzz.fromSeed(SEED);
    Random.generatePrincipals(fuzzer, NUM_USERS);
  };

  public func run(facade: Facade, start_date: Time, end_date: Time, tick_duration: Duration) : async*() {

    let fuzzer = Fuzz.fromSeed(SEED);

    let principals = Random.generatePrincipals(fuzzer, NUM_USERS);

    let categories = facade.getSubInfo().categories;

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

      for (principal in Array.vals(principals)) {
        for ({vote} in Array.vals(facade.queryFreshVotes(principal, #INTEREST, #FWD, 10, null).keys)){
          if (Random.random(fuzzer) < 0.2 and Result.isErr(facade.getInterestBallot(principal, vote.1.id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his interest on " # Nat.toText(vote.1.id));
            switch(await* facade.putInterestBallot(principal, vote.1.id, time, Random.randomInterest(fuzzer))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put interest ballot: " # putBallotErrorToString(err)); };
            };
          };
        };
        for ({vote} in Array.vals(facade.queryFreshVotes(principal, #OPINION, #FWD, 10, null).keys)){
          if (Random.random(fuzzer) < 0.2 and Result.isErr(facade.getOpinionBallot(principal, vote.1.id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his opinion on " # Nat.toText(vote.1.id));
            switch(await* facade.putOpinionBallot(principal, vote.1.id, time, Random.randomOpinion(fuzzer))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put opinion ballot: " # putBallotErrorToString(err)); };
            };
          };
        };
        for ({vote} in Array.vals(facade.queryFreshVotes(principal, #CATEGORIZATION, #FWD, 10, null).keys)){
          if (Random.random(fuzzer) < 0.1 and Result.isErr(facade.getCategorizationBallot(principal, vote.1.id))){
            Debug.print("User '" # Principal.toText(principal) # "' gives his categorization on " # Nat.toText(vote.1.id));
            switch(await* facade.putCategorizationBallot(principal, vote.1.id, time, Random.randomCategorization(fuzzer, categories))){
              case(#ok(_)){};
              case(#err(err)) { Debug.print("Fail to put categorization ballot: " # putBallotErrorToString(err)); };
            };
          };
        };
      };

      for (queried_question in Array.vals(facade.queryQuestions(#STATUS(#CLOSED), #FWD, 1000, null).keys)){
        let question_id = queried_question.question.id;
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
      case(#AccessDenied(_))          { "AccessDenied";                                  };
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