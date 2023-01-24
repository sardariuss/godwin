
import Types "Types";
import OrderedSet "OrderedSet";
import Questions "questions/Questions";
import Interests "votes/Interests";
import StatusInfoHelper "StatusInfoHelper";

import Map "mo:map/Map";
import Queries2 "Queries";

import Order "mo:base/Order";
import Int "mo:base/Int";
import Nat "mo:base/Nat";
import Debug "mo:base/Debug";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Option "mo:base/Option";

module {

  type OrderedSet<T> = OrderedSet.OrderedSet<T>;
  type Map<K, V> = Map.Map<K, V>;
  type InterestVote = Types.InterestVote;
  type Queries2<O, K> = Queries2.Queries2<O, K>;
  type Order = Order.Order;
  type Time = Int;
  type Question = Types.Question;
  type Questions = Questions.Questions;
  type QuestionStatus = Types.QuestionStatus;
  type Interests = Interests.Interests;

  public type OrderBy = {
    #AUTHOR;
    #TITLE;
    #TEXT;
    #DATE;
    #STATUS: QuestionStatus;
    #INTEREST_SCORE;
  };

  public type Key = {
    #AUTHOR: AuthorEntry;
    #TITLE: TextEntry;
    #TEXT: TextEntry;
    #DATE: DateEntry;
    #STATUS: StatusEntry;
    #INTEREST_SCORE: AppealScore;
  };

  type DateEntry = { question_id: Nat; date: Time; };
  type TextEntry = { question_id: Nat; text: Text; date: Time; };
  type AuthorEntry = { question_id: Nat; author: Principal; date: Time; };
  type StatusEntry = { question_id: Nat; status: QuestionStatus; date: Int; };
  type AppealScore = { question_id: Nat; score: Int; };

  public type QuestionQueries = Queries2.Queries<OrderBy, Key, Question>;

  public type QueryQuestionsResult = Queries2.QueryResult<Question>;
  public type Direction = Queries2.Direction;

  public func addOrderBy(register: Map<OrderBy, OrderedSet<Key>>, order_by: OrderBy) {
    if(Option.isNull(Map.get(register, orderByHash, order_by))){
      Map.set(register, orderByHash, order_by, OrderedSet.init<Key>());
    };
  };

  public func build(register: Map<OrderBy, OrderedSet<Key>>, questions: Questions, interests: Interests) : QuestionQueries {

    let from_key = func(key: Key) : Question {
      questions.getQuestion(unwrapQuestionId(key));
    };

    let to_key = func(order_by: OrderBy, question: Question) : Key {
      switch(order_by){
        case(#AUTHOR)         { toAuthorEntry(question); };
        case(#TITLE)          { toTitleEntry(question); };
        case(#TEXT)           { toTextEntry(question); };
        case(#DATE)           { toDateEntry(question); };
        case(#STATUS(_))      { toStatusEntry(question); };
        case(#INTEREST_SCORE) {
          // Assume the current iteration is #INTEREST and only the current iteration is used
          toAppealScore(interests.getVote(question.id, StatusInfoHelper.StatusInfoHelper(question).getCurrentIteration()));
        };
      };
    };

    let queries = Queries2.buildQueries<OrderBy, Key, Question>(
      register,
      orderByHash,
      compareKeys,
      toOrderBy,
      from_key,
      to_key
    );

    // @todo: only the status and interest score are plugged so far

    addOrderBy(register, #STATUS(#VOTING(#INTEREST)));
    addOrderBy(register, #STATUS(#VOTING(#OPINION)));
    addOrderBy(register, #STATUS(#VOTING(#CATEGORIZATION)));
    addOrderBy(register, #STATUS(#CLOSED));
    addOrderBy(register, #STATUS(#REJECTED));
    addOrderBy(register, #INTEREST_SCORE);

    questions.addObs(func(old: ?Question, new: ?Question){
      queries.replace(
        Option.map(old, func(vote: Question) : Key { toStatusEntry(vote); }),
        Option.map(new, func(vote: Question) : Key { toStatusEntry(vote); })
      );
    });

    interests.addObs(func(old: ?InterestVote, new: ?InterestVote){
      queries.replace(
        Option.map(old, func(vote: InterestVote) : Key { toAppealScore(vote); }),
        Option.map(new, func(vote: InterestVote) : Key { toAppealScore(vote); })
      );
    });

    queries;
  };

  func toTextOrderBy(order_by: OrderBy) : Text {
    switch(order_by){
      case(#AUTHOR){ "AUTHOR"; };
      case(#TITLE){ "TITLE"; };
      case(#TEXT){ "TEXT"; };
      case(#DATE){ "DATE"; };
      case(#STATUS(status)) { 
        switch(status){
          case(#VOTING(#INTEREST)) { "VOTING_INTEREST"; };
          case(#VOTING(#OPINION)) { "VOTING_OPINION"; };
          case(#VOTING(#CATEGORIZATION)) { "VOTING_CATEGORIZATION"; };
          case(#CLOSED) { "CLOSED"; };
          case(#REJECTED) { "REJECTED"; };
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
      case(#TITLE(_)){ #TITLE; };
      case(#TEXT(_)){ #TEXT; };
      case(#DATE(_)){ #DATE; };
      case(#STATUS(entry)) { #STATUS(entry.status); };
      case(#INTEREST_SCORE(_)) { #INTEREST_SCORE; };
    };
  };

  func compareKeys(a: Key, b: Key) : Order {
    switch(toOrderBy(a)){
      case(#AUTHOR){ compareAuthorEntries(unwrapAuthor(a), unwrapAuthor(b)); };
      case(#TITLE){ compareTextEntries(unwrapTitle(a), unwrapTitle(b)); };
      case(#TEXT){ compareTextEntries(unwrapText(a), unwrapText(b)); };
      case(#DATE){ compareDateEntries(unwrapDateEntry(a), unwrapDateEntry(b)); };
      case(#STATUS(_)){ compareDateEntries(unwrapStatusEntry(a), unwrapStatusEntry(b)); }; // @todo: Status entries could be of different types (but should not happen anyway)
      case(#INTEREST_SCORE) { compareAppealScores(unwrapAppealScore(a), unwrapAppealScore(b)); };
    };
  };

  func unwrapAuthor(key: Key) : AuthorEntry {
    switch(key){
      case(#AUTHOR(entry)) { entry; };
      case(_) { Debug.trap("@todo"); };
    };
  };
  func unwrapTitle(key: Key) : TextEntry {
    switch(key){
      case(#TITLE(entry)) { entry; };
      case(_) { Debug.trap("@todo"); };
    };
  };
  func unwrapText(key: Key) : TextEntry {
    switch(key){
      case(#TEXT(entry)) { entry; };
      case(_) { Debug.trap("@todo"); };
    };
  };
  func unwrapDateEntry(key: Key) : DateEntry {
    switch(key){
      case(#DATE(entry)) { entry; };
      case(_) { Debug.trap("@todo"); };
    };
  };
  func unwrapStatusEntry(key: Key) : StatusEntry {
    switch(key){
      case(#STATUS(entry)) { entry; };
      case(_) { Debug.trap("@todo"); };
    };
  };
  func unwrapAppealScore(key: Key) : AppealScore {
    switch(key){
      case(#INTEREST_SCORE(interest_score)) { interest_score; };
      case(_) { Debug.trap("@todo"); };
    };
  };
  public func unwrapQuestionId(key: Key) : Nat {
    switch(key){
      case(#AUTHOR(entry))         { entry.question_id; };
      case(#TITLE(entry))          { entry.question_id; };
      case(#TEXT(entry))           { entry.question_id; };
      case(#DATE(entry))  { entry.question_id; };
      case(#STATUS(entry))    { entry.question_id; };
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
  func compareAppealScores(a: AppealScore, b: AppealScore) : Order {
    strictCompare<Int>(a.score, b.score, Int.compare, 
      Nat.compare(a.question_id, b.question_id));
  };

  public func toAuthorEntry(question: Question) : Key {
    #AUTHOR({
      question_id = question.id;
      author = question.author;
      date = question.date;
    });
  };
  public func toTitleEntry(question: Question) : Key {
    #TITLE({
      question_id = question.id;
      text = question.title;
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
  public func toStatusEntry(question: Question) : Key {
    #STATUS({
      question_id = question.id;
      status = question.status_info.current.status;
      date = question.status_info.current.date;
    });
  };

  public func toAppealScore(vote: InterestVote) : Key {
    #INTEREST_SCORE({
      question_id = vote.question_id;
      score = vote.aggregate.score;
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