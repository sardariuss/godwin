import Types "types";
import Queries "queries";

import Debug "mo:base/Debug";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  // For convenience: from types module
  type Question = Types.Question;
  type Pool = Types.Pool;
  type PoolParameters = Types.PoolParameters;
  type PoolsParameters = Types.PoolsParameters;

  public type VerifyPoolError = {
    #WrongPool;
  };

  public func verifyCurrentPool(question: Question, pools: [Pool]) : Result<(), VerifyPoolError> {
    let set_pools = TrieSet.fromArray<Pool>(pools, Types.hashPool, Types.equalPool);
    let current_pool = question.pool.current.pool;
    switch(Trie.get(set_pools, { key = current_pool; hash = Types.hashPool(current_pool) }, Types.equalPool)){
      case(null){ #err(#WrongPool); };
      case(?pool){ #ok; };
    };
  };

  public type QuestionsPerPool = {
    spawn_rbts: Queries.QuestionRBTs;
    reward_rbts: Queries.QuestionRBTs;
    archive_rbts: Queries.QuestionRBTs;
  };

  public func empty() : QuestionsPerPool {
    var spawn_rbts = Queries.init();
    spawn_rbts := Queries.addOrderBy(spawn_rbts, #ENDORSEMENTS);
    let reward_rbts = Queries.init();
    let archive_rbts = Queries.init();
    { spawn_rbts; reward_rbts; archive_rbts; };
  };

  func getPoolRBTs(per_pool: QuestionsPerPool, pool: Pool) : Queries.QuestionRBTs {
    switch(pool){
      case(#SPAWN){ per_pool.spawn_rbts; };
      case(#REWARD){ per_pool.reward_rbts; };
      case(#ARCHIVE){ per_pool.archive_rbts; };
    };
  };

  func setPoolRBTs(per_pool: QuestionsPerPool, pool: Pool, rbts: Queries.QuestionRBTs) : QuestionsPerPool {
    switch(pool){
      case(#SPAWN){   { spawn_rbts = rbts;             reward_rbts = per_pool.reward_rbts; archive_rbts = per_pool.archive_rbts; }; };
      case(#REWARD){  { spawn_rbts = per_pool.spawn_rbts; reward_rbts = rbts;        archive_rbts = per_pool.archive_rbts;       }; };
      case(#ARCHIVE){ { spawn_rbts = per_pool.spawn_rbts; reward_rbts = per_pool.reward_rbts; archive_rbts = rbts;               }; };
    };
  };

  public func addQuestion(per_pool: QuestionsPerPool, question: Question) : QuestionsPerPool {
    if (question.pool.current.pool != #SPAWN) {
      Debug.trap("Cannot add a question which current pool is different from #SPAWN");
    };
    {
      spawn_rbts = Queries.add(per_pool.spawn_rbts, question);
      reward_rbts = per_pool.reward_rbts;
      archive_rbts = per_pool.archive_rbts;
    };
  };

  public func replaceQuestion(per_pool: QuestionsPerPool, old_question: Question, new_question: Question) : QuestionsPerPool {
    var updated_per_pool = per_pool;
    let old_pool = old_question.pool.current.pool;
    let new_pool = new_question.pool.current.pool;
    if (old_pool == new_pool) {
      // Replace in current pool
      var rbts = getPoolRBTs(updated_per_pool, old_pool);
      rbts := Queries.replace(rbts, old_question, new_question);
      updated_per_pool := setPoolRBTs(updated_per_pool, old_pool, rbts);
    } else {
      // Remove from previous pool
      var rbts_1 = getPoolRBTs(updated_per_pool, old_pool);
      rbts_1 := Queries.remove(rbts_1, old_question);
      updated_per_pool := setPoolRBTs(updated_per_pool, old_pool, rbts_1);
      // Add in new pool
      var rbts_2 = getPoolRBTs(updated_per_pool, new_pool);
      rbts_2 := Queries.add(rbts_2, new_question);
      updated_per_pool := setPoolRBTs(updated_per_pool, new_pool, rbts_2);
    };
    updated_per_pool;
  };

  public func removeQuestion(per_pool: QuestionsPerPool, question: Question) : QuestionsPerPool {
    let current_pool = question.pool.current.pool;
    var rbts = getPoolRBTs(per_pool, current_pool);
    rbts := Queries.remove(rbts, question);
    setPoolRBTs(per_pool, current_pool, rbts);
  };

};