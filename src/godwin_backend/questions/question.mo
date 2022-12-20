import Types "../types";
import Interests "../votes/interests";
import Vote "../votes/vote";
import Iteration "../votes/iteration";
import CategoryPolarizationTrie "../representation/categoryPolarizationTrie";
import CategoryCursorTrie "../representation/categoryCursorTrie";
import Utils "../utils";
import Categories "../categories";

import Array "mo:base/Array";
import Buffer "mo:base/Buffer";
import Nat32 "mo:base/Nat32";
import Principal "mo:base/Principal";
import Int "mo:base/Int";
import Text "mo:base/Text";
import Prelude "mo:base/Prelude";
import Result "mo:base/Result";
import TrieSet "mo:base/TrieSet";

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
  type Status = Types.Status;
  type Category = Types.Category;

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat32.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("title: " # question.title # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat32.equal(q1.id, q2.id)
       and Principal.equal(q1.author, q2.author)
       and Text.equal(q1.title, q2.title)
       and Text.equal(q1.text, q2.text)
       and Int.equal(q1.date, q2.date);
  };

  type VoteError = {
    #InvalidVotingStage;
  };

  type CategorizationError = {
    #InvalidVotingStage;
    #InvalidCategorization;
  };

  public func getStatus(question: Question) : Status {
    switch(question.status) {
      case(#CANDIDATE(_)) { #CANDIDATE; };
      case(#OPEN({stage;})) { 
        switch(stage){
          case(#OPINION)        { #OPEN(#OPINION);        };
          case(#CATEGORIZATION) { #OPEN(#CATEGORIZATION); };
        };
      };
      case(#CLOSED(_)) { #CLOSED; };
      case(#REJECTED(_)) { #REJECTED; };
    };
  };

  public func unwrapStatusDate(question: Question) : Int {
    switch(question.status) {
      case(#CANDIDATE(vote)) { vote.date; };
      case(#OPEN({stage; iteration; })) { 
        switch(stage){
          case(#OPINION)        { iteration.opinion.date;        };
          case(#CATEGORIZATION) { iteration.categorization.date; };
        };
      };
      case(#CLOSED(date))   { date; };
      case(#REJECTED(date)) { date; };
    };
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

  public func openOpinionVote(question: Question, opinion_date: Int, categorization_date: Int) : Question {
    switch(question.status){
      case(#CANDIDATE(interests)) {
        { 
          question with 
          status = #OPEN({ stage = #OPINION; iteration = Iteration.new(opinion_date, categorization_date); });
          interests_history = Utils.append(question.interests_history, [interests]);
        };
      };
      case(_){
        Prelude.unreachable(); 
      };
    };
  };

  public func openCategorizationVote(question: Question, date: Int, categories: [Category]) : Question {
    switch(question.status){
      case(#OPEN({stage; iteration;})) {
        switch(stage){
          case(#OPINION) {
            { question with status = #OPEN({ stage = #CATEGORIZATION; iteration = Iteration.openCategorization(iteration, date, categories); }); };
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

  public func putCategorization(question: Question, principal: Principal, categorization: CategoryCursorTrie) : Result<Question, CategorizationError> {
    switch(question.status) {
      case(#OPEN({ stage; iteration; })) {
        switch(stage){
          case(#CATEGORIZATION) {
            if(not TrieSet.equal(CategoryPolarizationTrie.keys(iteration.categorization.aggregate), CategoryCursorTrie.keys(categorization), Text.equal)){
              return #err(#InvalidCategorization);
            };
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

  public func unwrapRejectedDate(question: Question) : Int {
    switch(question.status){
      case(#REJECTED(date)){ date; };
      case(_) { Prelude.unreachable(); };
    };
  };

  public func unwrapClosedDate(question: Question) : Int {
    switch(question.status){
      case(#CLOSED(date)){ date; };
      case(_) { Prelude.unreachable(); };
    };
  };

};