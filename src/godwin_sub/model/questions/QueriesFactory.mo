import Types        "Types";
import KeyConverter "KeyConverter";

import Queries       "../../utils/Queries";

import Map          "mo:map/Map";

import Order        "mo:base/Order";
import Int          "mo:base/Int";
import Nat          "mo:base/Nat";
import Debug        "mo:base/Debug";
import Text         "mo:base/Text";
import Principal    "mo:base/Principal";
import Float        "mo:base/Float";
import Bool         "mo:base/Bool";

module {

  type Map<K, V>             = Map.Map<K, V>;
  type Queries<OrderBy, Key> = Queries.Queries<OrderBy, Key>;
  type Order                 = Order.Order;
  type Time                  = Int;
  type Question              = Types.Question;
  type Status                = Types.Status;
  type OrderBy               = Types.OrderBy;
  type Key                   = Types.Key;
  type DateEntry             = Types.DateEntry;
  type TextEntry             = Types.TextEntry;
  type AuthorEntry           = Types.AuthorEntry;
  type StatusEntry           = Types.StatusEntry;
  type InterestScore         = Types.InterestScore;
  type QuestionQueries       = Types.QuestionQueries;
  type OpinionVoteEntry      = Types.OpinionVoteEntry;

  public type Register = Queries.Register<OrderBy, Key>;

  public func initRegister() : Register {
    Queries.initRegister<OrderBy, Key>(orderByHash);
  };

  public func addOrderBy(register: Register, order_by: OrderBy) {
    Queries.addOrderBy(register, orderByHash, order_by);
  };

  public func build(register: Register) : QuestionQueries {

    addOrderBy(register, #INTEREST_SCORE);
    // @todo: #STATUS(#CANDIDATE) and #STATUS(#CLOSED) could be removed when the scenario is removed
    addOrderBy(register, #STATUS(#CANDIDATE));
    addOrderBy(register, #STATUS(#OPEN));
    addOrderBy(register, #STATUS(#CLOSED));
    addOrderBy(register, #STATUS(#REJECTED));
    addOrderBy(register, #ARCHIVE);
    addOrderBy(register, #OPINION_VOTE);

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
      case(#AUTHOR)                       { "AUTHOR";              };
      case(#TEXT)                         { "TEXT";                };
      case(#DATE)                         { "DATE";                };
      case(#STATUS(#CANDIDATE)           ){ "STATUS(CANDIDATE)";   };
      case(#STATUS(#OPEN)                ){ "STATUS(OPEN)";        };
      case(#STATUS(#CLOSED)              ){ "STATUS(CLOSED)";      };
      case(#STATUS(#REJECTED))            { "STATUS(REJECTED)";    };
      case(#INTEREST_SCORE)               { "INTEREST_SCORE";      };
      case(#ARCHIVE)                      { "ARCHIVE";             };
      case(#OPINION_VOTE)                 { "OPINION_VOTE";        };
    };
  };

  func hashOrderBy(a: OrderBy) : Nat32 { Map.thash.0(toTextOrderBy(a)); };
  func equalOrderBy(a: OrderBy, b: OrderBy) : Bool { Map.thash.1(toTextOrderBy(a), toTextOrderBy(b)); };
  let orderByHash : Map.HashUtils<OrderBy> = ( func(a) = hashOrderBy(a), func(a, b) = equalOrderBy(a, b), func() = #AUTHOR );

  func toOrderBy(key: Key) : OrderBy {
    switch(key){
      case(#AUTHOR(_))         { #AUTHOR;             };
      case(#TEXT(_))           { #TEXT;               };
      case(#DATE(_))           { #DATE;               };
      case(#STATUS(entry))     { 
        switch(entry.status){
          case(#CANDIDATE)     { #STATUS(#CANDIDATE); };
          case(#OPEN)          { #STATUS(#OPEN);      };
          case(#CLOSED)        { #STATUS(#CLOSED);    };
          case(#REJECTED(_))   { #STATUS(#REJECTED);  };
        };
      };
      case(#INTEREST_SCORE(_)) { #INTEREST_SCORE;     };
      case(#ARCHIVE(_))        { #ARCHIVE;            };
      case(#OPINION_VOTE(_))   { #OPINION_VOTE;       };
    };
  };

  func compareKeys(a: Key, b: Key) : Order {
    switch(toOrderBy(a)){
      case(#AUTHOR)         { compareAuthorEntries     (unwrapAuthor(a),           unwrapAuthor(b)           ); };
      case(#TEXT)           { compareTextEntries       (unwrapText(a),             unwrapText(b)             ); };
      case(#DATE)           { compareDateEntries       (unwrapDateEntry(a),        unwrapDateEntry(b)        ); };
      case(#STATUS(_))      { compareDateEntries       (unwrapStatusEntry(a),      unwrapStatusEntry(b)      ); };
      case(#INTEREST_SCORE) { compareInterestScores    (unwrapInterestScore(a),    unwrapInterestScore(b)    ); };
      case(#ARCHIVE)        { compareDateEntries       (unwrapDateEntry(a),        unwrapDateEntry(b)        ); };
      case(#OPINION_VOTE)   { compareOpinionVoteEntries(unwrapOpinionVoteEntry(a), unwrapOpinionVoteEntry(b) ); };
    };
  };

  func getKeyIdentifier(key: Key) : Nat {
    switch(key){
      case(#AUTHOR(entry))         { entry.question_id; };
      case(#TEXT(entry))           { entry.question_id; };
      case(#DATE(entry))           { entry.question_id; };
      case(#STATUS(entry))         { entry.question_id; };
      case(#INTEREST_SCORE(entry)) { entry.question_id; };
      case(#ARCHIVE(entry))        { entry.question_id; };
      case(#OPINION_VOTE(entry))   { entry.question_id; };
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
      case(#DATE(entry))         { entry; };
      case(#ARCHIVE(entry))      { entry; };
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
  func unwrapOpinionVoteEntry(key: Key) : OpinionVoteEntry {
    switch(key){
      case(#OPINION_VOTE(entry)) { entry; };
      case(_) { Debug.trap("Failed to unwrap opinion vote entry"); };
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
  func compareOpinionVoteEntries(a: OpinionVoteEntry, b: OpinionVoteEntry) : Order {
    // Reverse the compare on is_late to put the late votes at the end
    strictCompare<Bool>(b.is_late, a.is_late, Bool.compare, 
      strictCompare<Int>(a.date, b.date, Int.compare, 
        Nat.compare(a.question_id, b.question_id)));
  };

  func strictCompare<T>(a: T, b: T, compare: (T, T) -> Order, on_equality: Order) : Order {
    switch(compare(a, b)){
      case(#less) { #less; };
      case(#greater) { #greater; };
      case(#equal) { on_equality; };
    };
  };

};