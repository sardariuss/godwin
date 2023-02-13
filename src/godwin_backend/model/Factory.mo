import Types "Types";
import Users "Users";
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

import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

module {

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
    let interest_poll = Poll.Poll(#INTEREST, interest_votes, questions);
    
    let opinion_votes = Opinions.build(state_.votes.opinion);
    let opinion_poll = Poll.Poll(#OPINION, opinion_votes, questions);
    
    let categorization_votes = Categorizations.build(state_.votes.categorization, categories);
    let categorization_poll = Poll.Poll(#CATEGORIZATION, categorization_votes, questions);

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

    // When the status changes from #VOTING(#INTEREST), remove the associated key for the #INTEREST_SCORE order_by
    controller.addObs(func(old: ?Question, _: ?Question){
      Option.iterate(old, func(question: Question) {
        let status_info = StatusHelper.StatusInfo(question.status_info);
        if (status_info.getCurrentStatus() == #VOTING(#INTEREST)){
          queries.remove(toAppealScore(interest_votes.getVote(question.id, status_info.getCurrentIteration())));
        };
      });
    });

    // When the question status changes from #VOTING(#CATEGORIZATION) to #CLOSED, update the users' convictions
    controller.addObs(func(old: ?Question, new: ?Question) {
      Option.iterate(old, func(old_question: Question) {
        if (old_question.status_info.current.status == #VOTING(#CATEGORIZATION)){
          Option.iterate(new, func(new_question: Question) {
            if (new_question.status_info.current.status == #CLOSED){
              users.onVoteClosed(new_question, opinion_votes, categorization_votes, categories);
            };
          });
        };
      });
    });

    // When the question status changes to #VOTING(poll), open the vote for this poll
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

    Game.Game(admin, categories, users, questions, queries, model, controller, interest_poll, opinion_poll, categorization_poll);
  };

};