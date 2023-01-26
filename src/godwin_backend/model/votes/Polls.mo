import Types "../Types";
import Interests "Interests";
import Opinion "Opinions";
import Categorization "Categorizations";
import StatusHelper "../StatusHelper";

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
  type TypedBallot = Types.TypedBallot;
  type TypedVote = Types.TypedVote;
  type TypedAnswer = Types.TypedAnswer;
  type InterestBallot = Types.InterestBallot;
  type OpinionBallot = Types.OpinionBallot;
  type CategorizationBallot = Types.CategorizationBallot;
  type InterestVote = Types.InterestVote;
  type OpinionVote = Types.OpinionVote;
  type CategorizationVote = Types.CategorizationVote;

  public class Polls(interests_: Interests, opinions_: Opinions, categorizations_: Categorizations){

    public func openVote(question: Question, poll: Poll){
      let { index; date; } = unwrapPollStatus(question, poll);
      switch(poll){
        case(#INTEREST)       { interests_.newVote(      question.id, index, date); };
        case(#OPINION)        { opinions_.newVote(       question.id, index, date); };
        case(#CATEGORIZATION) { categorizations_.newVote(question.id, index, date); };
      };
    };

    public func deleteVotes(question: Question){
      interests_.deleteVotes(question.id);
      opinions_.deleteVotes(question.id);
      categorizations_.deleteVotes(question.id);
    };
   
    public func findVote(question_id: Nat, iteration: Nat, poll: Poll) : ?TypedVote {
      switch(poll){
        case(#INTEREST)       { Option.chain(interests_.findVote      (question_id, iteration), func(v: InterestVote)       : ?TypedVote { ?#INTEREST(v);     }); };
        case(#OPINION)        { Option.chain(opinions_.findVote       (question_id, iteration), func(v: OpinionVote)        : ?TypedVote { ?#OPINION(v);       }); };
        case(#CATEGORIZATION) { Option.chain(categorizations_.findVote(question_id, iteration), func(v: CategorizationVote) : ?TypedVote { ?#CATEGORIZATION(v);}); };
      };
    };
      
    public func getBallot(principal: Principal, question_id: Nat, iteration: Nat, poll: Poll) : ?TypedBallot {
      switch(poll){
        case(#INTEREST)       { Option.chain(interests_.getBallot      (principal, question_id, iteration), func(b: InterestBallot)       : ?TypedBallot { ?#INTEREST(b);     }); };
        case(#OPINION)        { Option.chain(opinions_.getBallot       (principal, question_id, iteration), func(b: OpinionBallot)        : ?TypedBallot { ?#OPINION(b);       }); };
        case(#CATEGORIZATION) { Option.chain(categorizations_.getBallot(principal, question_id, iteration), func(b: CategorizationBallot) : ?TypedBallot { ?#CATEGORIZATION(b);}); };
      };
    };

    public func putBallot(principal: Principal, question: Question, ans: TypedAnswer, date: Time) {
      let status = unwrapPollStatus(question, getPoll(ans));
      switch(ans){
        case(#INTEREST(answer))       { interests_.putBallot      (principal, question.id, status.index, { answer; date; }); };
        case(#OPINION(answer))        { opinions_.putBallot       (principal, question.id, status.index, { answer; date; }); };
        case(#CATEGORIZATION(answer)) { categorizations_.putBallot(principal, question.id, status.index, { answer; date; }); };
      };
    };
    
    public func removeBallot(principal: Principal, question: Question, poll: Poll) {
      let status = unwrapPollStatus(question, poll);
      switch(poll){
        case(#INTEREST)       { interests_.removeBallot      (principal, question.id, status.index); };
        case(#OPINION)        { opinions_.removeBallot       (principal, question.id, status.index); };
        case(#CATEGORIZATION) { categorizations_.removeBallot(principal, question.id, status.index); };
      };
    };

  };

  public func isCurrentPoll(question: Question, poll: Poll) : Bool {
    question.status_info.current.status == #VOTING(poll);
  };

  public func matchCurrentPoll(question: Question, answer: TypedAnswer) : Bool {
    isCurrentPoll(question, getPoll(answer));
  };

  public func getPoll(answer: TypedAnswer) : Poll {
    switch(answer){
      case(#INTEREST(_)) { #INTEREST; };
      case(#OPINION(_)) { #OPINION; };
      case(#CATEGORIZATION(_)) { #CATEGORIZATION; };
    };
  };

  func unwrapPollStatus(question: Question, poll: Poll) : IndexedStatus {
    if (not isCurrentPoll(question, poll)){
      Debug.trap("This poll is currently closed");
    };
    question.status_info.current;
  };

};