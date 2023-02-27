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
import StatusHelper "StatusHelper";
import History "History";

import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

module {

  type Question = Types.Question;
  type Status = Types.Status;
  type InterestVote = Interests.Vote2;
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

    let interest_votes = Interests.build2(state_.votes.interest);
    let interest_poll = Poll.Poll(interest_votes);
    
    let opinion_votes = Opinions.build2(state_.votes.opinion);
    let opinion_poll = Poll.Poll(opinion_votes);
    
    let categorization_votes = Categorizations.build2(state_.votes.categorization, categories);
    let categorization_poll = Poll.Poll(categorization_votes);

    let model = Model.build(
      state_.controller.model.time,
      state_.controller.model.most_interesting,
      state_.controller.model.last_pick_date,
      state_.controller.model.params
    );

    let controller = Controller.build(
      model,
      questions
    );

    let queries = QuestionQueries.build(state_.queries.register, questions, interest_votes);

    let { status_history; user_history; convictions_half_life; } = state_.history;
    let histories = History.build(status_history, user_history, convictions_half_life, state_.creation_date, categories);

    // When the question status changes, update the associated key for the #STATUS order_by
    controller.addObs(func(old: ?Question, new: ?Question){
      queries.replace(
        Option.map(old, func(question: Question) : Key { toStatusEntry(question); }),
        Option.map(new, func(question: Question) : Key { toStatusEntry(question); })
      );
    });

    // When the interest votes changes, update the associated key for the #INTEREST_SCORE order_by
    interest_votes.addObs(func(old: ?InterestVote, new: ?InterestVote){
      queries.replace(
        Option.map(old, func(vote: InterestVote) : Key { toAppealScore(vote); }),
        Option.map(new, func(vote: InterestVote) : Key { toAppealScore(vote); })
      );
    });

    // When the status changes from #CANDIDATE, remove the associated key for the #INTEREST_SCORE order_by
    controller.addObs(func(old: ?Question, _: ?Question){
      Option.iterate(old, func(question: Question) {
        let status_info = StatusHelper.StatusInfo(question.status_info);
        if (status_info.getCurrentStatus() == #CANDIDATE){
          queries.remove(toAppealScore(interest_votes.getVote(question.id)));
        };
      });
    });

    controller.addObs(func(old: ?Question, new: ?Question) {
      Option.iterate(old, func(question: Question) {
        let status_info = StatusHelper.StatusInfo(question.status_info);
        // Remove the associated key for the #INTEREST_SCORE order_by
        if (status_info.getCurrentStatus() == #CANDIDATE){
          queries.remove(toAppealScore(interest_votes.getVote(question.id)));
        };
        // Remove the vote and put it in the history
        let status_record = switch(status_info.getCurrentStatus()){
          case(#CANDIDATE) {#CANDIDATE({
            date = status_info.getCurrentDate();
            vote_interest = interest_votes.removeVote(question.id); 
          }); };
          case(#OPEN) {     #OPEN({
            date = status_info.getCurrentDate();
            vote_opinion = opinion_votes.removeVote(question.id);
            vote_categorization = categorization_votes.removeVote(question.id);
          }); };
          case(#CLOSED){    #CLOSED({
            date = status_info.getCurrentDate();
          }); };
          case(#REJECTED){  #REJECTED({
            date = status_info.getCurrentDate();
          }); };
          case(#TRASH){     #TRASH({
            date = status_info.getCurrentDate();
          }); };
        };
        histories.add(question.id, status_record);
      });

      Option.iterate(new, func(question: Question) {
        let status_info = StatusHelper.StatusInfo(question.status_info);
        switch(status_info.getCurrentStatus()){
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

    Game.Game(admin, categories, questions, histories, queries, model, controller, interest_poll, opinion_poll, categorization_poll);
  };

};