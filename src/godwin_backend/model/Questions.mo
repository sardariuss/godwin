import Types "Types";
import Observers "../utils/Observers";
import WMap "../utils/wrappers/WMap";
import WRef "../utils/wrappers/WRef";
import StatusInfoHelper "StatusInfoHelper";

import Map "mo:map/Map";

import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Prelude "mo:base/Prelude";
import Option "mo:base/Option";
import Buffer "mo:base/Buffer";
import Text "mo:base/Text";
import Int "mo:base/Int";

module {

  // For convenience: from base module
  type Principal = Principal.Principal;
  type Time = Int;

  // For convenience: from other modules
  type Map<K, V> = Map.Map<K, V>;
  type WRef<V> = WRef.WRef<V>;
  type WMap<K, V> = WMap.WMap<K, V>;

  // For convenience: from types module
  type Question = Types.Question;
  type QuestionStatus = Types.QuestionStatus;
  type Ref<V> = Types.Ref<V>;
  let { statusToText; equalStatus; } = Types;

  public func toText(question: Question) : Text {
    var buffer : Buffer.Buffer<Text> = Buffer.Buffer<Text>(8);
    buffer.add("id: " # Nat.toText(question.id) # ", ");
    buffer.add("author: " # Principal.toText(question.author) # ", ");
    buffer.add("title: " # question.title # ", ");
    buffer.add("text: " # question.text # ", ");
    buffer.add("date: " # Int.toText(question.date) # ", ");
    buffer.add("status: " # statusToText(question.status_info.current.status)); // @todo: put the whole status_info
    Text.join("", buffer.vals());
  };
  
  public func equal(q1: Question, q2: Question) : Bool {
    return Nat.equal(q1.id, q2.id)
       and Principal.equal(q1.author, q2.author)
       and Text.equal(q1.title, q2.title)
       and Text.equal(q1.text, q2.text)
       and Int.equal(q1.date, q2.date)
       and equalStatus(q1.status_info.current.status, q2.status_info.current.status); // @todo: put the whole status_info
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
        status_info = {
          current = {
            status = #VOTING(#INTEREST);
            date;
            index = 0;
          };
          history = [];
          iterations = [(#VOTING(#INTEREST), 0)];
        };
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

    public func updateStatus(question_id: Nat, status: QuestionStatus, date: Time) : Question {
      // Get the question
      var question = getQuestion(question_id);
      // Update the question status
      let helper = StatusInfoHelper.StatusInfoHelper(question);
      helper.setCurrent(status, date);
      question := { question with status_info = helper.share() };
      // Replace the question
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