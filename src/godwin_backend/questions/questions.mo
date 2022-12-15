import Types "../types";
import Interests "../votes/interests";
import Vote "../votes/vote";
import Queries "queries";

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
  type Vote<B, A> = Types.Vote<B, A>;
  type Interest = Types.Interest;
  type InterestAggregate = Types.InterestAggregate;

  type Time = Int;

  public type Register = {
    questions: Trie<Nat, Question>;
    question_index: Nat;
    rbts: Queries.QuestionRBTs;
  };

  public func empty() : Register {
    var rbts = Queries.init();
    rbts := Queries.addOrderBy(rbts, #STATUS_DATE);
    {
      questions = Trie.empty<Nat, Question>();
      question_index = 0;
      rbts;
    };
  };

  public func getMostInteresting(register: Register) : ?Question {
    let result = Queries.queryQuestions(
      register.rbts,
      #STATUS_DATE,
      ?{ id = 0; data = #STATUS_DATE({ status = #CANDIDATE; date = 0; });},
      ?{ id = 0; data = #STATUS_DATE({ status = #CANDIDATE; date = 1_000_000_000_000; });}, // @todo: what could be a max for the score?
      #bwd,
      1);
    if (result.ids.size() == 0) { return null; }
    else { return ?getQuestion(register, result.ids[0]); };
  };

  public func getOldestInterest(register: Register) : ?Question {
    let result = Queries.queryQuestions(
      register.rbts,
      #STATUS_DATE,
      ?{ id = 0; data = #STATUS_DATE({ status = #CANDIDATE; date = 0; }); },
      ?{ id = 0; data = #STATUS_DATE({ status = #CANDIDATE; date = 1_000_000_000_000; }); }, // @todo: what could be a max for the score?
      #bwd,
      1);
    if (result.ids.size() == 0) { return null; }
    else { return ?getQuestion(register, result.ids[0]); };
  };

  public func getOldestOpinion(register: Register) : ?Question {
    let result = Queries.queryQuestions(
      register.rbts,
      #STATUS_DATE,
      ?{ id = 0; data = #STATUS_DATE({ status = #OPEN(#OPINION); date = 0; }); },
      ?{ id = 0; data = #STATUS_DATE({ status = #OPEN(#OPINION); date = 1_000_000_000_000; }); }, // @todo: what could be a max for the score?
      #fwd,
      1);
    if (result.ids.size() == 0) { return null; }
    else { return ?getQuestion(register, result.ids[0]); };
  };

    public func getOldestCategorization(register: Register) : ?Question {
    let result = Queries.queryQuestions(
      register.rbts,
      #STATUS_DATE,
      ?{ id = 0; data = #STATUS_DATE({ status = #OPEN(#CATEGORIZATION); date = 0; }); },
      ?{ id = 0; data = #STATUS_DATE({ status = #OPEN(#CATEGORIZATION); date = 1_000_000_000_000; }); }, // @todo: what could be a max for the score?
      #fwd,
      1);
    if (result.ids.size() == 0) { return null; }
    else { return ?getQuestion(register, result.ids[0]); };
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

  public func createQuestion(register: Register, author: Principal, date: Time, title: Text, text: Text) : (Register, Question) {
    let question = {
      id = register.question_index;
      author;
      title;
      text;
      date;
      status = #CANDIDATE(Vote.new<Interest, InterestAggregate>(date, { ups = 0; downs = 0; score = 0; }));
      interests_history = [];
      vote_history = [];
    };
    (
      {
        questions = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question).0;
        question_index = register.question_index + 1;
        rbts = Queries.add(register.rbts, question);
      },
      question
    );
  };

  public func replaceQuestion(register: Register, question: Question) : Register {
    let (questions, removed_question) = Trie.put(register.questions, Types.keyNat(question.id), Nat.equal, question);
    switch(removed_question){
      case(null) { Debug.trap("Cannot replace a question that does not exist"); };
      case(?old_question) {
        { register with questions; rbts = Queries.replace(register.rbts, old_question, question); };
      };
    };
  };

};