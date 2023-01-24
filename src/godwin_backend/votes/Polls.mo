import Types "../Types";
import Interests "Interests";
import Opinion "Opinions";
import Categorization "Categorizations";
import StatusInfoHelper "../StatusInfoHelper";

import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

module {

  type Interests = Interests.Interests;
  type Opinions = Opinion.Opinions;
  type Categorizations = Categorization.Categorizations;
  type Time = Int;

  type Question = Types.Question;
  type IndexedStatus = Types.IndexedStatus;
  type Poll = Types.Poll;
  type InterestBallot = Types.InterestBallot;
  type OpinionBallot = Types.OpinionBallot;
  type CategorizationBallot = Types.CategorizationBallot;
  type TypedBallot = Types.TypedBallot;
  type InterestVote = Types.InterestVote;
  type OpinionVote = Types.OpinionVote;
  type CategorizationVote = Types.CategorizationVote;
  type TypedVote = Types.TypedVote;
  type TypedAnswer = Types.TypedAnswer;

  public class Polls(interests_: Interests, opinions_: Opinions, categorizations_: Categorizations){

    public func openVote(question: Question, vote: Poll){
      let { index; date; } = unwrapVoteStatus(question, vote);
      switch(vote){
        case(#INTEREST)      { interests_.newVote(      question.id, index, date); };
        case(#OPINION)        { opinions_.newVote(       question.id, index, date); };
        case(#CATEGORIZATION) { categorizations_.newVote(question.id, index, date); };
      };
    };

    public func closeVote(question: Question, vote: Poll){
      let { index; } = unwrapVoteStatus(question, vote);
      switch(vote){
        case(#INTEREST)      { interests_.closeVote(      question.id, index); };
        case(#OPINION)        { opinions_.closeVote(       question.id, index); };
        case(#CATEGORIZATION) { categorizations_.closeVote(question.id, index); };
      };
    };

    public func deleteVotes(question: Question){
      // Delete interest votes
      let helper = StatusInfoHelper.StatusInfoHelper(question);
      // Delete interest votes
      for (iteration in Iter.range(0, helper.getIteration(#VOTING(#INTEREST)))){
        interests_.removeVote(question.id, iteration);
      };
      // Delete opinion votes
      for (iteration in Iter.range(0, helper.getIteration(#VOTING(#OPINION)))){
        opinions_.removeVote(question.id, iteration);
      };
      // Delete interest votes
      for (iteration in Iter.range(0, helper.getIteration(#VOTING(#CATEGORIZATION)))){
        categorizations_.removeVote(question.id, iteration);
      };
    };
   
    public func findVote(question_id: Nat, iteration: Nat, vote: Poll) : ?TypedVote {
      switch(vote){
        case(#INTEREST)      { Option.chain(interests_.findVote      (question_id, iteration), func(v: InterestVote)      : ?TypedVote { ?#INTEREST(v);     }); };
        case(#OPINION)        { Option.chain(opinions_.findVote       (question_id, iteration), func(v: OpinionVote)        : ?TypedVote { ?#OPINION(v);       }); };
        case(#CATEGORIZATION) { Option.chain(categorizations_.findVote(question_id, iteration), func(v: CategorizationVote) : ?TypedVote { ?#CATEGORIZATION(v);}); };
      };
    };
      
    public func getBallot(principal: Principal, question_id: Nat, iteration: Nat, vote: Poll) : ?TypedBallot {
      switch(vote){
        case(#INTEREST)      { Option.chain(interests_.getBallot      (principal, question_id, iteration), func(b: InterestBallot)      : ?TypedBallot { ?#INTEREST(b);     }); };
        case(#OPINION)        { Option.chain(opinions_.getBallot       (principal, question_id, iteration), func(b: OpinionBallot)        : ?TypedBallot { ?#OPINION(b);       }); };
        case(#CATEGORIZATION) { Option.chain(categorizations_.getBallot(principal, question_id, iteration), func(b: CategorizationBallot) : ?TypedBallot { ?#CATEGORIZATION(b);}); };
      };
    };

    public func putBallot(principal: Principal, question: Question, ans: TypedAnswer, date: Time) {
      let status = unwrapVoteStatus(question, getPoll(ans));
      switch(ans){
        case(#INTEREST(answer))      { interests_.putBallot      (principal, question.id, status.index, { answer; date; }); };
        case(#OPINION(answer))        { opinions_.putBallot       (principal, question.id, status.index, { answer; date; }); };
        case(#CATEGORIZATION(answer)) { categorizations_.putBallot(principal, question.id, status.index, { answer; date; }); };
      };
    };
    
    public func removeBallot(principal: Principal, question: Question, vote: Poll) {
      let status = unwrapVoteStatus(question, vote);
      switch(vote){
        case(#INTEREST)      { interests_.removeBallot      (principal, question.id, status.index); };
        case(#OPINION)        { opinions_.removeBallot       (principal, question.id, status.index); };
        case(#CATEGORIZATION) { categorizations_.removeBallot(principal, question.id, status.index); };
      };
    };

  };

  public func getPoll(answer: TypedAnswer) : Poll {
    switch(answer){
      case(#INTEREST(_)) { #INTEREST; };
      case(#OPINION(_)) { #OPINION; };
      case(#CATEGORIZATION(_)) { #CATEGORIZATION; };
    };
  };

  public func getVoteStatus(question: Question, vote: Poll) : ?IndexedStatus {
    let indexed_status = question.status_info.current;
    if (indexed_status.status == #VOTING(vote)){ 
      ?indexed_status; 
    } else { 
      null; 
    };
  };

  func unwrapVoteStatus(question: Question, vote: Poll) : IndexedStatus {
    switch(getVoteStatus(question, vote)){
      case(null) { Debug.trap("Unexpected question status"); };
      case(?indexed_status) { indexed_status; };
    };
  };

};