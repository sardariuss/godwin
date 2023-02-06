import Types "../Types";
import Interests "Interests";
import Opinions "Opinions";
import Categorizations "Categorizations";
import Controller "../controller/Controller";
import StatusHelper "../StatusHelper";
import Cursor "representation/Cursor";
import Categories "../Categories";
import CursorMap "representation/CursorMap";
import Utils "../../utils/Utils";

import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Iter "mo:base/Iter";

module {

  type Interests = Interests.Interests;
  type Opinions = Opinions.Opinions;
  type Categorizations = Categorizations.Categorizations;
  type Time = Int;

  type Question = Types.Question;
  type IndexedStatus = Types.IndexedStatus;
  type Poll = Types.Poll;
  type TypedBallot = Types.TypedBallot;
  type TypedAnswer = Types.TypedAnswer;
  type InterestBallot = Types.InterestBallot;
  type OpinionBallot = Types.OpinionBallot;
  type CategorizationBallot = Types.CategorizationBallot;
  type TypedAggregate = Types.TypedAggregate;
  type Categories = Categories.Categories;
  type Category = Types.Category;
  type Polarization = Types.Polarization;
  type CategorizationsBallot = Categorizations.Ballot;
  type Controller = Controller.Controller;

  public func build(controller: Controller, interests: Interests, opinions: Opinions, categorizations: Categorizations, categories: Categories) : Polls {
    let polls = Polls(interests, opinions, categorizations, categories);

    controller.addObs(func(old: ?Question, new: ?Question) {
      Option.iterate(new, func(question: Question) {
        switch(StatusHelper.getCurrentStatus(question)){
          case(#VOTING(poll)) { polls.openVote(question, poll); };
          case(_) {};
        };
      })
    });
    
    polls;
  };

  public class Polls(interests_: Interests, opinions_: Opinions, categorizations_: Categorizations, categories_: Categories){

    public func openVote(question: Question, poll: Poll){
      let status = unwrapPollStatus(question, poll);
      switch(poll){
        case(#INTEREST)       { interests_.newVote(question.id, status.index, status.date); };
        case(#OPINION)        { opinions_.newVote(question.id, status.index, status.date); };
        case(#CATEGORIZATION) { categorizations_.newVote(question.id, status.index, status.date); };
      };
    };

    public func deleteVotes(question: Question){
      interests_.deleteVotes(question.id);
      opinions_.deleteVotes(question.id);
      categorizations_.deleteVotes(question.id);
    };

    public func getAggregate(question_id: Nat, iteration: Nat, poll: Poll) : TypedAggregate {
      switch(poll){
        case(#INTEREST)       { #INTEREST(interests_.getVote(question_id, iteration).aggregate); };
        case(#OPINION)        { #OPINION(opinions_.getVote(question_id, iteration).aggregate); };
        case(#CATEGORIZATION) { #CATEGORIZATION(Utils.trieToArray(categorizations_.getVote(question_id, iteration).aggregate)); };
      };
    };
      
    public func getBallot(principal: Principal, question_id: Nat, iteration: Nat, poll: Poll) : ?TypedBallot {
      switch(poll){
        case(#INTEREST)       { Option.chain(interests_.getBallot      (principal, question_id, iteration), func(b: InterestBallot)       : ?TypedBallot { ?Interests.toTypedBallot(b);}); };
        case(#OPINION)        { Option.chain(opinions_.getBallot       (principal, question_id, iteration), func(b: OpinionBallot)        : ?TypedBallot { ?Opinions.toTypedBallot(b);}); };
        case(#CATEGORIZATION) { Option.chain(categorizations_.getBallot(principal, question_id, iteration), func(b: CategorizationBallot) : ?TypedBallot { ?Categorizations.toTypedBallot(b); }); };
      };
    };

    public func revealBallot(principal: Principal, question_id: Nat, iteration: Nat, poll: Poll, date: Time) : TypedBallot {
      switch(poll){
        case(#INTEREST)       { Interests.toTypedBallot(interests_.revealBallot(principal, question_id, iteration, date)); };
        case(#OPINION)        { Opinions.toTypedBallot(opinions_.revealBallot(principal, question_id, iteration, date)); };
        case(#CATEGORIZATION) { Categorizations.toTypedBallot(categorizations_.revealBallot(principal, question_id, iteration, date)); };
      };
    };

    // @todo: watchout: could use the questions module to get the question, otherwise it's caller responsibility to make sure the question exists
    public func putBallot(principal: Principal, question: Question, ans: TypedAnswer, date: Time) {
      let ballot = createBallot(ans, date);
      let status = unwrapPollStatus(question, getPoll(ans));
      switch(ballot){
        case(#INTEREST(_))       { interests_.putBallot      (principal, question.id, status.index, Interests.fromTypedBallot(ballot)); };
        case(#OPINION(_))        { opinions_.putBallot       (principal, question.id, status.index, Opinions.fromTypedBallot(ballot)); };
        case(#CATEGORIZATION(_)) { categorizations_.putBallot(principal, question.id, status.index, Categorizations.fromTypedBallot(ballot)); };
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

  public func createBallot(typed_answer: TypedAnswer, date: Time) : TypedBallot {
    switch(typed_answer){
      case(#INTEREST(answer))       { #INTEREST({ answer; date; }); };
      case(#OPINION(answer))        { #OPINION({ answer; date; }); };
      case(#CATEGORIZATION(answer)) { #CATEGORIZATION({ answer; date; }); };
    };
  };

};