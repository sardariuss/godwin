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

  // Watchout: traps if pool history is empty
  public func getCurrentPool(question: Question) : Pool {
    question.pool_history[question.pool_history.size() - 1].pool;
  };
  
  // Watchout: traps if pool history is empty
  public func getLastUpdate(question: Question) : Time {
    question.pool_history[question.pool_history.size() - 1].date;
  };

  public func initPoolHistory() : PoolHistory {
    [{date = Time.now(); pool = #SPAWN;}];
  };

  public type VerifyPoolError = {
    #WrongPool;
  };

  public func verifyCurrentPool(question: Question, pools: [Pool]) : Result<(), VerifyPoolError> {
    let set_pools = TrieSet.fromArray<Pool>(pools, Types.hashPool, Types.equalPool);
    let current_pool = getCurrentPool(question);
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

  public func updateCurrentPool(
    question: Question,
    parameters: Trie<Pool, PoolParameters>,
    question_endorsement: Nat,
    max_endorsement: Nat
  ) : Result<?Question, UpdatePoolError> {
    let current_pool = getCurrentPool(question);
    switch(Trie.get(parameters, { key = current_pool; hash = Types.hashPool(current_pool) }, Types.equalPool)){
      case(null){
        #err(#ParametersNotFound);
      };
      case(?parameters){
        let now = Time.now();
        if ((Float.fromInt(question_endorsement) > parameters.ratio_max_endorsement * Float.fromInt(max_endorsement)) and 
            (getLastUpdate(question) + parameters.time_elapsed_in_pool < now)){
          let updated_question = {
            id = question.id;
            author = question.author;
            title = question.title;
            text = question.text;
            categories = question.categories;
            pool_history = Array.append(question.pool_history, [{date = now; pool = parameters.next_pool;}]);
          };
          #ok(?updated_question);
        } else {
          #ok(null);
        };
      };
    };
  };

};