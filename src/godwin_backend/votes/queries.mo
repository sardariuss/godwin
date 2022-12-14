import Types "../types";

import RBT "mo:stableRBT/StableRBTree";

import Trie "mo:base/Trie";
import Order "mo:base/Order";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";
import Int "mo:base/Int";
import Float "mo:base/Float";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Order = Order.Order;
  type Hash = Hash.Hash;
  type Key<K> = Trie.Key<K>;
  type Iter<T> = Iter.Iter<T>;

  // For convenience: from types module
  type VotingStage = Types.VotingStage;
  type Iteration = Types.Iteration;
  type Polarization = Types.Polarization;
  type CategoryPolarizationTrie = Types.CategoryPolarizationTrie;
  type Vote<B, A> = Types.Vote<B, A>;

  // Public types
  public type OrderBy = {
    #ID;
    #VOTE_AGGREGATE;
    #VOTE_DATE;
  };

  public type QueryQuestionsResult = { ids: [Nat]; next_id: ?Nat };
  public type QueryDirection = {
    #FWD;
    #BWD;
  };
  public type IterationKey = {
    id: Nat;
    data: {
      #ID;
      #VOTE_AGGREGATE: VoteAggregateEntry;
      #VOTE_DATE: VoteDateEntry;
    };
  };

  // Private types
  type VoteAggregateEntry = { 
    #INTEREST: Int; // Interest score
    #OPINION: Polarization;
    #CATEGORIZATION: CategoryPolarizationTrie;
    #CLOSED;
  };

  type VoteDateEntry = { 
    stage: VotingStage;
    date: Int;
  };

  public type IterationRBTs = Trie<OrderBy, RBT.Tree<IterationKey, ()>>;

  // To be able to use OrderBy as key in a Trie
  func toTextOrderBy(order_by: OrderBy) : Text {
    switch(order_by){
      case(#ID){ "ID"; };
      case(#VOTE_AGGREGATE){ "VOTE_AGGREGATE"; };
      case(#VOTE_DATE){ "VOTE_DATE"; };
    };
  };
  func hashOrderBy(order_by: OrderBy) : Hash { Text.hash(toTextOrderBy(order_by)); };
  func equalOrderBy(a: OrderBy, b: OrderBy) : Bool { a == b; };
  func keyOrderBy(order_by: OrderBy) : Key<OrderBy> { { key = order_by; hash = hashOrderBy(order_by); } };

  // Init functions
  func initIterationKey(iteration: Iteration, order_by: OrderBy) : IterationKey {
    switch(order_by){
      case(#ID){ { id = iteration.id; data = #ID; } };
      case(#VOTE_AGGREGATE){ { id = iteration.id; data = #VOTE_AGGREGATE(initVoteAggregateEntry(iteration)); } };
      case(#VOTE_DATE){ { id = iteration.id; data = #VOTE_DATE(initVoteDateEntry(iteration)); } };
    };
  };

  func initVoteAggregateEntry(iteration: Iteration) : VoteAggregateEntry {
    switch(iteration.voting_stage){
      case(#INTEREST) { 
        switch(iteration.interest){
          case(null) { Debug.trap("@todo"); };
          case(?vote) { #INTEREST(vote.aggregate.score); };
        };
      };
      case(#OPINION) { 
        switch(iteration.opinion){
          case(null) { Debug.trap("@todo"); };
          case(?vote) { #OPINION(vote.aggregate); };
        };
      };
      case(#CATEGORIZATION) { 
        switch(iteration.categorization){
          case(null) { Debug.trap("@todo"); };
          case(?vote) { #CATEGORIZATION(vote.aggregate); };
        };
      };
      case(#CLOSED) { 
        switch(iteration.closing_date){
          case(null) { Debug.trap("@todo"); };
          case(?date) { #CLOSED; };
        };
      };
    };
  };

  func initVoteDateEntry(iteration: Iteration) : VoteDateEntry {
    {
      stage = iteration.voting_stage;
      date = switch(iteration.voting_stage){
        case(#INTEREST) { 
          switch(iteration.interest){
            case(null) { Debug.trap("@todo"); };
            case(?vote) { vote.date; };
          };
        };
        case(#OPINION) { 
          switch(iteration.opinion){
            case(null) { Debug.trap("@todo"); };
            case(?vote) { vote.date; };
          };
        };
        case(#CATEGORIZATION) { 
          switch(iteration.categorization){
            case(null) { Debug.trap("@todo"); };
            case(?vote) { vote.date; };
          };
        };
        case(#CLOSED) { 
          switch(iteration.closing_date){
            case(null) { Debug.trap("@todo"); };
            case(?date) { date; };
          };
        };
      };
    };
  };

  // Compare functions
  func compareIterationKey(a: IterationKey, b: IterationKey) : Order {
    let default_order = compareIds(a.id, b.id);
    switch(a.data){
      case(#ID){
        switch(b.data){
          case(#ID){ default_order; };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#VOTE_AGGREGATE(entry_a)){
        switch(b.data){
          case(#VOTE_AGGREGATE(entry_b)){ compareVoteAggregateEntries(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#VOTE_DATE(entry_a)){
        switch(b.data){
          case(#VOTE_DATE(entry_b)){ compareVoteDateEntries(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
    };
  };

  func compareIds(first_id: Nat, second_id: Nat) : Order {
    if (first_id < second_id){ #less;}
    else if (first_id > second_id){ #greater;}
    else { #equal;}  
  };

  func compareVoteAggregateEntries(a: VoteAggregateEntry, b: VoteAggregateEntry, default_order: Order) : Order {
    switch(a){
      case(#INTEREST(score_a)){
        switch(b){
          case(#INTEREST(score_b)) { compareInt(score_a, score_b, default_order); };
          case(#OPINION(_)) { #less; };
          case(#CATEGORIZATION(_)) { #less; };
          case(#CLOSED) { #less; };
        };
      };
      case(#OPINION(polarization_a)){
        switch(b){
          case(#INTEREST(_)) { #greater; };
          case(#OPINION(polarization_b)) { default_order; }; // @todo
          case(#CATEGORIZATION(_)) { #less; };
          case(#CLOSED) { #less; };
        };
      };
      case(#CATEGORIZATION(categorization_a)){
        switch(b){
          case(#INTEREST(_)) { #greater; };
          case(#OPINION(_)) { #greater; };
          case(#CATEGORIZATION(categorization_b)) { default_order; }; // @todo
          case(#CLOSED) { #less; };
        };
      };
      case(#CLOSED){
        switch(b){
          case(#INTEREST(_)) { #greater; };
          case(#OPINION(_)) { #greater; };
          case(#CATEGORIZATION(_)) { #greater; };
          case(#CLOSED) { default_order; };
        };
      };
    };
  };

  func compareVoteDateEntries(a: VoteDateEntry, b: VoteDateEntry, default_order: Order) : Order {
    switch(a.stage){
      case(#INTEREST){
        switch(b.stage){
          case(#INTEREST) { compareInt(a.date, b.date, default_order); };
          case(#OPINION) { #less; };
          case(#CATEGORIZATION) { #less; };
          case(#CLOSED) { #less; };
        };
      };
      case(#OPINION){
        switch(b.stage){
          case(#INTEREST) { #greater; };
          case(#OPINION) { compareInt(a.date, b.date, default_order); };
          case(#CATEGORIZATION) { #less; };
          case(#CLOSED) { #less; };
        };
      };
      case(#CATEGORIZATION){
        switch(b.stage){
          case(#INTEREST) { #greater; };
          case(#OPINION) { #greater; };
          case(#CATEGORIZATION) { compareInt(a.date, b.date, default_order); };
          case(#CLOSED) { #less; };
        };
      };
      case(#CLOSED){
        switch(b.stage){
          case(#INTEREST) { #greater; };
          case(#OPINION) { #greater; };
          case(#CATEGORIZATION) { #greater; };
          case(#CLOSED) { compareInt(a.date, b.date, default_order); };
        };
      };
    };
  };


  func compareInt(a: Int, b: Int, default_order: Order) : Order {
    switch(Int.compare(a, b)){
      case(#less) { #less; };
      case(#greater) { #greater; };
      case(#equal) { default_order; };
    };
  };

  func compareFloat(a: Float, b: Float, default_order: Order) : Order {
    switch(Float.compare(a, b)){
      case(#less) { #less; };
      case(#greater) { #greater; };
      case(#equal) { default_order; };
    };
  };

  // Public functions

  public func init() : IterationRBTs { 
    Trie.empty<OrderBy, RBT.Tree<IterationKey, ()>>();
  };

  // @todo: this is done for optimization (mostly to reduce memory usage) but brings some issues:
  // (queryQuestions and entries can trap). Alternative would be to init with every OrderBy
  // possible in init method.
  public func addOrderBy(rbts: IterationRBTs, order_by: OrderBy) : IterationRBTs {
    Trie.put(rbts, keyOrderBy(order_by), equalOrderBy, RBT.init<IterationKey, ()>()).0;
  };

  public func add(rbts: IterationRBTs, new_iteration: Iteration) : IterationRBTs {
    var new_rbts = rbts;
    for ((order_by, rbt) in Trie.iter(rbts)){
      let new_rbt = RBT.put(rbt, compareIterationKey, initIterationKey(new_iteration, order_by), ());
      new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
    };
    new_rbts;
  };

  public func replace(rbts: IterationRBTs, old_iteration: Iteration, new_iteration: Iteration) : IterationRBTs {
    var new_rbts = rbts;
    for ((order_by, rbt) in Trie.iter(rbts)){
      let old_key = initIterationKey(old_iteration, order_by);
      let new_key = initIterationKey(new_iteration, order_by);
      if (compareIterationKey(old_key, new_key) != #equal){
        var new_rbt = RBT.remove(rbt, compareIterationKey, old_key).1;
        new_rbt := RBT.put(new_rbt, compareIterationKey, new_key, ());
        new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
      };
    };
    new_rbts;
  };

  public func remove(rbts: IterationRBTs, old_iteration: Iteration) : IterationRBTs {
    var new_rbts = rbts;
    for ((order_by, rbt) in Trie.iter(rbts)){
      let new_rbt = RBT.remove(rbt, compareIterationKey, initIterationKey(old_iteration, order_by)).1;
      new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
    };
    new_rbts;
  };

  // @todo: if lower or upper bound IterationKey data is not of the same type as OrderBy, what happens ? traps ?
  // @todo: fix lower_bound and upper_bound should not require the iteration id...
  public func queryQuestions(
    rbts: IterationRBTs,
    order_by: OrderBy,
    lower_bound: ?IterationKey,
    upper_bound: ?IterationKey,
    direction: RBT.Direction,
    limit: Nat
  ) : QueryQuestionsResult {
    switch(Trie.get(rbts, keyOrderBy(order_by), equalOrderBy)){
      case(null){ Debug.trap("Cannot find rbt for this order_by"); };
      case(?rbt){
        switch(RBT.entries(rbt).next()){
          case(null){ { ids = []; next_id = null; } };
          case(?first){
            switch(RBT.entriesRev(rbt).next()){
              case(null){ { ids = []; next_id = null; } };
              case(?last){
                let scan = RBT.scanLimit(rbt, compareIterationKey, Option.get(lower_bound, first.0), Option.get(upper_bound, last.0), direction, limit);
                {
                  ids = Array.map(scan.results, func(key_value: (IterationKey, ())) : Nat { key_value.0.id; });
                  next_id = Option.getMapped(scan.nextKey, func(key : IterationKey) : ?Nat { ?key.id; }, null);
                }
              };
            };
          };
        };
      };
    };
  };

  public func entries(rbts: IterationRBTs, order_by: OrderBy, direction: QueryDirection) : Iter<(IterationKey, ())> {
    switch(Trie.get(rbts, keyOrderBy(order_by), equalOrderBy)){
      case(null){ Debug.trap("Cannot find rbt for this order_by"); };
      case(?rbt){ 
        switch(direction){
          case(#FWD) { RBT.entries(rbt); };
          case(#BWD) { RBT.entriesRev(rbt); };
        };
      };
    };
  };

};