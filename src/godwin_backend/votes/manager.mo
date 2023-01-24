import Types "../types";
import Interest "interest";
import Opinion "opinion";
import Categorization "categorization";
import StatusInfoHelper "../StatusInfoHelper";

import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

module {

  type Interests2 = Interest.Interests2;
  type Opinions = Opinion.Opinions;
  type Categorizations = Categorization.Categorizations;
  type Time = Int;

  type Question = Types.Question;
  type Category = Types.Category;
  type IndexedStatus = Types.IndexedStatus;
  type VoteType = Types.VoteType;
  type CandidateBallot = Types.CandidateBallot;
  type OpinionBallot = Types.OpinionBallot;
  type CategorizationBallot = Types.CategorizationBallot;
  type TypedBallot = Types.TypedBallot;
  type CandidateVote = Types.CandidateVote;
  type OpinionVote = Types.OpinionVote;
  type CategorizationVote = Types.CategorizationVote;
  type TypedVote = Types.TypedVote;
  type TypedAnswer = Types.TypedAnswer;

  public class Manager(interests_: Interests2, opinions_: Opinions, categorizations_: Categorizations){

    public func openVote(question: Question, vote: VoteType){
      let { index; date; } = unwrapVoteStatus(question, vote);
      switch(vote){
        case(#CANDIDATE)      { interests_.newVote(      question.id, index, date); };
        case(#OPINION)        { opinions_.newVote(       question.id, index, date); };
        case(#CATEGORIZATION) { categorizations_.newVote(question.id, index, date); };
      };
    };

    public func closeVote(question: Question, vote: VoteType){
      let { index; } = unwrapVoteStatus(question, vote);
      switch(vote){
        case(#CANDIDATE)      { interests_.closeVote(      question.id, index); };
        case(#OPINION)        { opinions_.closeVote(       question.id, index); };
        case(#CATEGORIZATION) { categorizations_.closeVote(question.id, index); };
      };
    };

    public func deleteVotes(question: Question){
      // Delete interest votes
      let helper = StatusInfoHelper.build(question.status_info);
      // Delete interest votes
      for (iteration in Iter.range(0, helper.getIteration(#VOTING(#CANDIDATE)))){
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
   
    public func findVote(question_id: Nat, iteration: Nat, vote: VoteType) : ?TypedVote {
      switch(vote){
        case(#CANDIDATE)      { Option.chain(interests_.findVote      (question_id, iteration), func(v: CandidateVote)      : ?TypedVote { ?#CANDIDATE(v);     }); };
        case(#OPINION)        { Option.chain(opinions_.findVote       (question_id, iteration), func(v: OpinionVote)        : ?TypedVote { ?#OPINION(v);       }); };
        case(#CATEGORIZATION) { Option.chain(categorizations_.findVote(question_id, iteration), func(v: CategorizationVote) : ?TypedVote { ?#CATEGORIZATION(v);}); };
      };
    };
      
    public func getBallot(principal: Principal, question_id: Nat, iteration: Nat, vote: VoteType) : ?TypedBallot {
      switch(vote){
        case(#CANDIDATE)      { Option.chain(interests_.getBallot      (principal, question_id, iteration), func(b: CandidateBallot)      : ?TypedBallot { ?#CANDIDATE(b);     }); };
        case(#OPINION)        { Option.chain(opinions_.getBallot       (principal, question_id, iteration), func(b: OpinionBallot)        : ?TypedBallot { ?#OPINION(b);       }); };
        case(#CATEGORIZATION) { Option.chain(categorizations_.getBallot(principal, question_id, iteration), func(b: CategorizationBallot) : ?TypedBallot { ?#CATEGORIZATION(b);}); };
      };
    };

    public func putBallot(principal: Principal, question: Question, ans: TypedAnswer, date: Time) {
      let status = unwrapVoteStatus(question, getVoteType(ans));
      switch(ans){
        case(#CANDIDATE(answer))      { interests_.putBallot      (principal, question.id, status.index, { answer; date; }); };
        case(#OPINION(answer))        { opinions_.putBallot       (principal, question.id, status.index, { answer; date; }); };
        case(#CATEGORIZATION(answer)) { categorizations_.putBallot(principal, question.id, status.index, { answer; date; }); };
      };
    };
    
    public func removeBallot(principal: Principal, question: Question, vote: VoteType) {
      let status = unwrapVoteStatus(question, vote);
      switch(vote){
        case(#CANDIDATE)      { interests_.removeBallot      (principal, question.id, status.index); };
        case(#OPINION)        { opinions_.removeBallot       (principal, question.id, status.index); };
        case(#CATEGORIZATION) { categorizations_.removeBallot(principal, question.id, status.index); };
      };
    };

  };

  public func getVoteType(answer: TypedAnswer) : VoteType {
    switch(answer){
      case(#CANDIDATE(_)) { #CANDIDATE; };
      case(#OPINION(_)) { #OPINION; };
      case(#CATEGORIZATION(_)) { #CATEGORIZATION; };
    };
  };

  public func getVoteStatus(question: Question, vote: VoteType) : ?IndexedStatus {
    let indexed_status = question.status_info.current;
    if (indexed_status.status == #VOTING(vote)){ 
      ?indexed_status; 
    } else { 
      null; 
    };
  };

  func unwrapVoteStatus(question: Question, vote: VoteType) : IndexedStatus {
    switch(getVoteStatus(question, vote)){
      case(null) { Debug.trap("Unexpected question status"); };
      case(?indexed_status) { indexed_status; };
    };
  };

};