import Users "users";
import Scheduler "scheduler";
import Decay "decay";
import Questions "questions/questions";
import Queries "questions/queries";
import Interest "votes/interest";
import Opinion "votes/opinion";
import Categorization "votes/categorization";
import Manager "votes/manager";
import State "state";
import Game "game";
import WSet "wrappers/WSet";

import Set "mo:map/Set";

import Iter "mo:base/Iter";

module {

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
    let manager = Manager.build(
      state_.votes.interest,
      state_.votes.opinion,
      state_.votes.categorization,
      Iter.toArray(categories.keys())
    );
    let scheduler = Scheduler.build(
      state_.scheduler.register,
      questions,
      users,
      queries,
      manager
    );

    // Add observers to sync queries
    questions.addObs(#RECORD, queries.replace);

    Game.Game(
      admin,
      categories,
      users,
      questions,
      queries,
      scheduler,
      manager
    );
  };

};