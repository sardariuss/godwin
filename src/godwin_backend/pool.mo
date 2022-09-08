import Types "types";

import Time "mo:base/Time";
import Float "mo:base/Float";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Result "mo:base/Result";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Time = Time.Time;

  // For convenience: from types module
  type Question = Types.Question;
  type Pool = Types.Pool;
  type PoolHistory = Types.PoolHistory;
  type DatedPool = Types.DatedPool;
  type PoolParameters = Types.PoolParameters;
  type PoolsParameters = Types.PoolsParameters;

  public type VerifyPoolError = {
    #WrongPool;
  };

  public func verifyCurrentPool(question: Question, pools: [Pool]) : Result<(), VerifyPoolError> {
    let set_pools = TrieSet.fromArray<Pool>(pools, Types.hashPool, Types.equalPool);
    let current_pool = question.pool.current.pool;
    switch(Trie.get(set_pools, { key = current_pool; hash = Types.hashPool(current_pool) }, Types.equalPool)){
      case(null){
        #err(#WrongPool);
      };
      case(?pool){
        #ok;
      };
    };
  };

  public type UpdatePoolError = {
    #ParametersNotFound;
  };

  func getPoolParameters(poolsParameters: PoolsParameters, pool: Pool) : PoolParameters {
    switch(pool){
      case(#SPAWN) { poolsParameters.spawn; };
      case(#FISSION) { poolsParameters.fission; };
      case(#ARCHIVE) { poolsParameters.archive; };
    };
  };

  public func updateCurrentPool(question: Question, pools_parameters: PoolsParameters, question_endorsement: Nat, max_endorsement: Nat) : ?Question {
    let now = Time.now();
    let pool_parameters = getPoolParameters(pools_parameters, question.pool.current.pool);
    if ((Float.fromInt(question_endorsement) > pool_parameters.ratio_max_endorsement * Float.fromInt(max_endorsement))){
      if (question.pool.current.date + pool_parameters.time_elapsed_in_pool < now) {
        let updated_question = {
          id = question.id;
          author = question.author;
          title = question.title;
          text = question.text;
          categories = question.categories;
          pool = {
            current = { date = now; pool = pool_parameters.next_pool; };
            history = Array.append(question.pool.history, [ question.pool.current ]);
          };
        };
        return ?updated_question;
      };
    };
    return null;
  };

};