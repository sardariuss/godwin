import Types "types";
import Utils "utils";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;

  // For convenience: from types module
  type QuestionId = Types.QuestionId;
  type QuestionStatus = Types.QuestionStatus;
  type Status = Types.Status; 

  type Register = Trie<QuestionId, QuestionStatus>;

  public func empty() : Register {
    Trie.empty<QuestionId, QuestionStatus>();
  };

  public func newLink(register: Register, question_id: QuestionId, status: Status) : Register {
    Trie.putFresh(register, Types.keyNat(question_id), Nat.equal, { current = status; history = []; });
  };

  public func updateLink(register: Register, question_id: QuestionId, status: Status) : Register {
    switch(Trie.get(register, Types.keyNat(question_id), Nat.equal)){
      case(null) { Debug.trap("Question status not found"); };
      case(?question_status){
        let buffer = Utils.toBuffer<Status>(question_status.history);
        buffer.add(question_status.current);
        Trie.put(register, Types.keyNat(question_id), Nat.equal, { current = status; history = buffer.toArray(); }).0;
      };
    };
  };

  public func getQuestionStatus(register: Register, question_id: QuestionId) : QuestionStatus {
    switch(Trie.get(register, Types.keyNat(question_id), Nat.equal)){
      case(null) { Debug.trap("Question status not found"); };
      case(?question_status) { question_status; };
    };
  };

  public func findQuestionStatus(register: Register, question_id: QuestionId) : ?QuestionStatus {
    switch(Trie.get(register, Types.keyNat(question_id), Nat.equal)){
      case(null) { null; };
      case(?question_status) { ?question_status; };
    };
  };

  public func getCurrentStatus(register: Register, question_id: QuestionId) : Status {
    getQuestionStatus(register, question_id).current;
  };

  public func findCurrentStatus(register: Register, question_id: QuestionId) : ?Status {
    switch(Trie.get(register, Types.keyNat(question_id), Nat.equal)){
      case(null) { null; };
      case(?question_status) { ?question_status.current; };
    };
  };

};