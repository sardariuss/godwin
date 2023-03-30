import Types "Types";
import Controller "controller/Controller";
import Model "controller/Model";
import Questions "Questions";
import Interests "votes/Interests";
import Categorizations "votes/Categorizations";
import Appeal "votes/representation/Appeal";
import Polarization "votes/representation/Polarization";
import PolarizationMap "votes/representation/PolarizationMap";
import Opinions "votes/Opinions";
import SubaccountGenerator "token/SubaccountGenerator";
import State "State";
import QuestionQueries "QuestionQueries";
import Categories "Categories";
import Users "Users";
import StatusManager "StatusManager";
import QuestionVoteHistory "QuestionVoteHistory";
import Votes "votes/Votes";

import Map "mo:map/Map";

import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Result "mo:base/Result";

module {

  type Question = Types.Question;
  type Status = Types.Status;
  type Appeal = Types.Appeal;
  type Interest = Types.Interest;
  type Cursor = Types.Cursor;
  type Polarization = Types.Polarization;
  type CursorMap = Types.CursorMap;
  type PolarizationMap = Types.PolarizationMap;
  type InterestVote = Interests.Vote;
  type Time = Int;
  type Controller = Controller.Controller;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Key = QuestionQueries.Key;
  let { toAppealScore; } = QuestionQueries;

  type State = State.State;

  public func build(state: State) : Controller {

    let admin = state.admin;
    
    let categories = Categories.build(state.categories);
    
    let questions = Questions.build(
      state.questions.register,
      state.questions.index,
      state.questions.character_limit
    );

    let status_manager = StatusManager.build(state.status.register);

    let subaccount_generator = SubaccountGenerator.build(state.subaccounts.index);
    let payin : (Principal, Blob) -> async* Result<(), ()> = func(principal: Principal, subaccount: Blob) : async* Result<(), ()> {
      #ok; // @todo
    };
    let interest_payout : (Interests.Vote, Blob) -> () = func(vote: Interests.Vote, subaccount: Blob) : () {
      // @todo
    };
    let categorization_payout : (Categorizations.Vote, Blob) -> () = func(vote: Categorizations.Vote, subaccount: Blob) : () {
      // @todo
    };

    let queries = QuestionQueries.build(state.queries.register);

    let interest_votes = Votes.Votes<Interest, Appeal>(state.votes.interest, Appeal.init());
    let interest_history = QuestionVoteHistory.build(state.votes.interest_history);
    
    let interests = Interests.build(
      interest_votes,
      interest_history,
      queries,
      state.subaccounts.interest_votes,
      subaccount_generator,
      payin,
      interest_payout
    );
    
    let opinion_votes = Votes.Votes<Cursor, Polarization>(state.votes.opinion, Polarization.nil());
    let opinion_history = QuestionVoteHistory.build(state.votes.opinion_history);
    
    let opinions = Opinions.build(
      opinion_votes,
      opinion_history,
    );
    
    let categorization_votes = Votes.Votes<CursorMap, PolarizationMap>(state.votes.categorization, PolarizationMap.nil(categories));
    let categorization_history = QuestionVoteHistory.build(state.votes.categorization_history);
    
    let categorizations = Categorizations.build(
      categories,
      categorization_votes,
      categorization_history,
      state.subaccounts.categorization_votes,
      subaccount_generator,
      payin,
      categorization_payout
    );

    let users = Users.build(
      state.users.register,
      opinion_history,
      opinion_votes,
      categorization_history,
      categorization_votes,
      state.users.convictions_half_life,
      state.creation_date,
      categories);

    let model = Model.build(
      state.admin,
      state.controller.model.time,
      state.controller.model.last_pick_date,
      state.controller.model.params,
      categories,
      questions,
      status_manager,
      users,
      queries,
      interests,
      opinions,
      categorizations
    );

    let controller = Controller.build(model);

    controller;
  };

};