import Types      "Types";
import Queries    "../utils/Queries";

import Map        "mo:map/Map";

import Order      "mo:base/Order";
import Int        "mo:base/Int";
import Nat        "mo:base/Nat";
import Debug      "mo:base/Debug";
import Text       "mo:base/Text";
import Principal  "mo:base/Principal";
import Option     "mo:base/Option";
import Float      "mo:base/Float";

module {

  type Map<K, V> = Map.Map<K, V>;
  type Queries<OrderBy, Key> = Queries.Queries<OrderBy, Key>;
  type Order = Order.Order;
  type Time = Int;
  type Question = Types.Question;
  type Status = Types.Status;

  // @todo: AUTHOR, TEXT and DATE are not used
  public type OrderBy = {
    #AUTHOR;
    #TEXT;
    #DATE;
    #STATUS: Status;
    #INTEREST_SCORE;
  };

  public type Key = {
    #AUTHOR: AuthorEntry;
    #TEXT: TextEntry;
    #DATE: DateEntry;
    #STATUS: StatusEntry;
    #INTEREST_SCORE: InterestScore;
  };

  type DateEntry = { question_id: Nat; date: Time; };
  type TextEntry = { question_id: Nat; text: Text; date: Time; };
  type AuthorEntry = { question_id: Nat; author: Principal; date: Time; };
  type StatusEntry = { question_id: Nat; status: Status; date: Int; };
  type InterestScore = { question_id: Nat; score: Float; };

  public type Register = Queries.Register<OrderBy, Key>;
  public type QuestionQueries = Queries.Queries<OrderBy, Key>;
  public type Direction = Queries.Direction;
  public type ScanLimitResult = Queries.ScanLimitResult;

  public func initRegister() : Register {
    Queries.initRegister<OrderBy, Key>();
  };

  public func addOrderBy(register: Register, order_by: OrderBy) {
    Queries.addOrderBy(register, orderByHash, order_by);
  };

  public func build(register: Register) : QuestionQueries {

    addOrderBy(register, #STATUS(#CANDIDATE));
    addOrderBy(register, #STATUS(#OPEN));
    addOrderBy(register, #STATUS(#CLOSED));
    addOrderBy(register, #STATUS(#REJECTED));
    addOrderBy(register, #INTEREST_SCORE);

    let queries = Queries.build<OrderBy, Key>(
      register,
      orderByHash,
      compareKeys,
      toOrderBy,
      getKeyIdentifier
    );

    queries;
  };

  func toTextOrderBy(order_by: OrderBy) : Text {
    switch(order_by){
      case(#AUTHOR)         { "AUTHOR"; };
      case(#TEXT)           { "TEXT"; };
      case(#DATE)           { "DATE"; };
      case(#STATUS(status)){ 
        switch(status){
          case(#CANDIDATE)  { "CANDIDATE"; };
          case(#OPEN)       { "OPEN"; };
          case(#CLOSED)     { "CLOSED"; };
          case(#REJECTED)   { "REJECTED"; };
        };
      };
      case(#INTEREST_SCORE) { "INTEREST_SCORE"; };
    };
  };

  func hashOrderBy(a: OrderBy) : Nat { Map.thash.0(toTextOrderBy(a)); };
  func equalOrderBy(a: OrderBy, b: OrderBy) : Bool { Map.thash.1(toTextOrderBy(a), toTextOrderBy(b)); };
  let orderByHash : Map.HashUtils<OrderBy> = ( func(a) = hashOrderBy(a), func(a, b) = equalOrderBy(a, b) );

  func toOrderBy(key: Key) : OrderBy {
    switch(key){
      case(#AUTHOR(_)){ #AUTHOR; };
      case(#TEXT(_)){ #TEXT; };
      case(#DATE(_)){ #DATE; };
      case(#STATUS(entry)) { #STATUS(entry.status); };
      case(#INTEREST_SCORE(_)) { #INTEREST_SCORE; };
    };
  };

  func compareKeys(a: Key, b: Key) : Order {
    switch(toOrderBy(a)){
      case(#AUTHOR){ compareAuthorEntries(unwrapAuthor(a), unwrapAuthor(b)); };
      case(#TEXT){ compareTextEntries(unwrapText(a), unwrapText(b)); };
      case(#DATE){ compareDateEntries(unwrapDateEntry(a), unwrapDateEntry(b)); };
      case(#STATUS(_)){ compareDateEntries(unwrapStatusEntry(a), unwrapStatusEntry(b)); }; // @todo: Status entries could be of different types (but should not happen anyway)
      case(#INTEREST_SCORE) { compareInterestScores(unwrapInterestScore(a), unwrapInterestScore(b)); };
    };
  };

  func getKeyIdentifier(key: Key) : Nat {
    switch(key){
      case(#AUTHOR(entry)) { entry.question_id; };
      case(#TEXT(entry)) { entry.question_id; };
      case(#DATE(entry)) { entry.question_id; };
      case(#STATUS(entry)) { entry.question_id; };
      case(#INTEREST_SCORE(entry)) { entry.question_id; };
    };
  };

  func unwrapAuthor(key: Key) : AuthorEntry {
    switch(key){
      case(#AUTHOR(entry)) { entry; };
      case(_) { Debug.trap("Failed to unwrap author"); };
    };
  };
  func unwrapText(key: Key) : TextEntry {
    switch(key){
      case(#TEXT(entry)) { entry; };
      case(_) { Debug.trap("Failed to unwrap text"); };
    };
  };
  func unwrapDateEntry(key: Key) : DateEntry {
    switch(key){
      case(#DATE(entry)) { entry; };
      case(_) { Debug.trap("Failed to unwrap date entry"); };
    };
  };
  func unwrapStatusEntry(key: Key) : StatusEntry {
    switch(key){
      case(#STATUS(entry)) { entry; };
      case(_) { Debug.trap("Failed to unwrap status entry"); };
    };
  };
  func unwrapInterestScore(key: Key) : InterestScore {
    switch(key){
      case(#INTEREST_SCORE(interest_score)) { interest_score; };
      case(_) { Debug.trap("Failed to unwrap appeal score"); };
    };
  };
  public func unwrapQuestionId(key: Key) : Nat {
    switch(key){
      case(#AUTHOR(entry))         { entry.question_id; };
      case(#TEXT(entry))           { entry.question_id; };
      case(#DATE(entry))           { entry.question_id; };
      case(#STATUS(entry))         { entry.question_id; };
      case(#INTEREST_SCORE(entry)) { entry.question_id; };
    };
  };

  func compareAuthorEntries(a: AuthorEntry, b: AuthorEntry) : Order {
    strictCompare<Principal>(a.author, b.author, Principal.compare, 
      strictCompare<Int>(a.date, b.date, Int.compare, 
        Nat.compare(a.question_id, b.question_id)));
  };
  func compareTextEntries(a: TextEntry, b: TextEntry) : Order {
    strictCompare<Text>(a.text, b.text, Text.compare, 
      strictCompare<Int>(a.date, b.date, Int.compare, 
        Nat.compare(a.question_id, b.question_id)));
  };
  func compareDateEntries(a: DateEntry, b: DateEntry) : Order {
    strictCompare<Int>(a.date, b.date, Int.compare, 
      Nat.compare(a.question_id, b.question_id));
  };
  func compareInterestScores(a: InterestScore, b: InterestScore) : Order {
    strictCompare<Float>(a.score, b.score, Float.compare, 
      Nat.compare(a.question_id, b.question_id));
  };

  public func toAuthorEntry(question: Question) : Key {
    #AUTHOR({
      question_id = question.id;
      author = question.author;
      date = question.date;
    });
  };
  public func toTextEntry(question: Question) : Key {
    #TEXT({
      question_id = question.id;
      text = question.text;
      date = question.date;
    });
  };
  public func toDateEntry(question: Question) : Key {
    #DATE({
      question_id = question.id;
      date = question.date;
    });
  };
  public func toStatusEntry(question_id: Nat, status: Status, date: Time) : Key {
    #STATUS({question_id; status; date;});
  };

  public func toInterestScore(question_id: Nat, score: Float) : Key {
    #INTEREST_SCORE({
      question_id;
      score;
    });
  };

  func strictCompare<T>(a: T, b: T, compare: (T, T) -> Order, on_equality: Order) : Order {
    switch(compare(a, b)){
      case(#less) { #less; };
      case(#greater) { #greater; };
      case(#equal) { on_equality; };
    };
  };

};