import Types "types";
import Utils "utils";
import Observers "observers";
import WMap "wrappers/WMap";
import WRef "wrappers/WRef";

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
  type Buffer<T> = Buffer.Buffer<T>;

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
  type StatusInfo = Types.StatusInfo;

  public func isHistoryIteration(question: Question, status: QuestionStatus, iteration: Nat) : Bool {
    let helper = build(question.status_info);
    not (helper.getCurrentStatus() == status and helper.getCurrentIteration() == iteration) and helper.getIteration(status) <= iteration;
  };

  public func isValidIteration(question: Question, status: QuestionStatus, iteration: Nat) : Bool {
    let helper = build(question.status_info);
    helper.getIteration(status) <= iteration;
  };

  public func isCurrentStatus(question: Question, status: QuestionStatus) : Bool {
    question.status_info.current.status == status;
  };

  public func build(status_info: StatusInfo) : StatusInfoHelper {
    StatusInfoHelper(
      status_info.current,
      Buffer.fromArray<IndexedStatus>(status_info.history),
      Utils.arrayToMap<QuestionStatus, Nat>(status_info.iterations, Types.questionStatushash)
    );
  };

  // @todo: use question as parameter
  public class StatusInfoHelper(current: IndexedStatus, history_: Buffer<IndexedStatus>, iterations_: Map<QuestionStatus, Nat>) {

    var current_ = current;

    public func share() : StatusInfo {
      {
        current = current_;
        history = Buffer.toArray(history_);
        iterations = Utils.mapToArray<QuestionStatus, Nat>(iterations_);
      };
    };

    public func setCurrent(status: QuestionStatus, date: Time){
      // Add current to history
      history_.add(current_);
      let index = switch(Map.get(iterations_, Types.questionStatushash, status)){
        case(null) { Debug.trap("The status index is missing"); };
        case(?idx) { idx + 1; };
      };
      // Set current
      current_ := { status; date; index; };
      // Update iteration index for this status
      Map.set(iterations_, Types.questionStatushash, status, index);
    };

    public func getIteration(status: QuestionStatus) : Nat {
      switch(Map.get(iterations_, Types.questionStatushash, status)){
        case(null) { Debug.trap("The status index is missing"); };
        case(?idx) { idx; };
      };
    };

    public func getCurrentStatus() : QuestionStatus {
      current_.status;
    };

    public func getCurrentIteration() : Nat {
      current_.index;
    };

  };

};