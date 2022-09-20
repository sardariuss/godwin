import Types "types";
import Queries "queries";

import Debug "mo:base/Debug";

module {

  // For convenience: from types module
  type Question = Types.Question;
  type Pool = Types.Pool;

  public type QuestionPools = {
    spawn_rbts: Queries.QuestionRBTs;
    reward_rbts: Queries.QuestionRBTs;
    archive_rbts: Queries.QuestionRBTs;
  };

  public func empty() : QuestionPools {
    var spawn_rbts = Queries.init();
    spawn_rbts := Queries.addOrderBy(spawn_rbts, #ENDORSEMENTS);
    let reward_rbts = Queries.init();
    let archive_rbts = Queries.init();
    { spawn_rbts; reward_rbts; archive_rbts; };
  };

  func getPoolRBTs(pools: QuestionPools, pool: Pool) : Queries.QuestionRBTs {
    switch(pool){
      case(#SPAWN){ pools.spawn_rbts; };
      case(#REWARD){ pools.reward_rbts; };
      case(#ARCHIVE){ pools.archive_rbts; };
    };
  };

  func setPoolRBTs(pools: QuestionPools, pool: Pool, rbts: Queries.QuestionRBTs) : QuestionPools {
    switch(pool){
      case(#SPAWN){   { spawn_rbts = rbts;             reward_rbts = pools.reward_rbts; archive_rbts = pools.archive_rbts; }; };
      case(#REWARD){  { spawn_rbts = pools.spawn_rbts; reward_rbts = rbts;        archive_rbts = pools.archive_rbts;       }; };
      case(#ARCHIVE){ { spawn_rbts = pools.spawn_rbts; reward_rbts = pools.reward_rbts; archive_rbts = rbts;               }; };
    };
  };

  public func addQuestion(pools: QuestionPools, question: Question) : QuestionPools {
    if (question.pool.current.pool != #SPAWN) {
      Debug.trap("Cannot add a question which current pool is different from SPAWN");
    };
    {
      spawn_rbts = Queries.add(pools.spawn_rbts, question);
      reward_rbts = pools.reward_rbts;
      archive_rbts = pools.archive_rbts;
    };
  };

  public func replaceQuestion(pools: QuestionPools, old_question: Question, new_question: Question) : QuestionPools {
    var updated_pools = pools;
    let old_pool = old_question.pool.current.pool;
    let new_pool = new_question.pool.current.pool;
    if (old_pool == new_pool) {
      // Replace in current pool
      var rbts = getPoolRBTs(updated_pools, old_pool);
      rbts := Queries.replace(rbts, old_question, new_question);
      updated_pools := setPoolRBTs(updated_pools, old_pool, rbts);
    } else {
      // Remove from previous pool
      var rbts_1 = getPoolRBTs(updated_pools, old_pool);
      rbts_1 := Queries.remove(rbts_1, old_question);
      updated_pools := setPoolRBTs(updated_pools, old_pool, rbts_1);
      // Add in new pool
      var rbts_2 = getPoolRBTs(updated_pools, new_pool);
      rbts_2 := Queries.add(rbts_2, new_question);
      updated_pools := setPoolRBTs(updated_pools, new_pool, rbts_2);
    };
    updated_pools;
  };

  public func removeQuestion(pools: QuestionPools, question: Question) : QuestionPools {
    let current_pool = question.pool.current.pool;
    var rbts = getPoolRBTs(pools, current_pool);
    rbts := Queries.remove(rbts, question);
    setPoolRBTs(pools, current_pool, rbts);
  };

};