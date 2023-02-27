import Types "Types";
import Controller "controller/Controller";
import Model "controller/Model";
import Questions "Questions";
import Interests "votes/Interests";
import Opinions "votes/Opinions";
import Categorizations "votes/Categorizations";
import Poll "votes/Poll";
import State "State";
import Game "Game";
import QuestionQueries "QuestionQueries";
import Categories "Categories";
import History "History";

import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

module {

  type Question = Types.Question;
  type Status = Types.Status;
  type InterestVote = Interests.Vote;
  type Time = Int;
  
  type Key = QuestionQueries.Key;
  let { toAppealScore; toStatusEntry } = QuestionQueries;

  type State = State.State;

  public func build(state_: State) : Game.Game {

    let admin = state_.admin;
    
    let categories = Categories.build(state_.categories);
    
    let questions = Questions.build(
      state_.questions.register,
      state_.questions.index
    );

    let interest_votes = Interests.build(state_.votes.interest);
    let interest_poll = Poll.Poll(interest_votes);
    
    let opinion_votes = Opinions.build(state_.votes.opinion);
    let opinion_poll = Poll.Poll(opinion_votes);
    
    let categorization_votes = Categorizations.build(state_.votes.categorization, categories);
    let categorization_poll = Poll.Poll(categorization_votes);

    let model = Model.build(
      state_.controller.model.time,
      state_.controller.model.most_interesting,
      state_.controller.model.last_pick_date,
      state_.controller.model.params
    );

    let queries = QuestionQueries.build(state_.queries.register, questions, interest_votes);

    let { status_history; user_history; convictions_half_life; } = state_.history;
    let history = History.build(status_history, user_history, convictions_half_life, state_.creation_date, categories);

    let controller = Controller.build(
      model,
      history,
      questions
    );

    // When the interest votes changes, update the associated key for the #INTEREST_SCORE order_by
    interest_votes.addObs(func(old: ?InterestVote, new: ?InterestVote){
      queries.replace(
        Option.map(old, func(vote: InterestVote) : Key { toAppealScore(vote); }),
        Option.map(new, func(vote: InterestVote) : Key { toAppealScore(vote); })
      );
    });

    controller.addObs(func(old: ?Question, new: ?Question) {
      // When the question status changes, update the associated key for the #STATUS order_by
      queries.replace(
        Option.map(old, func(question: Question) : Key { toStatusEntry(question); }),
        Option.map(new, func(question: Question) : Key { toStatusEntry(question); })
      );

      Option.iterate(old, func(question: Question) {
        // Remove the associated key for the #INTEREST_SCORE order_by
        if (question.status_info.status == #CANDIDATE){
          queries.remove(toAppealScore(interest_votes.getVote(question.id)));
        };
        // Remove the vote and put it in the history
        let status_record = switch(question.status_info.status){
          case(#CANDIDATE) {#CANDIDATE({
            date = question.status_info.date;
            vote_interest = interest_votes.removeVote(question.id); 
          }); };
          case(#OPEN) {     #OPEN({
            date = question.status_info.date;
            vote_opinion = opinion_votes.removeVote(question.id);
            vote_categorization = categorization_votes.removeVote(question.id);
          }); };
          case(#CLOSED){    #CLOSED({
            date = question.status_info.date;
          }); };
          case(#REJECTED){  #REJECTED({
            date = question.status_info.date;
          }); };
          case(#TRASH){     #TRASH({
            date = question.status_info.date;
          }); };
        };
        history.add(question.id, status_record);
      });

      Option.iterate(new, func(question: Question) {
        // Open a new vote
        switch(question.status_info.status){
          case(#CANDIDATE) {
            interest_votes.newVote(question.id);
          };
          case(#OPEN) {
            opinion_votes.newVote(question.id);
            categorization_votes.newVote(question.id);
          };
          case(_) {
          };
        };
      });
      
    });

    Game.Game(admin, categories, questions, history, queries, model, controller, interest_poll, opinion_poll, categorization_poll);
  };

};