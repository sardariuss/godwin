import Types "Types";
import Observers "../utils/Observers";
import WMap "../utils/wrappers/WMap";
import Ref "../utils/Ref";
import WRef "../utils/wrappers/WRef";
import StatusHelper "StatusHelper";

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

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("title: " # question.title # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    buffer.add("status: " # StatusHelper.statusToText(question.status_info.current.status)); // @todo: put the whole status_info
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
       and Principal.equal(q1.author, q2.author)
       and Text.equal(q1.title, q2.title)
       and Text.equal(q1.text, q2.text)
       and Int.equal(q1.date, q2.date)
       and StatusHelper.equalStatus(q1.status_info.current.status, q2.status_info.current.status); // @todo: put the whole status_info
  };

  public func build(register: Map<Nat, Question>, index: Ref<Nat>) : Questions {
    Questions(WMap.WMap(register, Map.nhash), WRef.WRef(index));
  };

  public class Questions(register_: WMap<Nat, Question>, index_: WRef<Nat>) {

    let observers_ = Observers.Observers2<Question>();

    public func getQuestion(question_id: Nat) : Question {
      switch(findQuestion(question_id)){
        case(null) { Debug.trap("The question does not exist."); };
        case(?question) { question; };
      };
    };

    public func findQuestion(question_id: Nat) : ?Question {
      register_.get(question_id);
    };

    public func createQuestion(author: Principal, date: Int, title: Text, text: Text) : Question {
      let question = {
        id = index_.get();
        author;
        title;
        text;
        date;
        status_info = StatusHelper.initStatusInfo(date);
      };
      register_.set(question.id, question);
      index_.set(index_.get() + 1);
      observers_.callObs(null, ?question);
      question;
    };

    public func removeQuestion(question_id: Nat) {
      switch(register_.get(question_id)){
        case(null) { Debug.trap("The question does not exist"); };
        case(?question) { 
          ignore register_.remove(question.id);
          observers_.callObs(?question, null);
        };
      };
    };

    public func updateStatus(question_id: Nat, status: Status, date: Time) : Question {
      // @todo: check if it's not the same status
      // Get the question
      var question = getQuestion(question_id);
      // Update the question status
      let status_info = StatusHelper.StatusInfo(question.status_info);
      status_info.setCurrent(status, date);
      question := { question with status_info = status_info.share() };
      // Replace the question
      switch(register_.put(question.id, question)){
        case(null) { Prelude.unreachable(); };
        case(?old_question) {
          observers_.callObs(?old_question, ?question);
        };
      };
      question;
    };

    public func iter() : Iter<Question> {
      register_.vals();
    };

    public func addObs(callback: (?Question, ?Question) -> ()) {
      observers_.addObs(callback);
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
        let lower_title = TextUtils.toLowerCase(question.title, lower_case_array);
        let match_count = TextUtils.matchCount(lower_text, lower_title);
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