import Types "../types";
import WMap "../wrappers/WMap";
import Question "question";
import OrderedSet "../OrderedSet";

import Map "mo:map/Map";

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
import Nat "mo:base/Nat";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Time = Time.Time;
  type Order = Order.Order;
  type Hash = Hash.Hash;
  type Key<K> = Trie.Key<K>;
  type Iter<T> = Iter.Iter<T>;
  type OrderedSet<K> = OrderedSet.OrderedSet<K>;
  
  public type Direction = OrderedSet.Direction;

  type WMap<K, V> = WMap.WMap<K, V>;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;
  let { thash } = Map;
  func hashOrderBy(order_by: OrderBy) : Nat { thash.0(toTextOrderBy(order_by)); };
  func equalOrderBy(a: OrderBy, b: OrderBy) : Bool { thash.1(toTextOrderBy(a), toTextOrderBy(b)); };
  let orderbyhash : Map.HashUtils<OrderBy> = ( func(a) = hashOrderBy(a), func(a, b) = equalOrderBy(a, b));

  // For convenience: from types module
  type Question = Types.Question;
  type Status = Types.Status;

  // Public types
  public type OrderBy = {
    #AUTHOR;
    #TITLE;
    #TEXT;
    #CREATION_DATE;
    #STATUS_DATE: Status;
    #INTEREST;
    #INTEREST_HOT;
  };

  public type QueryQuestionsResult = { ids: [Nat]; next_id: ?Nat };
  
  public type QuestionKey = {
    id: Nat;
    data: {
      #AUTHOR: TextEntry;
      #TITLE: TextEntry;
      #TEXT: TextEntry;
      #CREATION_DATE: DateEntry;
      #STATUS_DATE: DateEntry;
      #INTEREST: InterestEntry;
      #INTEREST_HOT: InterestHotEntry;
    };
  };

  // Private types
  type DateEntry = { date: Time; };
  type TextEntry = { text: Text; date: Time; };
  type InterestEntry = Int;
  type InterestHotEntry = Float;
  type StatusDateEntry = {
    status: Status;
    date: Int;
  };

  // To be able to use OrderBy as key in a Trie
  func toTextOrderBy(order_by: OrderBy) : Text {
    switch(order_by){
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
      case(#INTEREST_HOT) { "INTEREST_HOT"; };
    };
  };
  //func hashOrderBy(order_by: OrderBy) : Hash { Text.hash(toTextOrderBy(order_by)); };
  //func equalOrderBy(a: OrderBy, b: OrderBy) : Bool { a == b; };
  //func keyOrderBy(order_by: OrderBy) : Key<OrderBy> { { key = order_by; hash = hashOrderBy(order_by); } };

  // Init functions
  public func initQuestionKey(question: Question, order_by: OrderBy) : ?QuestionKey {
    switch(order_by){
      case(#AUTHOR){ initAuthorEntry(question); };
      case(#TITLE){ initTitleEntry(question); };
      case(#TEXT){ initTextEntry(question); };
      case(#CREATION_DATE){ initDateEntry(question); };
      case(#STATUS_DATE(status)) { initStatusDateEntry(status, question); };
      case(#INTEREST) { initInterestEntry(question); };
      case(#INTEREST_HOT) { initInterestHotEntry(question); };
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

  func initInterestHotEntry(question: Question) : ?QuestionKey {
    switch(question.status){
      case(#CANDIDATE(vote)) { 
        // When based on creation date, the hot algorithm assumes the date is in the past
        // @todo: cannot do assert(question.date <= Time.now()) here because it prevents from running the tests
        // Based on: https://medium.com/hacking-and-gonzo/how-reddit-ranking-algorithms-work-ef111e33d0d9
        // @todo: find out if the division coefficient (currently 45000) makes sense for godwin
        let hot = Float.log(Float.max(Float.fromInt(vote.aggregate.score), 1.0)) / 2.303 + Float.fromInt(vote.date * 1_000_000_000) / 45000.0;
        ?{ id = question.id; data = #INTEREST_HOT(hot); }; 
      };
      case(_) { null; };
    };
  };

  // Compare functions
  func compareQuestionKey(a: QuestionKey, b: QuestionKey) : Order {
    let default_order = Nat.compare(a.id, b.id);
    switch(a.data){
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
      case(#INTEREST_HOT(entry_a)){
        switch(b.data){
          case(#INTEREST_HOT(entry_b)) { compareFloat(entry_a, entry_b, default_order); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
    };
  };

  func equalOptKeys(a: ?QuestionKey, b: ?QuestionKey) : Bool {
    switch(a){
      case(null) {
        switch(b){
          case(null) { true; };
          case(_) { false; };
        };
      };
      case(?q1) {
        switch(b){
          case(null) { false; };
          case(?q2) { compareQuestionKey(q1, q2) == #equal; };
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
  func compareFloat(a: Float, b: Float, default_order: Order) : Order {
    compare<Float>(a, b, Float.compare, default_order);
  };

  // Public functions

  public func addOrderBy(register: Map<OrderBy, OrderedSet<QuestionKey>>, order_by: OrderBy) {
    Map.set(register, orderbyhash, order_by, OrderedSet.init<QuestionKey>());
  };

  // @todo: this is done for optimization (mostly to reduce memory usage) but brings some issues:
  // (queryQuestions and entries can trap). Alternative would be to init with every OrderBy
  // possible in init method.
  public func initRegister() : Map<OrderBy, OrderedSet<QuestionKey>> {
    let register = Map.new<OrderBy, OrderedSet<QuestionKey>>();
    addOrderBy(register, #TITLE);
    addOrderBy(register, #CREATION_DATE);
    addOrderBy(register, #STATUS_DATE(#CANDIDATE));
    addOrderBy(register, #STATUS_DATE(#OPEN(#OPINION)));
    addOrderBy(register, #STATUS_DATE(#OPEN(#CATEGORIZATION)));
    addOrderBy(register, #STATUS_DATE(#CLOSED));
    addOrderBy(register, #STATUS_DATE(#REJECTED));
    addOrderBy(register, #INTEREST);
    register;
  };

  public func build(register: Map<OrderBy, OrderedSet<QuestionKey>>) : Queries {
    Queries(WMap.WMap(register, orderbyhash));
  };

  public class Queries(register_: WMap<OrderBy, OrderedSet<QuestionKey>>) {
  
    public func add(new_question: Question) {
      register_.forEach(func(order_by, rbt){
        // Add the new key
        Option.iterate(initQuestionKey(new_question, order_by), func(question_key: QuestionKey) {
          let new_rbt = OrderedSet.put(rbt, compareQuestionKey, question_key);
          register_.set(order_by, new_rbt);
        });
      });
    };
  
    // @todo: the keys could use the Questions #UpdateType
    public func replace(old_question: ?Question, new_question: ?Question) {
      Option.iterate(old_question, func(old: Question) { remove(old); });
      Option.iterate(new_question, func(new: Question) { add(new);    });
//      register_.forEach(func(order_by, rbt){
//        let old_key = initQuestionKey(old_question, order_by);
//        let new_key = initQuestionKey(new_question, order_by);
//        if (not equalOptKeys(old_key, new_key)){
//          var single_rbt = rbt;
//          // Remove the old key
//          Option.iterate(old_key, func(question_key: QuestionKey) {
//            single_rbt := OrderedSet.delete(single_rbt, compareQuestionKey, question_key);
//          });
//          // Add the new key
//          Option.iterate(new_key, func(question_key: QuestionKey) {
//            single_rbt := OrderedSet.put(single_rbt, compareQuestionKey, question_key);
//          });
//          register_.set(order_by, single_rbt);
//        };
//      });
    };
  
    public func remove(old_question: Question) {
      register_.forEach(func(order_by, rbt){
        // Remove the old key
        Option.iterate(initQuestionKey(old_question, order_by), func(question_key: QuestionKey) {
          let new_rbt = OrderedSet.delete(rbt, compareQuestionKey, question_key);
          register_.set(order_by, new_rbt);
        });
      });
    };
  
    // @todo: if lower or upper bound QuestionKey data is not of the same type as OrderBy, what happens ? traps ?
    // @todo: fix lower_bound and upper_bound should not require the question id...
    public func queryQuestions(
      order_by: OrderBy,
      lower_bound: ?QuestionKey,
      upper_bound: ?QuestionKey,
      direction: Direction,
      limit: Nat
    ) : QueryQuestionsResult {
      switch(register_.get(order_by)){
        case(null){ Debug.trap("Cannot find rbt for this order_by"); };
        case(?rbt){
          switch(OrderedSet.keys(rbt).next()){
            case(null){ { ids = []; next_id = null; } };
            case(?first){
              switch(OrderedSet.keysRev(rbt).next()){
                case(null){ { ids = []; next_id = null; } };
                case(?last){
                  let scan = OrderedSet.scanLimit(rbt, compareQuestionKey, Option.get(lower_bound, first), Option.get(upper_bound, last), direction, limit);
                  {
                    ids = Array.map(scan.keys, func(key: QuestionKey) : Nat { key.id; });
                    next_id = Option.getMapped(scan.next, func(key : QuestionKey) : ?Nat { ?key.id; }, null);
                  }
                };
              };
            };
          };
        };
      };
    };
  
    public func entries(order_by: OrderBy, direction: Direction) : Iter<QuestionKey> {
      switch(register_.get(order_by)){
        case(null){ Debug.trap("Cannot find rbt for this order_by"); };
        case(?rbt){ 
          OrderedSet.iter(rbt, direction);
        };
      };
    };

  };

};