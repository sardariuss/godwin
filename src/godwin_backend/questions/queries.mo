import Types "../types";
import Question "question";

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
import Float "mo:base/Float";
import Int "mo:base/Int";
import Nat32 "mo:base/Nat32";

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
  type Status = Types.Status;

  // Public types
  public type OrderBy = {
    #ID;
    #AUTHOR;
    #TITLE;
    #TEXT;
    #CREATION_DATE;
    #STATUS_DATE: Status;
    #INTEREST;
  };

  public type QueryQuestionsResult = { ids: [Nat32]; next_id: ?Nat32 };
  public type QueryDirection = {
    #FWD;
    #BWD;
  };
  public type QuestionKey = {
    id: Nat32;
    data: {
      #ID;
      #AUTHOR: TextEntry;
      #TITLE: TextEntry;
      #TEXT: TextEntry;
      #CREATION_DATE: DateEntry;
      #STATUS_DATE: DateEntry;
      #INTEREST: InterestEntry;
    };
  };

  // Private types
  type DateEntry = { date: Time; };
  type TextEntry = { text: Text; date: Time; };
  type InterestEntry = Int;
  type StatusDateEntry = {
    status: Status;
    date: Int;
  };
  public type QuestionRBTs = Trie<OrderBy, RBT.Tree<QuestionKey, ()>>;

  // To be able to use OrderBy as key in a Trie
  func toTextOrderBy(order_by: OrderBy) : Text {
    switch(order_by){
      case(#ID){ "ID"; };
      case(#AUTHOR){ "AUTHOR"; };
      case(#TITLE){ "TITLE"; };
      case(#TEXT){ "TEXT"; };
      case(#CREATION_DATE){ "CREATION_DATE"; };
      case(#STATUS_DATE(status)) { 
        switch(status){
          case(#CANDIDATE) { "CANDIDATE"; };
          case(#OPEN(#OPINION)) { "OPEN_OPINION"; };
          case(#OPEN(#CATEGORIZATION)) { "OPEN_CATEGORIZATION"; };
          case(#CLOSED) { "CLOSED"; };
          case(#REJECTED) { "REJECTED"; };
        };
      };
      case(#INTEREST) { "INTEREST"; };
    };
  };
  func hashOrderBy(order_by: OrderBy) : Hash { Text.hash(toTextOrderBy(order_by)); };
  func equalOrderBy(a: OrderBy, b: OrderBy) : Bool { a == b; };
  func keyOrderBy(order_by: OrderBy) : Key<OrderBy> { { key = order_by; hash = hashOrderBy(order_by); } };

  // Init functions
  func initQuestionKey(question: Question, order_by: OrderBy) : ?QuestionKey {
    switch(order_by){
      case(#ID){ ?{ id = question.id; data = #ID; } };
      case(#AUTHOR){ initAuthorEntry(question); };
      case(#TITLE){ initTitleEntry(question); };
      case(#TEXT){ initTextEntry(question); };
      case(#CREATION_DATE){ initDateEntry(question); };
      case(#STATUS_DATE(status)) { initStatusDateEntry(status, question); };
      case(#INTEREST) { initInterestEntry(question); };
    };
  };
  func initDateEntry(question: Question) : ?QuestionKey { ?{ id = question.id; data = #CREATION_DATE({date = question.date; }); }};
  func initAuthorEntry(question: Question) : ?QuestionKey { ?{ id = question.id; data = #AUTHOR({ text = Principal.toText(question.author); date = question.date; }); }};
  func initTitleEntry(question: Question) : ?QuestionKey { ?{ id = question.id; data = #TITLE({ text = question.title; date = question.date; }); }};
  func initTextEntry(question: Question) : ?QuestionKey { ?{ id = question.id; data = #TEXT({ text = question.text; date = question.date; }); }};

  func initStatusDateEntry(status: Status, question: Question) : ?QuestionKey {
    if (Question.getStatus(question) != status) { return null; };
    ?{ id = question.id; data = #STATUS_DATE({ date = Question.unwrapStatusDate(question); }) };
  };

  func initInterestEntry(question: Question) : ?QuestionKey {
    switch(question.status){
      case(#CANDIDATE(vote)) { ?{ id = question.id; data = #INTEREST(vote.aggregate.score); }; };
      case(_) { null; };
    };
  };

//  func initCreationHotEntry(question: Question) : CreationHotEntry { 
//    // When based on creation date, the hot algorithm assumes the date is in the past
//    // @todo: cannot do assert(question.date <= Time.now()) here because it prevents from running the tests
//    // Based on: https://medium.com/hacking-and-gonzo/how-reddit-ranking-algorithms-work-ef111e33d0d9
//    // @todo: find out if the division coefficient (currently 45000) makes sense for godwin
//    Float.log(Float.max(Float.fromInt(question.interests.score), 1.0)) / 2.303 + Float.fromInt(question.date * 1_000_000_000) / 45000.0;
//  };

  // Compare functions
  func compareQuestionKey(a: QuestionKey, b: QuestionKey) : Order {
    let default_order = Nat32.compare(a.id, b.id);
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
      case(#CREATION_DATE(entry_a)){
        switch(b.data){
          case(#CREATION_DATE(entry_b)){ compareDateEntry(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#STATUS_DATE(entry_a)){
        switch(b.data){
          case(#STATUS_DATE(entry_b)){ compareDateEntry(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#INTEREST(entry_a)){
        switch(b.data){
          case(#INTEREST(entry_b)) { compareInt(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
    };
  };

  func compare<T>(a: T, b: T, compare: (T, T) -> Order, on_equality: Order) : Order {
    switch(compare(a, b)){
      case(#greater) { #greater; };
      case(#less) { #less; };
      case(#equal) { on_equality; };     
    };
  };
  func compareDateEntry(a: DateEntry, b: DateEntry, default_order: Order) : Order {
    compare<Int>(a.date, b.date, Int.compare, default_order);
  };
  func compareInt(a: Int, b: Int, default_order: Order) : Order {
    compare<Int>(a, b, Int.compare, default_order);
  };
  func compareTextEntry(a: TextEntry, b: TextEntry, default_order: Order) : Order {
    compare<Text>(a.text, b.text, Text.compare, compareDateEntry(a, b, default_order));
  };

  // Public functions

  public func init() : QuestionRBTs { 
    Trie.empty<OrderBy, RBT.Tree<QuestionKey, ()>>();
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
      // Add the new key
      Option.iterate(initQuestionKey(new_question, order_by), func(question_key: QuestionKey) {
        let new_rbt = RBT.put(rbt, compareQuestionKey, question_key, ());
        new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
      });
    };
    new_rbts;
  };

  // @todo: once tested, use add and remove instead
  public func replace(rbts: QuestionRBTs, old_question: Question, new_question: Question) : QuestionRBTs {
    var new_rbts = rbts;
    for ((order_by, rbt) in Trie.iter(rbts)){
      // Remove the old key
      Option.iterate(initQuestionKey(old_question, order_by), func(question_key: QuestionKey) {
        let new_rbt = RBT.remove(rbt, compareQuestionKey, question_key).1;
        new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
      });
      // Add the new key
      Option.iterate(initQuestionKey(new_question, order_by), func(question_key: QuestionKey) {
        let new_rbt = RBT.put(rbt, compareQuestionKey, question_key, ());
        new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
      });
    };
    new_rbts;
  };

  public func remove(rbts: QuestionRBTs, old_question: Question) : QuestionRBTs {
    var new_rbts = rbts;
    for ((order_by, rbt) in Trie.iter(rbts)){
      // Remove the old key
      Option.iterate(initQuestionKey(old_question, order_by), func(question_key: QuestionKey) {
        let new_rbt = RBT.remove(rbt, compareQuestionKey, question_key).1;
        new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
      });
    };
    new_rbts;
  };

  // @todo: if lower or upper bound QuestionKey data is not of the same type as OrderBy, what happens ? traps ?
  // @todo: fix lower_bound and upper_bound should not require the question id...
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
                  ids = Array.map(scan.results, func(key_value: (QuestionKey, ())) : Nat32 { key_value.0.id; });
                  next_id = Option.getMapped(scan.nextKey, func(key : QuestionKey) : ?Nat32 { ?key.id; }, null);
                }
              };
            };
          };
        };
      };
    };
  };

  public func entries(rbts: QuestionRBTs, order_by: OrderBy, direction: QueryDirection) : Iter<(QuestionKey, ())> {
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