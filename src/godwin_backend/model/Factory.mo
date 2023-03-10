import Types "Types";
import Controller "controller/Controller";
import Model "controller/Model";
import Questions "Questions";
import Interests "votes/Interests";
import Opinions "votes/Opinions";
import Categorizations "votes/Categorizations";
import Poll "votes/Poll";
import SubaccountGenerator "token/SubaccountGenerator";
import SubaccountMap "token/SubaccountMap";
import State "State";
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
  type Controller = Controller.Controller;
  
  type Key = QuestionQueries.Key;
  let { toAppealScore; toStatusEntry } = QuestionQueries;

  type State = State.State;

  public func build(state_: State) : Controller {

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

    let history = History.build(
      state_.history.status_history,
      state_.history.interests_history,
      state_.history.opinons_history,
      state_.history.categorizations_history,
      state_.history.user_history,
      state_.history.convictions_half_life,
      state_.creation_date,
      categories);

    let queries = QuestionQueries.build(state_.queries.register, questions, interest_votes);

    let interest_subaccounts = SubaccountMap.SubaccountMap(state_.subaccounts.interest_subaccounts);
    let categorization_subaccounts = SubaccountMap.SubaccountMap(state_.subaccounts.categorization_subaccounts);
    let subaccount_generator = SubaccountGenerator.build(state_.subaccounts.index);

    let model = Model.build(
      state_.admin,
      state_.controller.model.time,
      state_.controller.model.last_pick_date,
      state_.controller.model.params,
      categories,
      questions,
      history,
      queries,
      interest_votes,
      opinion_votes,
      categorization_votes,
      interest_subaccounts,
      categorization_subaccounts,
      subaccount_generator
    );

    let controller = Controller.build(model);

    // When the interest votes changes, update the associated key for the #INTEREST_SCORE order_by
    interest_votes.addObs(func(old: ?InterestVote, new: ?InterestVote){
      queries.replace(
        Option.map(old, func(vote: InterestVote) : Key { toAppealScore(vote); }),
        Option.map(new, func(vote: InterestVote) : Key { toAppealScore(vote); })
      );
    });

    controller;
  };

};