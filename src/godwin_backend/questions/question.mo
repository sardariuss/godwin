import Types "../types";
import Interests "../votes/interests";
import Vote "../votes/vote";
import Iteration "../votes/iteration";
import Utils "../utils";

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Prelude "mo:base/Prelude";
import Result "mo:base/Result";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type Cursor = Types.Cursor;
  type CategoryCursorTrie = Types.CategoryCursorTrie;
  type Polarization = Types.Polarization;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Vote<B, A> = Types.Vote<B, A>;
  type Iteration = Types.Iteration;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("title: " # question.title # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
        and Principal.equal(q1.author, q2.author)
        and Text.equal(q1.title, q2.title)
        and Text.equal(q1.text, q2.text)
        and Int.equal(q1.date, q2.date);
  };

  type VoteError = {
    #InvalidVotingStage;
  };

  public func rejectQuestion(question: Question, date: Int) : Question {
    switch(question.status){
      case(#CANDIDATE(interests)) {
        { 
          question with 
          status = #REJECTED(date);
          interests_history = Utils.append(question.interests_history, [interests]);
        };
      };
      case(_){
        Prelude.unreachable(); 
      };
    };
  };

  public func openOpinionVote(question: Question, date: Int) : Question {
    switch(question.status){
      case(#CANDIDATE(interests)) {
        { 
          question with 
          status = #OPEN({ stage = #OPINION; iteration = Iteration.new(date); });
          interests_history = Utils.append(question.interests_history, [interests]);
        };
      };
      case(_){
        Prelude.unreachable(); 
      };
    };
  };

  public func openCategorizationVote(question: Question, date: Int) : Question {
    switch(question.status){
      case(#OPEN({stage; iteration;})) {
        switch(stage){
          case(#OPINION) {
            { question with status = #OPEN({ stage = #CATEGORIZATION; iteration; }); };
          };
          case(_) {
            Prelude.unreachable();
          };
        };
      };
      case(_){
        Prelude.unreachable();
      };
    };
  };

  public func closeQuestion(question: Question, date: Int) : Question {
    switch(question.status){
      case(#OPEN({stage; iteration;})) {
        switch(stage){
          case(#CATEGORIZATION) {
            {
              question with
              status = #CLOSED(date);
              vote_history = Utils.append(question.vote_history, [iteration]);
            };
          };
          case(_) {
            Prelude.unreachable();
          };
        };
      };
      case(_){
        Prelude.unreachable(); 
      };
    };
  };

  public func putInterest(question: Question, principal: Principal, interest: Interest) : Result<Question, VoteError> {
    switch(question.status){
      case(#CANDIDATE(vote)) {
        #ok({ question with status = #CANDIDATE(Vote.putBallot(vote, principal, interest, Interests.addToAggregate, Interests.removeFromAggregate)); });
      };
      case(_) {
        #err(#InvalidVotingStage);
      };
    };
  };

  public func removeInterest(question: Question, principal: Principal) : Result<Question, VoteError> {
    switch(question.status) {
      case(#CANDIDATE(vote)) {
        #ok({ question with status = #CANDIDATE(Vote.removeBallot(vote, principal, Interests.addToAggregate, Interests.removeFromAggregate)); });
      };
      case(_) {
        #err(#InvalidVotingStage);
      };
    };
  };

  public func putOpinion(question: Question, principal: Principal, opinion: Cursor) : Result<Question, VoteError> {
    switch(question.status) {
      case(#OPEN({ stage; iteration; })) {
        switch(stage){
          case(#OPINION) {
            #ok({ question with status = #OPEN({ stage; iteration = Iteration.putOpinion(iteration, principal, opinion); }); });
          };
          case(_){ #err(#InvalidVotingStage); };
        };
      };
      case(_) { #err(#InvalidVotingStage); };
    };
  };

  public func removeOpinion(question: Question, principal: Principal) : Result<Question, VoteError> {
    switch(question.status) {
      case(#OPEN({ stage; iteration; })) {
        switch(stage){
          case(#OPINION) {
            #ok({ question with status = #OPEN({ stage; iteration = Iteration.removeOpinion(iteration, principal); }); });
          };
          case(_){ #err(#InvalidVotingStage); };
        };
      };
      case(_) { #err(#InvalidVotingStage); };
    };
  };

  public func putCategorization(question: Question, principal: Principal, categorization: CategoryCursorTrie) : Result<Question, VoteError> {
    switch(question.status) {
      case(#OPEN({ stage; iteration; })) {
        switch(stage){
          case(#CATEGORIZATION) {
            #ok({ question with status = #OPEN({ stage; iteration = Iteration.putCategorization(iteration, principal, categorization); }); });
          };
          case(_){ #err(#InvalidVotingStage); };
        };
      };
      case(_) { #err(#InvalidVotingStage); };
    };
  };

  public func removeCategorization(question: Question, principal: Principal) : Result<Question, VoteError> {
    switch(question.status) {
      case(#OPEN({ stage; iteration; })) {
        switch(stage){
          case(#CATEGORIZATION) {
            #ok({ question with status = #OPEN({ stage; iteration = Iteration.removeCategorization(iteration, principal); }); });
          };
          case(_){ #err(#InvalidVotingStage); };
        };
      };
      case(_) { #err(#InvalidVotingStage); };
    };
  };

  type ReopenError = {
    #InvalidVotingStage;
  };
  
  public func reopenQuestion(question: Question) : Result<Question, ReopenError> {
    switch(question.status) {
      case(#CLOSED(date)) {
        #ok({ question with status = #CANDIDATE(Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = 0; })); });
      };
      case(_) {
        #err(#InvalidVotingStage);
      };
    };
  };

  public func unwrapInterest(question: Question) : Vote<Interest, InterestAggregate> {
    switch(question.status){
      case(#CANDIDATE(interests)){ interests; };
      case(_) { Prelude.unreachable(); };
    };
  };

  public func unwrapIteration(question: Question) : Iteration {
    switch(question.status){
      case(#OPEN({stage; iteration;})){ iteration; };
      case(_) { Prelude.unreachable(); };
    };
  };

};