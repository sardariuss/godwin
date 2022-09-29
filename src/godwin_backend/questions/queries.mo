import Types "../types";

import RBT "mo:stableRBT/StableRBTree";

import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Order "mo:base/Order";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Time = Time.Time;
  type Order = Order.Order;
  type Hash = Hash.Hash;
  type Key<K> = Trie.Key<K>;
  type Iter<T> = Iter.Iter<T>;

  // For convenience: from types module
  type Question = Types.Question;
  type Pool = Types.Pool;
  type OrderBy = Types.OrderBy;
  type QueryQuestionsResult = Types.QueryQuestionsResult;
  type Categorization = Types.Categorization;

  // Private types
  type DateEntry = { date: Time; };
  type TextEntry = { text: Text; date: Time; };
  type PoolEntry = { pool: Pool; date: Time; };
  type EndorsementsEntry = { endorsements: Nat; date: Time; };
  type CategorizationEntry = { categorization: Categorization; date: Time; };
  type QuestionKey = {
    id: Nat;
    data: {
      #ID;
      #AUTHOR: TextEntry;
      #TITLE: TextEntry;
      #TEXT: TextEntry;
      #ENDORSEMENTS: EndorsementsEntry;
      #CREATION_DATE: DateEntry;
      #POOL_DATE: PoolEntry;
      #CATEGORIZATION_DATE: CategorizationEntry;
    };
  };
  public type QuestionRBTs = Trie<OrderBy, RBT.Tree<QuestionKey, ()>>;

  // To be able to use OrderBy as key in a Trie
  func toTextOrderBy(order_by: OrderBy) : Text {
    switch(order_by){
      case(#ID){ "ID"; };
      case(#AUTHOR){ "AUTHOR"; };
      case(#TITLE){ "TITLE"; };
      case(#TEXT){ "TEXT"; };
      case(#ENDORSEMENTS){ "ENDORSEMENTS"; };
      case(#CREATION_DATE){ "CREATION_DATE"; };
      case(#POOL_DATE){ "POOL_DATE"; };
      case(#CATEGORIZATION_DATE){ "CATEGORIZATION"; };
    };
  };
  func hashOrderBy(order_by: OrderBy) : Hash { Text.hash(toTextOrderBy(order_by)); };
  func equalOrderBy(a: OrderBy, b: OrderBy) : Bool { a == b; };
  func keyOrderBy(order_by: OrderBy) : Key<OrderBy> { { key = order_by; hash = hashOrderBy(order_by); } };

  // Init functions
  func initQuestionKey(question: Question, order_by: OrderBy) : QuestionKey {
    switch(order_by){
      case(#ID){ { id = question.id; data = #ID; } };
      case(#AUTHOR){ { id = question.id; data = #AUTHOR(initAuthorEntry(question)); } };
      case(#TITLE){ { id = question.id; data = #TITLE(initTitleEntry(question)); } };
      case(#TEXT){ { id = question.id; data = #TEXT(initTextEntry(question)); } };
      case(#ENDORSEMENTS){ { id = question.id; data = #ENDORSEMENTS(initEndorsementsEntry(question)); } };
      case(#CREATION_DATE){ { id = question.id; data = #CREATION_DATE(initDateEntry(question)); } };
      case(#POOL_DATE){ { id = question.id; data = #POOL_DATE(initPoolEntry(question)); } };
      case(#CATEGORIZATION_DATE){ { id = question.id; data = #CATEGORIZATION_DATE(initCategorizationEntry(question)); } };
    };
  };
  func initDateEntry(question: Question) : DateEntry { {date = question.date; }; };
  func initAuthorEntry(question: Question) : TextEntry { { text = Principal.toText(question.author); date = question.date; }; };
  func initTitleEntry(question: Question) : TextEntry { { text = question.title; date = question.date; }; };
  func initTextEntry(question: Question) : TextEntry {{ text = question.text; date = question.date; };};
  func initPoolEntry(question: Question) : PoolEntry { { pool = question.pool.current.pool; date = question.pool.current.date; }; };
  func initEndorsementsEntry(question: Question) : EndorsementsEntry { { endorsements = question.endorsements; date = question.pool.current.date; }; };
  func initCategorizationEntry(question: Question) : CategorizationEntry { 
    { 
      categorization = question.categorization.current.categorization;
      date = question.categorization.current.date;
    };
  };

  // Compare functions
  func compareQuestionKey(a: QuestionKey, b: QuestionKey) : Order {
    let default_order = compareIds(a.id, b.id);
    switch(a.data){
      case(#ID){
        switch(b.data){
          case(#ID){ default_order; };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#AUTHOR(entry_a)){
        switch(b.data){
          case(#AUTHOR(entry_b)){ compareTextEntry(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#TITLE(entry_a)){
        switch(b.data){
          case(#TITLE(entry_b)){ compareTextEntry(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#TEXT(entry_a)){
        switch(b.data){
          case(#TEXT(entry_b)){ compareTextEntry(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#ENDORSEMENTS(entry_a)){
        switch(b.data){
          case(#ENDORSEMENTS(entry_b)){ compareEndorsementsEntry(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#CREATION_DATE(entry_a)){
        switch(b.data){
          case(#CREATION_DATE(entry_b)){ compareDateEntry(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#POOL_DATE(entry_a)){
        switch(b.data){
          case(#POOL_DATE(entry_b)){ comparePoolEntry(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#CATEGORIZATION_DATE(entry_a)){
        switch(b.data){
          case(#CATEGORIZATION_DATE(entry_b)){ compareCategorizationEntry(entry_a, entry_b, default_order); };
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
  func compareDateEntry(a: DateEntry, b: DateEntry, default_order: Order) : Order {
    if (a.date < b.date){ #less;}
    else if (a.date > b.date){ #greater;}
    else { default_order };
  };
  func compareTextEntry(a: TextEntry, b: TextEntry, default_order: Order) : Order {
    switch (Text.compare(a.text, b.text)){
      case(#less){ #less; };
      case(#greater){ #greater; };
      case(#equal){ compareDateEntry(a, b, default_order); };
    };
  };
  func comparePoolEntry(a: PoolEntry, b: PoolEntry, default_order: Order) : Order {
    switch(a.pool){
      case(#SPAWN){
        switch(b.pool){
          case(#SPAWN){ compareDateEntry(a, b, default_order); }; case(#REWARD){ #less; }; case(#ARCHIVE){ #less; };
        };
      };
      case(#REWARD){
        switch(b.pool){
          case(#SPAWN){ #greater; }; case(#REWARD){ compareDateEntry(a, b, default_order); }; case(#ARCHIVE){ #less; };
        };
      };
      case(#ARCHIVE){
        switch(b.pool){
          case(#SPAWN){ #greater; }; case(#REWARD){ #greater; }; case(#ARCHIVE){ compareDateEntry(a, b, default_order); };
        };
      };
    };
  };
  func compareEndorsementsEntry(a: EndorsementsEntry, b: EndorsementsEntry, default_order: Order) : Order {
    if (a.endorsements < b.endorsements){ #less; }
    else if (a.endorsements > b.endorsements){ #greater;}
    else { compareDateEntry(a, b, default_order); };
  };
  func compareCategorizationEntry(a: CategorizationEntry, b: CategorizationEntry, default_order: Order) : Order {
    switch(a.categorization){
      case(#PENDING){
        switch(b.categorization){
          case(#PENDING){ compareDateEntry(a, b, default_order); }; case(#ONGOING(_)){ #less; }; case(#DONE(_)){ #less; };
        };
      };
      case(#ONGOING(_)){
        switch(b.categorization){
          case(#PENDING){ #greater; }; case(#ONGOING(_)){ compareDateEntry(a, b, default_order); }; case(#DONE(_)){ #less; };
        };
      };
      case(#DONE(_)){
        switch(b.categorization){
          case(#PENDING){ #greater; }; case(#ONGOING(_)){ #greater; }; case(#DONE(_)){ compareDateEntry(a, b, default_order); };
        };
      };
    };
  };

  // Public functions

  public func init() : QuestionRBTs { 
    var rbts = Trie.empty<OrderBy, RBT.Tree<QuestionKey, ()>>();
    rbts := addOrderBy(rbts, #ID);
    rbts;
  };

  // @todo: this is done for optimization (mostly to reduce memory usage) but brings some issues:
  // (queryQuestions and entries can trap). Alternative would be to init with every OrderBy
  // possible in init method.
  public func addOrderBy(rbts: QuestionRBTs, order_by: OrderBy) : QuestionRBTs {
    Trie.put(rbts, keyOrderBy(order_by), equalOrderBy, RBT.init<QuestionKey, ()>()).0;
  };

  public func add(rbts: QuestionRBTs, new_question: Question) : QuestionRBTs {
    var new_rbts = rbts;
    for ((order_by, rbt) in Trie.iter(rbts)){
      let new_rbt = RBT.put(rbt, compareQuestionKey, initQuestionKey(new_question, order_by), ());
      new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
    };
    new_rbts;
  };

  public func replace(rbts: QuestionRBTs, old_question: Question, new_question: Question) : QuestionRBTs {
    var new_rbts = rbts;
    for ((order_by, rbt) in Trie.iter(rbts)){
      let old_key = initQuestionKey(old_question, order_by);
      let new_key = initQuestionKey(new_question, order_by);
      if (compareQuestionKey(old_key, new_key) != #equal){
        var new_rbt = RBT.remove(rbt, compareQuestionKey, old_key).1;
        new_rbt := RBT.put(new_rbt, compareQuestionKey, new_key, ());
        new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
      };
    };
    new_rbts;
  };

  public func remove(rbts: QuestionRBTs, old_question: Question) : QuestionRBTs {
    var new_rbts = rbts;
    for ((order_by, rbt) in Trie.iter(rbts)){
      let new_rbt = RBT.remove(rbt, compareQuestionKey, initQuestionKey(old_question, order_by)).1;
      new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
    };
    new_rbts;
  };

  // @todo: if lower or upper bound QuestionKey data is not of the same type as OrderBy, what happens ? traps ?
  public func queryQuestions(
    rbts: QuestionRBTs,
    order_by: OrderBy,
    lower_bound: ?QuestionKey,
    upper_bound: ?QuestionKey,
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
                let scan = RBT.scanLimit(rbt, compareQuestionKey, Option.get(lower_bound, first.0), Option.get(upper_bound, last.0), direction, limit);
                {
                  ids = Array.map(scan.results, func(key_value: (QuestionKey, ())) : Nat { key_value.0.id; });
                  next_id = Option.getMapped(scan.nextKey, func(key : QuestionKey) : ?Nat { ?key.id; }, null);
                }
              };
            };
          };
        };
      };
    };
  };

  public func entries(rbts: QuestionRBTs, order_by: OrderBy) : Iter<(QuestionKey, ())> {
    switch(Trie.get(rbts, keyOrderBy(order_by), equalOrderBy)){
      case(null){ Debug.trap("Cannot find rbt for this order_by"); };
      case(?rbt){ RBT.entries(rbt); };
    };
  };

  public func entriesRev(rbts: QuestionRBTs, order_by: OrderBy) : Iter<(QuestionKey, ())> {
    switch(Trie.get(rbts, keyOrderBy(order_by), equalOrderBy)){
      case(null){ Debug.trap("Cannot find rbt for this order_by"); };
      case(?rbt){ RBT.entriesRev(rbt); };
    };
  };

};