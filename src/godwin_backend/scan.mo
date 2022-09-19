import Types "types";
import Pool "pool";
import Questions "questions";

import RBT "mo:stableRBT/StableRBTree";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Order "mo:base/Order";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Array "mo:base/Array";
import Hash "mo:base/Hash";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Time = Time.Time;
  type Order = Order.Order;
  type Iter<T> = Iter.Iter<T>;
  type Hash = Hash.Hash;
  type Key<K> = Trie.Key<K>;

  // For convenience: from types module
  type Question = Types.Question;
  type Categorization = Types.Categorization;
  type Pool = Types.Pool;

  type TestKey = {
    id: Nat;
    data: {
      #AUTHOR: TextEntry;
      #TITLE: TextEntry;
      #TEXT: TextEntry;
      #ENDORSEMENTS: EndorsementsEntry;
      #CREATION_DATE: DateEntry;
      #POOL_DATE: PoolEntry;
    };
  };

  func compareTestKey(a: TestKey, b: TestKey) : Order {
    switch(a.data){
      case(#AUTHOR(entry_a)){
        switch(b.data){
          case(#AUTHOR(entry_b)){ compareTextEntry(entry_a, entry_b); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#TITLE(entry_a)){
        switch(b.data){
          case(#TITLE(entry_b)){ compareTextEntry(entry_a, entry_b); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#TEXT(entry_a)){
        switch(b.data){
          case(#TEXT(entry_b)){ compareTextEntry(entry_a, entry_b); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#ENDORSEMENTS(entry_a)){
        switch(b.data){
          case(#ENDORSEMENTS(entry_b)){ compareEndorsementsEntry(entry_a, entry_b); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#CREATION_DATE(entry_a)){
        switch(b.data){
          case(#CREATION_DATE(entry_b)){ compareDateEntry(entry_a, entry_b); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
      case(#POOL_DATE(entry_a)){
        switch(b.data){
          case(#POOL_DATE(entry_b)){ comparePoolEntry(entry_a, entry_b); };
          case(_){Debug.trap("Cannot compare entries of different types")};
        };
      };
    };
  };

  func initTestKey(question: Question, order_by: OrderBy) : TestKey {
    switch(order_by){
      case(#AUTHOR){ { id = question.id; data = #AUTHOR(initAuthorEntry(question)); } };
      case(#TITLE){ { id = question.id; data = #TITLE(initTitleEntry(question)); } };
      case(#TEXT){ { id = question.id; data = #TEXT(initTextEntry(question)); } };
      case(#ENDORSEMENTS){ { id = question.id; data = #ENDORSEMENTS(initEndorsementsEntry(question)); } };
      case(#CREATION_DATE){ { id = question.id; data = #CREATION_DATE(initDateEntry(question)); } };
      case(#POOL_DATE){ { id = question.id; data = #POOL_DATE(initPoolEntry(question)); } };
    };
  };

  type DateEntry = {
    date: Time;
    id: Nat;
  };

  func compareDateEntry(a: DateEntry, b: DateEntry) : Order {
    if (a.date < b.date){ #less;}
    else if (a.date > b.date){ #greater;}
    else {
      if (a.id < b.id){ #less;}
      else if (a.id > b.id){ #greater;}
      else { #equal;}  
    };
  };

  func initDateEntry(question: Question) : DateEntry {
    {
      date = question.pool.history[0].date;
      id = question.id;
    };
  };

  type TextEntry = {
    text: Text;
    date: Time;
    id: Nat;
  };

  func compareTextEntry(a: TextEntry, b: TextEntry) : Order {
    switch (Text.compare(a.text, b.text)){
      case(#less){ #less; };
      case(#greater){ #greater; };
      case(#equal){ compareDateEntry(a, b); };
    };
  };

  func initAuthorEntry(question: Question) : TextEntry {
    {
      text = Principal.toText(question.author);
      date = question.pool.history[0].date;
      id = question.id;
    };
  };

  func initTitleEntry(question: Question) : TextEntry {
    {
      text = question.title;
      date = question.pool.history[0].date;
      id = question.id;
    };
  };

  func initTextEntry(question: Question) : TextEntry {
    {
      text = question.text;
      date = question.pool.history[0].date;
      id = question.id;
    };
  };

  type PoolEntry = {
    pool: Pool;
    date: Time;
    id: Nat;
  };

  func comparePoolEntry(a: PoolEntry, b: PoolEntry) : Order {
    switch(a.pool){
      case(#SPAWN){
        switch(b.pool){
          case(#SPAWN){ compareDateEntry(a, b); };
          case(#REWARD){ #less; };
          case(#ARCHIVE){ #less; };
        };
      };
      case(#REWARD){
        switch(b.pool){
          case(#SPAWN){ #greater; };
          case(#REWARD){ compareDateEntry(a, b); };
          case(#ARCHIVE){ #less; };
        };
      };
      case(#ARCHIVE){
        switch(b.pool){
          case(#SPAWN){ #greater; };
          case(#REWARD){ #greater; };
          case(#ARCHIVE){ compareDateEntry(a, b); };
        };
      };
    };
  };

  func initPoolEntry(question: Question) : PoolEntry {
    {
      pool = question.pool.current.pool;
      date = question.pool.current.date;
      id = question.id;
    };
  };

  type EndorsementsEntry = {
    endorsements: Nat;
    date: Time;
    id: Nat;
  };

  func compareEndorsementsEntry(a: EndorsementsEntry, b: EndorsementsEntry) : Order {
    if (a.endorsements < b.endorsements){ #less; }
    else if (a.endorsements > b.endorsements){ #greater;}
    else { compareDateEntry(a, b); };
  };

  func initEndorsementsEntry(question: Question) : EndorsementsEntry {
    {
      endorsements = question.endorsements;
      date = question.pool.current.date;
      id = question.id;
    };
  };

  public type OrderBy = {
    #AUTHOR;
    #TITLE;
    #TEXT;
    #ENDORSEMENTS;
    #CREATION_DATE;
    #POOL_DATE;
  };

  public func toTextOrderBy(order_by: OrderBy) : Text {
    switch(order_by){
      case(#AUTHOR){ "AUTHOR"; };
      case(#TITLE){ "TITLE"; };
      case(#TEXT){ "TEXT"; };
      case(#ENDORSEMENTS){ "ENDORSEMENTS"; };
      case(#CREATION_DATE){ "CREATION_DATE"; };
      case(#POOL_DATE){ "POOL_DATE"; };
    };
  };

  public func hashOrderBy(order_by: OrderBy) : Hash.Hash { 
    Text.hash(toTextOrderBy(order_by));
  };

  public func equalOrderBy(a: OrderBy, b: OrderBy) : Bool {
    a == b;
  };

  public func keyOrderBy(order_by: OrderBy) : Key<OrderBy> {
    return { key = order_by; hash = hashOrderBy(order_by); }
  };

  public type TestRegister = Trie<OrderBy, RBT.Tree<TestKey, ()>>;
    
  public type Register = {
    by_author: ?RBT.Tree<TextEntry, ()>;
    by_title: ?RBT.Tree<TextEntry, ()>;
    by_text: ?RBT.Tree<TextEntry, ()>;
    by_endorsements: ?RBT.Tree<EndorsementsEntry, ()>;
    by_creation_date: ?RBT.Tree<DateEntry, ()>;
    by_pool: ?RBT.Tree<PoolEntry, ()>;
  };

  public func init() : TestRegister {
    Trie.empty<OrderBy, RBT.Tree<TestKey, ()>>();
  };

  public func addOrderBy(register: TestRegister, order_by: OrderBy) : TestRegister {
    Trie.put(register, keyOrderBy(order_by), equalOrderBy, RBT.init<TestKey, ()>()).0;
  };

  public func add(register: TestRegister, new_question: Question) : TestRegister {
    var new_register = register;
    for ((order_by, rbt) in Trie.iter(register)){
      let new_rbt = RBT.put(rbt, compareTestKey, initTestKey(new_question, order_by), ());
      new_register := Trie.put(new_register, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
    };
    new_register;
  };

  public func replace(register: TestRegister, old_question: Question, new_question: Question) : TestRegister {
    var new_register = register;
    for ((order_by, rbt) in Trie.iter(register)){
      let old_key = initTestKey(old_question, order_by);
      let new_key = initTestKey(new_question, order_by);
      if (compareTestKey(old_key, new_key) != #equal){
        var new_rbt = RBT.remove(rbt, compareTestKey, old_key).1;
        new_rbt := RBT.put(new_rbt, compareTestKey, new_key, ());
        new_register := Trie.put(new_register, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
      };
    };
    new_register;
  };

  public func remove(register: TestRegister, old_question: Question) : TestRegister {
    var new_register = register;
    for ((order_by, rbt) in Trie.iter(register)){
      let new_rbt = RBT.remove(rbt, compareTestKey, initTestKey(old_question, order_by)).1;
      new_register := Trie.put(new_register, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
    };
    new_register;
  };

  public type TestKeyBounds = {
    lower_bound: ?TestKey; 
    upper_bound: ?TestKey;
  };

  public type RequestResult = { results: [Nat]; next: ?Nat };

  public func get(register: TestRegister, order_by: OrderBy, lower_bound: ?TestKey, upper_bound: ?TestKey, direction: RBT.Direction, limit: Nat) : ?RequestResult {
    switch(Trie.get(register, keyOrderBy(order_by), equalOrderBy)){
      case(null){ null; };
      case(?rbt){
        switch(RBT.entries(rbt).next()){
          case(null){ ?{ results = []; next = null; } };
          case(?first){
            switch(RBT.entriesRev(rbt).next()){
              case(null){ ?{ results = []; next = null; } };
              case(?last){
                let scan = RBT.scanLimit(rbt, compareTestKey, Option.get(lower_bound, first.0), Option.get(upper_bound, last.0), direction, limit);
                let results = Array.map(scan.results, func(key_value: (TestKey, ())) : Nat {
                  switch(key_value.0.data){
                    case(#AUTHOR(entry)){ entry.id; };
                    case(#CREATION_DATE(entry)){ entry.id; };
                    case(#ENDORSEMENTS(entry)){ entry.id; };
                    case(#POOL_DATE(entry)){ entry.id; };
                    case(#TEXT(entry)){ entry.id; };
                    case(#TITLE(entry)){ entry.id; };
                  };
                });
                var next : ?Nat = null;
                switch(scan.nextKey){
                  case(null){};
                  case(?key){ 
                    switch(key.data){
                      case(#AUTHOR(entry)){ next := ?entry.id; };
                      case(#CREATION_DATE(entry)){ next := ?entry.id; };
                      case(#ENDORSEMENTS(entry)){ next := ?entry.id; };
                      case(#POOL_DATE(entry)){ next := ?entry.id; };
                      case(#TEXT(entry)){ next := ?entry.id; };
                      case(#TITLE(entry)){ next := ?entry.id; };
                    };
                  };
                };
                ?{ results; next; };
              };
            };
          };
        };
      };
    };
  };

};