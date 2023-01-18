import Users "users";
import Scheduler "scheduler";
import Decay "decay";
import Questions "questions/questions";
import Queries "questions/queries";
import Interest "votes/interest";
import Opinion "votes/opinion";
import Categorization "votes/categorization";
import State "state";
import Game "game";
import WSet "wrappers/WSet";

import Set "mo:map/Set";

import Iter "mo:base/Iter";

module {

  type Set<K> = Set.Set<K>;

  type State = State.State;

  public func build(state_: State) : Game.Game {

    let admin = state_.admin;
    let categories = WSet.WSet(state_.categories, Set.thash);
    let users = Users.build(
      state_.users.register,
      Decay.computeOptDecay(state_.creation_date, state_.users.convictions_half_life)
    );
    let questions = Questions.build(
      state_.questions.register,
      state_.questions.index
    );
    let queries = Queries.build(
      state_.queries.register
    );
    let scheduler = Scheduler.build(
      state_.scheduler.selection_rate,
      state_.scheduler.status_durations,
      state_.scheduler.last_selection_date,
      questions,
      users,
      queries
    );
    let interest_votes = Interest.build(
      state_.votes.interest.ballots, 
      state_.votes.interest.aggregates
    );
    let opinion_votes = Opinion.build(
      state_.votes.opinion.ballots,
      state_.votes.opinion.aggregates
    );
    let categorization_votes = Categorization.build(
      state_.votes.categorization.ballots,
      state_.votes.categorization.aggregates,
      Iter.toArray(categories.keys())
    );

    // Add observers to sync queries
    questions.addObs(#QUESTION_ADDED, queries.add);
    questions.addObs(#QUESTION_REMOVED, queries.remove);

    Game.Game(
      admin,
      categories,
      users,
      questions,
      queries,
      scheduler,
      interest_votes,
      opinion_votes,
      categorization_votes
    );
  };

};