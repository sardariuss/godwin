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
import Polls "votes/Polls";
import State "State";
import Game "Game";
import QuestionQueries "QuestionQueries";
import Categories "Categories";

import Set "mo:map/Set";

import Iter "mo:base/Iter";

module {

  type Appeal = Types.Appeal;
  type Polarization = Types.Polarization;
  type PolarizationMap = Types.PolarizationMap;
  type Question = Types.Question;
  type Status = Types.Status;

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

    let queries = QuestionQueries.build(state_.queries.register, controller, questions, interest_votes);

    let users = Users.build(
      state_.users.register,
      Decay.computeOptDecay(state_.creation_date, state_.users.convictions_half_life),
      controller,
      opinion_votes,
      categorization_votes,
      categories
    );

    let polls = Polls.build(
      controller,
      interest_votes,
      opinion_votes,
      categorization_votes,
      categories
    );

    Game.Game(admin, categories, users, questions, queries, model, controller, polls);
  };

};