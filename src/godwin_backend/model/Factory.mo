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

  public func build(_state: State) : Controller {

    let admin = _state.admin;
    
    let categories = Categories.build(_state.categories);
    
    let questions = Questions.build(
      _state.questions.register,
      _state.questions.index
    );

    let status_manager = StatusManager.build(_state.status.register);

    let subaccount_generator = SubaccountGenerator.build(_state.subaccounts.index);
    let payin : (Principal, Blob) -> async* Result<(), ()> = func(principal: Principal, subaccount: Blob) : async* Result<(), ()> {
      #ok; // @todo
    };
    let interest_payout : (Interests.Vote, Blob) -> () = func(vote: Interests.Vote, subaccount: Blob) : () {
      // @todo
    };
    let categorization_payout : (Categorizations.Vote, Blob) -> () = func(vote: Categorizations.Vote, subaccount: Blob) : () {
      // @todo
    };

    let queries = QuestionQueries.build(_state.queries.register);

    let interest_votes = Votes.Votes<Interest, Appeal>(_state.votes.interest, Appeal.init());
    let interest_history = QuestionVoteHistory.build(_state.votes.interest_history);
    
    let interests = Interests.build(
      interest_votes,
      interest_history,
      queries,
      _state.subaccounts.interest_votes,
      subaccount_generator,
      payin,
      interest_payout
    );
    
    let opinion_votes = Votes.Votes<Cursor, Polarization>(_state.votes.opinion, Polarization.nil());
    let opinion_history = QuestionVoteHistory.build(_state.votes.opinion_history);
    
    let opinions = Opinions.build(
      opinion_votes,
      opinion_history,
    );
    
    let categorization_votes = Votes.Votes<CursorMap, PolarizationMap>(_state.votes.categorization, PolarizationMap.nil(categories));
    let categorization_history = QuestionVoteHistory.build(_state.votes.categorization_history);
    
    let categorizations = Categorizations.build(
      categories,
      categorization_votes,
      categorization_history,
      _state.subaccounts.categorization_votes,
      subaccount_generator,
      payin,
      categorization_payout
    );

    let users = Users.build(
      _state.users.register,
      opinion_history,
      opinion_votes,
      categorization_history,
      categorization_votes,
      _state.users.convictions_half_life,
      _state.creation_date,
      categories);

    let model = Model.build(
      _state.admin,
      _state.controller.model.time,
      _state.controller.model.last_pick_date,
      _state.controller.model.params,
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