import Types "types";
import Users "users";
import Scheduler "scheduler";
import Decay "decay";
import Questions "questions/questions";
import Queries "questions/queries";
import Queries2 "Queries2";
import OrderedSet "OrderedSet";
import Interest "votes/interest";
import Opinion "votes/opinion";
import Categorization "votes/categorization";
import Manager "votes/manager";
import State "state";
import Game "game";
import Observers "observers";
import WSet "wrappers/WSet";
import QuestionQueries2 "QuestionQueries2";
import Utils "utils";

import Set "mo:map/Set";

import Map "mo:map/Map";

import Iter "mo:base/Iter";
import Option "mo:base/Option";

module {

  type InterestAggregate = Types.InterestAggregate;
  type Polarization = Types.Polarization;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Question = Types.Question;
  type QuestionStatus = Types.QuestionStatus;

  type State = State.State;

  public func build(state_: State) : Game.Game {

    let admin = state_.admin;
    
    let categories = WSet.WSet(state_.categories, Set.thash);
    
    let questions = Questions.build(
      state_.questions.register,
      state_.questions.index
    );

    let interest_votes = Interest.build(state_.votes.interest);
    
    let opinion_votes = Opinion.build(state_.votes.opinion);
    
    let categorization_votes = Categorization.build(state_.votes.categorization, Iter.toArray(categories.keys()));

    let queries = QuestionQueries2.build(state_.queries.register, questions, interest_votes);

    let users = Users.build(
      state_.users.register,
      Decay.computeOptDecay(state_.creation_date, state_.users.convictions_half_life),
      questions,
      opinion_votes,
      categorization_votes
    );

    let manager = Manager.Manager(
      interest_votes,
      opinion_votes,
      categorization_votes
    );

    let scheduler = Scheduler.build(
      state_.scheduler.register,
      questions,
      users,
      queries,
      manager
    );

    Game.Game(admin, categories, users, questions, queries, scheduler, manager);
  };

};