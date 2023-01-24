import Types "Types";
import Users "Users";
import Scheduler "Scheduler";
import Decay "Decay";
import Questions "Questions";
import Interests "votes/Interests";
import Opinions "votes/Opinions";
import Categorizations "votes/Categorizations";
import Polls "votes/Polls";
import State "State";
import Game "Game";
import QuestionQueries "QuestionQueries";
import WSet "../utils/wrappers/WSet";

import Set "mo:map/Set";

import Iter "mo:base/Iter";

module {

  type Appeal = Types.Appeal;
  type Polarization = Types.Polarization;
  type PolarizationMap = Types.PolarizationMap;
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

    let interest_votes = Interests.build(state_.votes.interest);
    
    let opinion_votes = Opinions.build(state_.votes.opinion);
    
    let categorization_votes = Categorizations.build(state_.votes.categorization, Iter.toArray(categories.keys()));

    let queries = QuestionQueries.build(state_.queries.register, questions, interest_votes);

    let users = Users.build(
      state_.users.register,
      Decay.computeOptDecay(state_.creation_date, state_.users.convictions_half_life),
      questions,
      opinion_votes,
      categorization_votes
    );

    let manager = Polls.Polls(
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