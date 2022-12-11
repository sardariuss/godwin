import Types "../types";
import Interests "../votes/interests";

import Trie "mo:base/Trie";
import Nat "mo:base/Nat";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  // For convenience: from other modules

  type Time = Int;

  type Register = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
  };

  public func empty() : Register {
    {
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
    };
  };

  public func getQuestion(register: Register, question_id: Nat) : Question {
    switch(findQuestion(register, question_id)){
      case(null) { Debug.trap("The question does not exist."); };
      case(?question) { question; };
    };
  };

  public func findQuestion(register: Register, question_id: Nat) : ?Question {
    Trie.get(register.questions, Types.keyNat(question_id), Nat.equal);
  };

  public func createQuestion(register: Register, interests: Interests.Register, author: Principal, date: Time, title: Text, text: Text, iteration_id: Nat) : (Register, Interests.Register, Question) {
    let (updated_interests, vote) = Interests.newVote(interests, date); // @todo: add question id
    let question = {
      id = register.question_index;
      author = author;
      title = title;
      text = text;
      date = date;
      votes = [#INTEREST(vote.id)];
    };
    (
      {
        questions = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question).0;
        question_index = register.question_index + 1;
      },
      updated_interests,
      question
    );
  };

  public func replaceQuestion(register: Register, question: Question) : Register {
    let (questions, removed_question) = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question);
    switch(removed_question){
      case(null) { Debug.trap("Cannot replace a question that does not exist"); };
      case(_) {
        { register with questions };
      };
    };
  };

};