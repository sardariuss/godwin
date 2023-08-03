import Types "Types";
import WMap "../../utils/wrappers/WMap";
import Ref "../../utils/Ref";
import WRef "../../utils/wrappers/WRef";

import Map "mo:map/Map";
import Set "mo:map/Set";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

import TextUtils "../../utils/Text";
import Heap "mo:base/Heap";
import Order "mo:base/Order";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;

  // For convenience: from other modules
  type Map<K, V> = Map.Map<K, V>;
  type Set<K> = Set.Set<K>;
  type WRef<V> = WRef.WRef<V>;
  type WMap<K, V> = WMap.WMap<K, V>;
  type Ref<V> = Ref.Ref<V>;
  type Iter<T> = Iter.Iter<T>;
  type Order = Order.Order;

  type QuestionId        = Types.QuestionId;
  type Question          = Types.Question;
  type OpenQuestionError = Types.OpenQuestionError;

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
       and Principal.equal(q1.author, q2.author)
       and Text.equal(q1.text, q2.text)
       and Int.equal(q1.date, q2.date)
  };

  public type Register = {
    questions: Map<QuestionId, Question>;
    var question_index: QuestionId;
    var character_limit: Nat;
    by_author: Map<Principal, Set<QuestionId>>;
  };

  public func initRegister(char_limit: Nat) : Register {
    {
      questions = Map.new<QuestionId, Question>(Map.nhash);
      var question_index = 0;
      var character_limit = char_limit;
      by_author = Map.new<Principal, Set<QuestionId>>(Map.phash);
    };
  };

  public class Questions(_register: Register) {

    public func getCharacterLimit() : Nat {
      _register.character_limit;
    };

    public func getQuestionIdsFromAuthor(principal: Principal) : Set<QuestionId> {
      switch(Map.get(_register.by_author, Map.phash, principal)){
        case(null) { Set.new<Nat>(Map.nhash); };
        case(?ids) { ids; };
      };
    };

    public func getQuestion(question_id: QuestionId) : Question {
      switch(findQuestion(question_id)){
        case(null) { Debug.trap("The question does not exist."); };
        case(?question) { question; };
      };
    };

    public func findQuestion(question_id: QuestionId) : ?Question {
      Map.get(_register.questions, Map.nhash, question_id);
    };

    public func canCreateQuestion(author: Principal, date: Int, text: Text) : ?OpenQuestionError {
      if (Principal.isAnonymous(author)){
        ?#PrincipalIsAnonymous;
      } else if (text.size() > _register.character_limit){
        ?#TextTooLong;
      } else {
        null;
      };
    };

    public func createQuestion(author: Principal, date: Int, text: Text) : Question {

      // Create the question and add it to the register
      let question = {
        id = _register.question_index;
        author;
        text;
        date;
      };
      Map.set(_register.questions, Map.nhash, question.id, question);
      
      // Add the question to the author's list of questions
      let author_questions = Option.get(Map.get(_register.by_author, Map.phash, author), Set.new<Nat>(Map.nhash));
      Set.add(author_questions, Map.nhash, question.id);
      Map.set(_register.by_author, Map.phash, author, author_questions);

      // Increment the question index
      _register.question_index := _register.question_index + 1;

      // Return the question
      question;
    };

    public func removeQuestion(question_id: QuestionId) {
      switch(Map.get(_register.questions, Map.nhash, question_id)){
        case(null) { Debug.trap("The question does not exist"); };
        case(?question) { 
          ignore Map.remove(_register.questions, Map.nhash, question.id);
        };
      };
    };

    public func iter() : Iter<Question> {
      Map.vals(_register.questions);
    };

    type MatchCount = { count: Nat; id: Nat; };

    // Revert the order so that the greatest match is the first pick of the heap
    func matchCountCompare(m1: MatchCount, m2: MatchCount) : Order {
      switch(Nat.compare(m1.count, m2.count)){
        case(#greater) { #less; };
        case(#less)    { #greater; };
        case(#equal)   { #equal; };
      };
    };

    let lower_case_array = TextUtils.initToLowerCaseArray();

    public func searchQuestions(text: Text, limit: Nat) : [Nat] {

      let lower_text = TextUtils.toLowerCase(text, lower_case_array);

      let heap = Heap.Heap<MatchCount>(matchCountCompare);
      for (question in iter()) {
        let lower_text = TextUtils.toLowerCase(question.text, lower_case_array);
        let match_count = TextUtils.matchCount(lower_text, lower_text);
        Debug.print("Match count for " # Nat.toText(question.id) # ": " # Nat.toText(match_count) # "\n");
        heap.put({ count = match_count; id = question.id; });
      };

      let buffer = Buffer.Buffer<Nat>(limit);
      label to_array for (index in Iter.range(0, limit - 1)) {
        switch(heap.removeMin()){
          case(null) { break to_array; };
          case(?match_count) { buffer.add(match_count.id); };
        };
      };

      Buffer.toArray(buffer);
    };

  };

};