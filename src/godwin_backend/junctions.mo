import Types "types";
import Utils "utils";

import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Nat "mo:base/Nat";
import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Set<K> = TrieSet.Set<K>;

  // For convenience: from types module
  type QuestionId = Types.QuestionId;
  type IterationId = Types.IterationId;
  type QuestionIterations = Types.QuestionIterations; 
  type Junctions = Types.Junctions;

  public func empty() : Junctions {
    {
      iterations = Trie.empty<QuestionId, QuestionIterations>();
      questions = Trie.empty<IterationId, QuestionId>();
      new = TrieSet.empty<IterationId>();
      current = TrieSet.empty<IterationId>();
    };
  };

  public func addNew(junctions: Junctions, question_id: QuestionId, iteration_id: IterationId) : Junctions {
    {
      iterations = Trie.putFresh(junctions.iterations, Types.keyNat(question_id), Nat.equal, { current = iteration_id; history = []; });
      questions = Trie.putFresh(junctions.questions, Types.keyNat(iteration_id), Nat.equal, question_id);
      new = Trie.put(junctions.new, Types.keyNat(iteration_id), Nat.equal, ()).0;
      current = Trie.put(junctions.current, Types.keyNat(iteration_id), Nat.equal, ()).0;
    };
  };

  public func addIteration(junctions: Junctions, question_id: QuestionId, iteration_id: IterationId) : Junctions {
    switch(Trie.get(junctions.iterations, Types.keyNat(question_id), Nat.equal)){
      case(null) { Debug.trap("Iteration not found"); };
      case(?question_iterations){
        let buffer = Utils.toBuffer<Nat>(question_iterations.history);
        buffer.add(question_iterations.current);
        {
          iterations = Trie.put(junctions.iterations, Types.keyNat(question_id), Nat.equal, { current = iteration_id; history = buffer.toArray(); }).0;
          questions = Trie.putFresh(junctions.questions, Types.keyNat(iteration_id), Nat.equal, question_id);
          new = Trie.remove(junctions.new, Types.keyNat(question_iterations.current), Nat.equal).0;
          current = Trie.put(junctions.current, Types.keyNat(iteration_id), Nat.equal, ()).0;
        };
      };
    };
  };

  public func getQuestionId(junctions: Junctions, iteration_id: IterationId) : QuestionId {
    switch(Trie.get(junctions.questions, Types.keyNat(iteration_id), Nat.equal)){
      case(null) { Debug.trap("Question not found"); };
      case(?question_id) { question_id; };
    };
  };

  public func getCurrentIteration(junctions: Junctions, question_id: QuestionId) : IterationId {
    switch(Trie.get(junctions.iterations, Types.keyNat(question_id), Nat.equal)){
      case(null) { Debug.trap("Iteration not found"); };
      case(?iterations) { iterations.current; };
    };
  };

  public func getIterations(junctions: Junctions, question_id: QuestionId) : QuestionIterations {
    switch(Trie.get(junctions.iterations, Types.keyNat(question_id), Nat.equal)){
      case(null) { Debug.trap("Iteration not found"); };
      case(?iterations) { iterations; };
    };
  };

  public func findCurrentIteration(junctions: Junctions, question_id: QuestionId) : ?IterationId {
    switch(Trie.get(junctions.iterations, Types.keyNat(question_id), Nat.equal)){
      case(null) { null; };
      case(?iterations) { ?iterations.current; };
    };
  };

};