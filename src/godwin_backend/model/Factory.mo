import Types "Types";
import Users "Users";
import Controller "controller/Controller";
import Schema "controller/Schema";
import Model "controller/Model";
import Decay "Decay";
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
import Observers "../utils/Observers";
import Utils "../utils/Utils";

import Set "mo:map/Set";

import Iter "mo:base/Iter";
import Option "mo:base/Option";

module {

  type Appeal = Types.Appeal;
  type Polarization = Types.Polarization;
  type PolarizationMap = Types.PolarizationMap;
  type Question = Types.Question;
  type Status = Types.Status;
  type InterestVote = Interests.Vote;
  
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
    
    let opinion_votes = Opinions.build(state_.votes.opinion);
    
    let categorization_votes = Categorizations.build(state_.votes.categorization, categories);

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

    let users = Users.build(
      state_.users.register,
      state_.creation_date, 
      state_.users.convictions_half_life
    );

    controller.addObs(func(old: ?Question, new: ?Question){
      queries.replace(
        Option.map(old, func(question: Question) : Key { toStatusEntry(question); }),
        Option.map(new, func(question: Question) : Key { toStatusEntry(question); })
      );
      Option.iterate(new, func(question: Question) {
        let status_info = StatusHelper.StatusInfo(question.status_info);
        if (status_info.getCurrentStatus() == #VOTING(#OPINION)){
          queries.remove(toAppealScore(interest_votes.getVote(question.id, status_info.getIteration(#VOTING(#INTEREST)))));
        };
      });
    });

    interest_votes.addObs(func(old: ?InterestVote, new: ?InterestVote){
      queries.replace(
        Option.map(old, func(vote: InterestVote) : Key { toAppealScore(vote); }),
        Option.map(new, func(vote: InterestVote) : Key { toAppealScore(vote); })
      );
    });

    controller.addObs(func(old: ?Question, new: ?Question) {
      let old_status = Option.map(old, func(question: Question): Status { question.status_info.current.status; });
      let new_status = Option.map(new, func(question: Question): Status { question.status_info.current.status; });
      if (not Utils.equalOpt(old_status, new_status, StatusHelper.equalStatus)){
        Option.iterate(new, func(question: Question) {
          if (question.status_info.current.status == #CLOSED){
            users.updateConvictions(question, opinion_votes, categorization_votes, categories);
          };
        });
      };
    });

    controller.addObs(func(old: ?Question, new: ?Question) {
      Option.iterate(new, func(question: Question) {
        let status_info = StatusHelper.StatusInfo(question.status_info);
        switch(status_info.getCurrentStatus()){
          case(#VOTING(poll)){
            switch(poll){
              case(#INTEREST) {
                interest_votes.newVote(question.id, status_info.getCurrentIteration(), status_info.getCurrentDate());
              };
              case(#OPINION) {
                opinion_votes.newVote(question.id, status_info.getCurrentIteration(), status_info.getCurrentDate());
              };
              case(#CATEGORIZATION) {
                categorization_votes.newVote(question.id, status_info.getCurrentIteration(), status_info.getCurrentDate());
              };
            };
          };
          case(_) {};
        };
      })
    });

    let interest_poll = Poll.Poll(#INTEREST, interest_votes, questions);
    let opinion_poll = Poll.Poll(#OPINION, opinion_votes, questions);
    let categorization_poll = Poll.Poll(#CATEGORIZATION, categorization_votes, questions);

    Game.Game(admin, categories, users, questions, queries, model, controller, interest_poll, opinion_poll, categorization_poll);
  };

};