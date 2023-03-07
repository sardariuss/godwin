import Types "Types";
import WMap "../utils/wrappers/WMap";
import Ref "../utils/Ref";
import WRef "../utils/wrappers/WRef";
import Status "Status";

import Map "mo:map/Map";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Iter "mo:base/Iter";

import TextUtils "../utils/Text";
import Heap "mo:base/Heap";
import Order "mo:base/Order";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;

  // For convenience: from other modules
  type Map<K, V> = Map.Map<K, V>;
  type WRef<V> = WRef.WRef<V>;
  type WMap<K, V> = WMap.WMap<K, V>;
  type Ref<V> = Ref.Ref<V>;
  type Iter<T> = Iter.Iter<T>;
  type Order = Order.Order;

  // For convenience: from types module
  type Question = Types.Question;
  type Status = Types.Status;
  type GetQuestionError = Types.GetQuestionError;

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    buffer.add("status: " # Status.statusToText(question.status_info.status)); // @todo: put the whole status_info
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
       and Principal.equal(q1.author, q2.author)
       and Text.equal(q1.text, q2.text)
       and Int.equal(q1.date, q2.date)
       and Status.equalStatus(q1.status_info.status, q2.status_info.status); // @todo: put the whole status_info
  };

  public func build(register: Map<Nat, Question>, index: Ref<Nat>) : Questions {
    Questions(WMap.WMap(register, Map.nhash), WRef.WRef(index));
  };

  public class Questions(register_: WMap<Nat, Question>, index_: WRef<Nat>) {

    public func getQuestion(question_id: Nat) : Question {
      switch(findQuestion(question_id)){
        case(null) { Debug.trap("The question does not exist."); };
        case(?question) { question; };
      };
    };

    public func findQuestion(question_id: Nat) : ?Question {
      register_.getOpt(question_id);
    };

    public func createQuestion(author: Principal, date: Int, text: Text) : Question {
      let question = {
        id = index_.get();
        author;
        text;
        date;
        status_info = {
          status = #CANDIDATE;
          iteration = 0;
          date;
        };
      };
      register_.set(question.id, question);
      index_.set(index_.get() + 1);
      question;
    };

    public func removeQuestion(question_id: Nat) {
      switch(register_.getOpt(question_id)){
        case(null) { Debug.trap("The question does not exist"); };
        case(?question) { 
          ignore register_.remove(question.id);
        };
      };
    };

    public func replaceQuestion(question: Question) {
      switch(register_.getOpt(question.id)){
        case(null) { Debug.trap("The question does not exist"); };
        case(_) { 
          ignore register_.put(question.id, question);
        };
      };
    };

    public func iter() : Iter<Question> {
      register_.vals();
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