import Types "Types";
import Controller "controller/Controller";
import Model "controller/Model";
import Questions "Questions";
import Interests "votes/Interests";
import Opinions "votes/Opinions";
import Categorizations "votes/Categorizations";
import Interests2 "votes/Interests2";
import Opinions2 "votes/Opinions2";
import Categorizations2 "votes/Categorizations2";
import SubaccountGenerator "token/SubaccountGenerator";
import SubaccountMap "token/SubaccountMap";
import State "State";
import QuestionQueries "QuestionQueries";
import Categories "Categories";
import History "History";
import StatusManager "StatusManager2";
import QuestionVoteHistory "QuestionVoteHistory";

import Map "mo:map/Map";

import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";
import Result "mo:base/Result";

module {

  type Question = Types.Question;
  type Status = Types.Status;
  type Appeal = Types.Appeal;
  type InterestVote = Interests.Vote;
  type Time = Int;
  type Controller = Controller.Controller;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  
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

    let status_manager = StatusManager.build(state_.status.register);

    let subaccount_generator = SubaccountGenerator.build(state_.subaccounts.index);
    let payin : (Principal, Blob) -> async Result<(), ()> = func(principal: Principal, subaccount: Blob) : async Result<(), ()> {
      #ok; // @todo
    };
    let interest_payout : (Interests.Vote, Blob) -> () = func(vote: Interests.Vote, subaccount: Blob) : () {
      // @todo
    };
    let categorization_payout : (Categorizations.Vote, Blob) -> () = func(vote: Categorizations.Vote, subaccount: Blob) : () {
      // @todo
    };

    let queries = QuestionQueries.build(state_.queries.register);

    // When the interest votes changes, update the associated key for the #INTEREST_SCORE order_by
    let update_appeal_callback = func(question_id: Nat, old: ?Appeal, new: ?Appeal){
      queries.replace(
        Option.map(old, func(appeal: Appeal) : Key { toAppealScore(question_id, appeal); }),
        Option.map(new, func(appeal: Appeal) : Key { toAppealScore(question_id, appeal); })
      );
    };

    let interest_votes = Interests2.build(
      state_.votes2.interest,
      QuestionVoteHistory.build(Map.new<Nat, QuestionVoteHistory.VoteLink>()), // @todo
      state_.subaccounts.interest_votes,
      subaccount_generator,
      payin,
      interest_payout,
      [update_appeal_callback]
    );
    
    let opinion_votes = Opinions2.build(
      state_.votes2.opinion,
      QuestionVoteHistory.build(Map.new<Nat, QuestionVoteHistory.VoteLink>()) // @todo
    );
    
    let categorization_votes = Categorizations2.build(
      categories,
      state_.votes2.categorization,
      QuestionVoteHistory.build(Map.new<Nat, QuestionVoteHistory.VoteLink>()), // @todo
      state_.subaccounts.categorization_votes,
      subaccount_generator,
      payin,
      categorization_payout
    );

    let history = History.build(
      state_.history.status_history,
      state_.history.interests_history,
      state_.history.opinons_history,
      state_.history.categorizations_history,
      state_.history.user_history,
      state_.history.convictions_half_life,
      state_.creation_date,
      categories);

    let model = Model.build(
      state_.admin,
      state_.controller.model.time,
      state_.controller.model.last_pick_date,
      state_.controller.model.params,
      categories,
      questions,
      status_manager,
      history,
      queries,
      interest_votes,
      opinion_votes,
      categorization_votes
    );

    let controller = Controller.build(model);

    controller;
  };

};