//import Types "../types";
//import StageHistory "../stageHistory";
//
//import RBT "mo:stableRBT/StableRBTree";
//
//import Trie "mo:base/Trie";
//import Principal "mo:base/Principal";
//import Time "mo:base/Time";
//import Order "mo:base/Order";
//import Debug "mo:base/Debug";
//import Text "mo:base/Text";
//import Option "mo:base/Option";
//import Array "mo:base/Array";
//import Hash "mo:base/Hash";
//import Iter "mo:base/Iter";
//import Float "mo:base/Float";

module {

//  // For convenience: from base module
//  type Trie<K, V> = Trie.Trie<K, V>;
//  type Principal = Principal.Principal;
//  type Time = Time.Time;
//  type Order = Order.Order;
//  type Hash = Hash.Hash;
//  type Key<K> = Trie.Key<K>;
//  type Iter<T> = Iter.Iter<T>;
//
//  // For convenience: from types module
//  type Question = Types.Question;
//  type SelectionStage = Types.SelectionStage;
//  type CategorizationStage = Types.CategorizationStage;
//  //type InterestAggregate = Types.InterestAggregate;
//
//  // Public types
//  public type OrderBy = {
//    #ID;
//    #AUTHOR;
//    #TITLE;
//    #TEXT;
//    //#ENDORSEMENTS;
//    #CREATION_DATE;
//    #SELECTION_STAGE_DATE;
//    #CATEGORIZATION_STAGE_DATE;
//    //#CREATION_HOT;
//  };
//
//  public type QueryQuestionsResult = { ids: [Nat]; next_id: ?Nat };
//  public type QueryDirection = {
//    #FWD;
//    #BWD;
//  };
//  public type QuestionKey = {
//    id: Nat;
//    data: {
//      #ID;
//      #AUTHOR: TextEntry;
//      #TITLE: TextEntry;
//      #TEXT: TextEntry;
//      //#ENDORSEMENTS: InterestsEntry;
//      #CREATION_DATE: DateEntry;
//      #SELECTION_STAGE_DATE: SelectionStageEntry;
//      #CATEGORIZATION_STAGE_DATE: CategorizationStageEntry;
//      //#CREATION_HOT: CreationHotEntry;
//    };
//  };
//
//  // Private types
//  type DateEntry = { date: Time; };
//  type TextEntry = { text: Text; date: Time; };
//  type SelectionStageEntry = { selection_stage: SelectionStage; date: Time; };
//  //type InterestsEntry = { interests: InterestAggregate; date: Time; };
//  type CategorizationStageEntry = { categorization_stage: CategorizationStage; date: Time; };
//  //type CreationHotEntry = Float;
//  public type QuestionRBTs = Trie<OrderBy, RBT.Tree<QuestionKey, ()>>;
//
//  // To be able to use OrderBy as key in a Trie
//  func toTextOrderBy(order_by: OrderBy) : Text {
//    switch(order_by){
//      case(#ID){ "ID"; };
//      case(#AUTHOR){ "AUTHOR"; };
//      case(#TITLE){ "TITLE"; };
//      case(#TEXT){ "TEXT"; };
//      //case(#ENDORSEMENTS){ "ENDORSEMENTS"; };
//      case(#CREATION_DATE){ "CREATION_DATE"; };
//      case(#SELECTION_STAGE_DATE){ "SELECTION_STAGE_DATE"; };
//      case(#CATEGORIZATION_STAGE_DATE){ "CATEGORIZATION"; };
//      //case(#CREATION_HOT){ "CREATION_HOT"; };
//    };
//  };
//  func hashOrderBy(order_by: OrderBy) : Hash { Text.hash(toTextOrderBy(order_by)); };
//  func equalOrderBy(a: OrderBy, b: OrderBy) : Bool { a == b; };
//  func keyOrderBy(order_by: OrderBy) : Key<OrderBy> { { key = order_by; hash = hashOrderBy(order_by); } };
//
//  // Init functions
//  func initQuestionKey(question: Question, order_by: OrderBy) : QuestionKey {
//    switch(order_by){
//      case(#ID){ { id = question.id; data = #ID; } };
//      case(#AUTHOR){ { id = question.id; data = #AUTHOR(initAuthorEntry(question)); } };
//      case(#TITLE){ { id = question.id; data = #TITLE(initTitleEntry(question)); } };
//      case(#TEXT){ { id = question.id; data = #TEXT(initTextEntry(question)); } };
//      //case(#ENDORSEMENTS){ { id = question.id; data = #ENDORSEMENTS(initInterestsEntry(question)); } };
//      case(#CREATION_DATE){ { id = question.id; data = #CREATION_DATE(initDateEntry(question)); } };
//      case(#SELECTION_STAGE_DATE){ { id = question.id; data = #SELECTION_STAGE_DATE(initSelectionStageEntry(question)); } };
//      case(#CATEGORIZATION_STAGE_DATE){ { id = question.id; data = #CATEGORIZATION_STAGE_DATE(initCategorizationStageEntry(question)); } };
//      //case(#CREATION_HOT){ { id = question.id; data = #CREATION_HOT(initCreationHotEntry(question)); } };
//    };
//  };
//  func initDateEntry(question: Question) : DateEntry { {date = question.date; }; };
//  func initAuthorEntry(question: Question) : TextEntry { { text = Principal.toText(question.author); date = question.date; }; };
//  func initTitleEntry(question: Question) : TextEntry { { text = question.title; date = question.date; }; };
//  func initTextEntry(question: Question) : TextEntry {{ text = question.text; date = question.date; };};
//  func initSelectionStageEntry(question: Question) : SelectionStageEntry { 
//    let stage_record = StageHistory.getActiveStage(question.selection_stage);
//    {
//      selection_stage = stage_record.stage;
//      date = stage_record.timestamp;
//    }; 
//  };
////  func initInterestsEntry(question: Question) : InterestsEntry { 
////    { 
////      interests = question.interests; 
////      date = StageHistory.getActiveStage(question.selection_stage).timestamp;
////    }; 
////  };
//  func initCategorizationStageEntry(question: Question) : CategorizationStageEntry {
//    let stage_record = StageHistory.getActiveStage(question.categorization_stage);
//    { 
//      categorization_stage = stage_record.stage;
//      date = stage_record.timestamp;
//    };
//  };
////  func initCreationHotEntry(question: Question) : CreationHotEntry { 
////    // When based on creation date, the hot algorithm assumes the date is in the past
////    // @todo: cannot do assert(question.date <= Time.now()) here because it prevents from running the tests
////    // Based on: https://medium.com/hacking-and-gonzo/how-reddit-ranking-algorithms-work-ef111e33d0d9
////    // @todo: find out if the division coefficient (currently 45000) makes sense for godwin
////    Float.log(Float.max(Float.fromInt(question.interests.score), 1.0)) / 2.303 + Float.fromInt(question.date * 1_000_000_000) / 45000.0;
////  };
//
//  // Compare functions
//  func compareQuestionKey(a: QuestionKey, b: QuestionKey) : Order {
//    let default_order = compareIds(a.id, b.id);
//    switch(a.data){
//      case(#ID){
//        switch(b.data){
//          case(#ID){ default_order; };
//          case(_){Debug.trap("Cannot compare entries of different types")};
//        };
//      };
//      case(#AUTHOR(entry_a)){
//        switch(b.data){
//          case(#AUTHOR(entry_b)){ compareTextEntry(entry_a, entry_b, default_order); };
//          case(_){Debug.trap("Cannot compare entries of different types")};
//        };
//      };
//      case(#TITLE(entry_a)){
//        switch(b.data){
//          case(#TITLE(entry_b)){ compareTextEntry(entry_a, entry_b, default_order); };
//          case(_){Debug.trap("Cannot compare entries of different types")};
//        };
//      };
//      case(#TEXT(entry_a)){
//        switch(b.data){
//          case(#TEXT(entry_b)){ compareTextEntry(entry_a, entry_b, default_order); };
//          case(_){Debug.trap("Cannot compare entries of different types")};
//        };
//      };
////      case(#ENDORSEMENTS(entry_a)){
////        switch(b.data){
////          case(#ENDORSEMENTS(entry_b)){ compareInterestsEntry(entry_a, entry_b, default_order); };
////          case(_){Debug.trap("Cannot compare entries of different types")};
////        };
////      };
//      case(#CREATION_DATE(entry_a)){
//        switch(b.data){
//          case(#CREATION_DATE(entry_b)){ compareDateEntry(entry_a, entry_b, default_order); };
//          case(_){Debug.trap("Cannot compare entries of different types")};
//        };
//      };
//      case(#SELECTION_STAGE_DATE(entry_a)){
//        switch(b.data){
//          case(#SELECTION_STAGE_DATE(entry_b)){ compareSelectionStageEntry(entry_a, entry_b, default_order); };
//          case(_){Debug.trap("Cannot compare entries of different types")};
//        };
//      };
//      case(#CATEGORIZATION_STAGE_DATE(entry_a)){
//        switch(b.data){
//          case(#CATEGORIZATION_STAGE_DATE(entry_b)){ compareCategorizationStageEntry(entry_a, entry_b, default_order); };
//          case(_){Debug.trap("Cannot compare entries of different types")};
//        };
//      };
////      case(#CREATION_HOT(entry_a)){
////        switch(b.data){
////          case(#CREATION_HOT(entry_b)){ Float.compare(entry_a, entry_b); };
////          case(_){Debug.trap("Cannot compare entries of different types")};
////        };
////      };
//    };
//  };
//  func compareIds(first_id: Nat, second_id: Nat) : Order {
//    if (first_id < second_id){ #less;}
//    else if (first_id > second_id){ #greater;}
//    else { #equal;}  
//  };
//  func compareDateEntry(a: DateEntry, b: DateEntry, default_order: Order) : Order {
//    if (a.date < b.date){ #less;}
//    else if (a.date > b.date){ #greater;}
//    else { default_order };
//  };
//  func compareTextEntry(a: TextEntry, b: TextEntry, default_order: Order) : Order {
//    switch (Text.compare(a.text, b.text)){
//      case(#less){ #less; };
//      case(#greater){ #greater; };
//      case(#equal){ compareDateEntry(a, b, default_order); };
//    };
//  };
//  func compareSelectionStageEntry(a: SelectionStageEntry, b: SelectionStageEntry, default_order: Order) : Order {
//    switch(a.selection_stage){
//      case(#CREATED){
//        switch(b.selection_stage){
//          case(#CREATED){ compareDateEntry(a, b, default_order); }; case(#SELECTED){ #less; }; case(#ARCHIVED(_)){ #less; };
//        };
//      };
//      case(#SELECTED){
//        switch(b.selection_stage){
//          case(#CREATED){ #greater; }; case(#SELECTED){ compareDateEntry(a, b, default_order); }; case(#ARCHIVED(_)){ #less; };
//        };
//      };
//      case(#ARCHIVED(_)){
//        switch(b.selection_stage){
//          case(#CREATED){ #greater; }; case(#SELECTED){ #greater; }; case(#ARCHIVED(_)){ compareDateEntry(a, b, default_order); };
//        };
//      };
//    };
//  };
////  func compareInterestsEntry(a: InterestsEntry, b: InterestsEntry, default_order: Order) : Order {
////    if (a.interests.score < b.interests.score){ #less; }
////    else if (a.interests.score > b.interests.score){ #greater;}
////    else { compareDateEntry(a, b, default_order); };
////  };
//  func compareCategorizationStageEntry(a: CategorizationStageEntry, b: CategorizationStageEntry, default_order: Order) : Order {
//    switch(a.categorization_stage){
//      case(#PENDING){
//        switch(b.categorization_stage){
//          case(#PENDING){ compareDateEntry(a, b, default_order); }; case(#ONGOING){ #less; }; case(#DONE(_)){ #less; };
//        };
//      };
//      case(#ONGOING){
//        switch(b.categorization_stage){
//          case(#PENDING){ #greater; }; case(#ONGOING){ compareDateEntry(a, b, default_order); }; case(#DONE(_)){ #less; };
//        };
//      };
//      case(#DONE(_)){
//        switch(b.categorization_stage){
//          case(#PENDING){ #greater; }; case(#ONGOING){ #greater; }; case(#DONE(_)){ compareDateEntry(a, b, default_order); };
//        };
//      };
//    };
//  };
//
//  // Public functions
//
//  public func init() : QuestionRBTs { 
//    var rbts = Trie.empty<OrderBy, RBT.Tree<QuestionKey, ()>>();
//    rbts := addOrderBy(rbts, #ID);
//    rbts;
//  };
//
//  // @todo: this is done for optimization (mostly to reduce memory usage) but brings some issues:
//  // (queryQuestions and entries can trap). Alternative would be to init with every OrderBy
//  // possible in init method.
//  public func addOrderBy(rbts: QuestionRBTs, order_by: OrderBy) : QuestionRBTs {
//    Trie.put(rbts, keyOrderBy(order_by), equalOrderBy, RBT.init<QuestionKey, ()>()).0;
//  };
//
//  public func add(rbts: QuestionRBTs, new_question: Question) : QuestionRBTs {
//    var new_rbts = rbts;
//    for ((order_by, rbt) in Trie.iter(rbts)){
//      let new_rbt = RBT.put(rbt, compareQuestionKey, initQuestionKey(new_question, order_by), ());
//      new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
//    };
//    new_rbts;
//  };
//
//  public func replace(rbts: QuestionRBTs, old_question: Question, new_question: Question) : QuestionRBTs {
//    var new_rbts = rbts;
//    for ((order_by, rbt) in Trie.iter(rbts)){
//      let old_key = initQuestionKey(old_question, order_by);
//      let new_key = initQuestionKey(new_question, order_by);
//      if (compareQuestionKey(old_key, new_key) != #equal){
//        var new_rbt = RBT.remove(rbt, compareQuestionKey, old_key).1;
//        new_rbt := RBT.put(new_rbt, compareQuestionKey, new_key, ());
//        new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
//      };
//    };
//    new_rbts;
//  };
//
//  public func remove(rbts: QuestionRBTs, old_question: Question) : QuestionRBTs {
//    var new_rbts = rbts;
//    for ((order_by, rbt) in Trie.iter(rbts)){
//      let new_rbt = RBT.remove(rbt, compareQuestionKey, initQuestionKey(old_question, order_by)).1;
//      new_rbts := Trie.put(new_rbts, keyOrderBy(order_by), equalOrderBy, new_rbt).0;
//    };
//    new_rbts;
//  };
//
//  // @todo: if lower or upper bound QuestionKey data is not of the same type as OrderBy, what happens ? traps ?
//  // @todo: fix lower_bound and upper_bound should not require the question id...
//  public func queryQuestions(
//    rbts: QuestionRBTs,
//    order_by: OrderBy,
//    lower_bound: ?QuestionKey,
//    upper_bound: ?QuestionKey,
//    direction: RBT.Direction,
//    limit: Nat
//  ) : QueryQuestionsResult {
//    switch(Trie.get(rbts, keyOrderBy(order_by), equalOrderBy)){
//      case(null){ Debug.trap("Cannot find rbt for this order_by"); };
//      case(?rbt){
//        switch(RBT.entries(rbt).next()){
//          case(null){ { ids = []; next_id = null; } };
//          case(?first){
//            switch(RBT.entriesRev(rbt).next()){
//              case(null){ { ids = []; next_id = null; } };
//              case(?last){
//                let scan = RBT.scanLimit(rbt, compareQuestionKey, Option.get(lower_bound, first.0), Option.get(upper_bound, last.0), direction, limit);
//                {
//                  ids = Array.map(scan.results, func(key_value: (QuestionKey, ())) : Nat { key_value.0.id; });
//                  next_id = Option.getMapped(scan.nextKey, func(key : QuestionKey) : ?Nat { ?key.id; }, null);
//                }
//              };
//            };
//          };
//        };
//      };
//    };
//  };
//
//  public func entries(rbts: QuestionRBTs, order_by: OrderBy, direction: QueryDirection) : Iter<(QuestionKey, ())> {
//    switch(Trie.get(rbts, keyOrderBy(order_by), equalOrderBy)){
//      case(null){ Debug.trap("Cannot find rbt for this order_by"); };
//      case(?rbt){ 
//        switch(direction){
//          case(#FWD) { RBT.entries(rbt); };
//          case(#BWD) { RBT.entriesRev(rbt); };
//        };
//      };
//    };
//  };

};