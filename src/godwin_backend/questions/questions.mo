import Types "../types";
import Utils "../utils";
import Queries "queries";
import Observers "../observers";
import WMap "../wrappers/WMap";
import WRef "../wrappers/WRef";
import StatusInfoHelper "../StatusInfoHelper";

import Map "mo:map/Map";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Hash "mo:base/Hash";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Int "mo:base/Int";

module {

  // For convenience: from base module
  type Iter<T> = Iter.Iter<T>;
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;
  type Time = Int;

  // For convenience: from map module
  type Map<K, V> = Map.Map<K, V>;

  // For convenience: from types module
  type Question = Types.Question;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;
  type QuestionStatus = Types.QuestionStatus;
  type Ref<V> = Types.Ref<V>;
  type WRef<V> = WRef.WRef<V>;
  type WMap<K, V> = WMap.WMap<K, V>;
  type IndexedStatus = Types.IndexedStatus;

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("title: " # question.title # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
       and Principal.equal(q1.author, q2.author)
       and Text.equal(q1.title, q2.title)
       and Text.equal(q1.text, q2.text)
       and Int.equal(q1.date, q2.date);
  };

  public func build(register: Map<Nat, Question>, index: Ref<Nat>) : Questions {
    Questions(WMap.WMap(register, Map.nhash), WRef.WRef(index));
  };

  public class Questions(
    register_: WMap<Nat, Question>,
    index_: WRef<Nat>
  ) {

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
        status_info = {
          current = {
            status = #VOTING(#CANDIDATE);
            date;
            index = 0;
          };
          history = [];
          iterations = [(#VOTING(#CANDIDATE), 0)];
        };
      };
      register_.set(question.id, question);
      index_.set(index_.get() + 1);
      observers_.callObs(null, ?question);
      question;
    };

    public func removeQuestion(question_id: Nat) {
      if (Option.isNull(register_.get(question_id))){
        Debug.trap("Cannot remove a question that does not exist");
      };
      switch(register_.remove(question_id)){
        case(null) { Prelude.unreachable(); };
        case(?old_question) {
          observers_.callObs(?old_question, null);
        };
      };
    };

    public func updateStatus(question_id: Nat, status: QuestionStatus, date: Time) : Question {
      // Get the question
      var question = getQuestion(question_id);
      // Use the helper to update the status
      let helper = StatusInfoHelper.build(question.status_info);
      helper.setCurrent(status, date);
      question := { question with status_info = helper.share() };
      // @todo: use update method instead
      switch(register_.put(question.id, question)){
        case(null) { Prelude.unreachable(); };
        case(?old_question) {
          observers_.callObs(?old_question, ?question);
        };
      };
      question;
    };

    public func addObs(callback: (?Question, ?Question) -> ()) {
      observers_.addObs(callback);
    };

  };

};