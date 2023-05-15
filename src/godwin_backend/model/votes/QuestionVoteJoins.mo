import Types           "Types";

import Utils           "../../utils/Utils";
import WMap            "../../utils/wrappers/WMap";

import Map             "mo:map/Map";

import Result          "mo:base/Result";
import Debug           "mo:base/Debug";
import Option          "mo:base/Option";
import Array           "mo:base/Array";

module {

  // For convenience: from base module
  type Result<Ok, Err>            = Result.Result<Ok, Err>;

  // For convenience: from map module
  type Map<K, V>                  = Map.Map<K, V>;
  type WMap<K, V>                 = WMap.WMap<K, V>;

  // For convenience: from types module
  type VoteId                     = Types.VoteId;
  type FindVoteError              = Types.FindVoteError;
  type FindQuestionIterationError = Types.FindQuestionIterationError;

  // For convenience
  type QuestionId              = Nat;

  public type Register = {
    indexed_by_question : Map<QuestionId, [VoteId]>;
    indexed_by_vote     : Map<VoteId, (QuestionId, Nat)>;
  };

  public func initRegister() : Register {
    {
      indexed_by_question = Map.new<QuestionId, [VoteId]>(Map.nhash);
      indexed_by_vote     = Map.new<VoteId, (QuestionId, Nat)>(Map.nhash);
    };
  };

  public func build(register: Register) : QuestionVoteJoins {
    QuestionVoteJoins(
      WMap.WMap(register.indexed_by_question, Map.nhash),
      WMap.WMap(register.indexed_by_vote, Map.nhash),
    );
  };
  
  // @todo: add ID to function names
  public class QuestionVoteJoins(
    _indexed_by_question: WMap<QuestionId, [VoteId]>,
    _indexed_by_vote: WMap<VoteId, (QuestionId, Nat)>
  ) {

    public func findQuestionIteration(vote_id: VoteId) : Result<(QuestionId, Nat), FindQuestionIterationError> {
      switch(_indexed_by_vote.getOpt(vote_id)){
        case(null)                      { #err(#VoteNotFound);           };
        case(?(question_id, iteration)) { #ok((question_id, iteration)); };
      };
    };

    public func getQuestionIteration(vote_id: VoteId) : (QuestionId, Nat) {
      switch(findQuestionIteration(vote_id)){
        case(#ok((question_id, iteration))) { (question_id, iteration);     };
        case(#err(#VoteNotFound))           { Debug.trap("Vote not found"); };
      };
    };

    public func findVoteId(question_id: QuestionId, iteration: Nat) : Result<VoteId, FindVoteError> {
      let votes = switch(_indexed_by_question.getOpt(question_id)){
        case(null)   { return #err(#QuestionNotFound); };
        case(?votes) { votes;                          };
      };
      if (iteration >= votes.size()) {
        return #err(#IterationOutOfBounds);
      };
      #ok(votes[iteration]);
    };

    public func getVoteId(question_id: QuestionId, iteration: Nat) : VoteId {
      switch(findVoteId(question_id, iteration)){
        case(#ok(vote_id))                { vote_id                                };
        case(#err(#QuestionNotFound))     { Debug.trap("Question not found");      };
        case(#err(#IterationOutOfBounds)) { Debug.trap("Iteration out of bounds"); };
      };
    };

    public func getLastVoteId(question_id: QuestionId) : VoteId {
      switch(_indexed_by_question.getOpt(question_id)){
        case(null)   { Debug.trap("Question not found"); };
        case(?votes) { votes[votes.size() - 1];          };
      };
    };

    public func addJoin(question_id: QuestionId, vote_id: VoteId) {
      
      let votes = Option.get(_indexed_by_question.getOpt(question_id), []);
      
      if (Array.find(votes, func(id: VoteId) : Bool { id == vote_id; }) != null) {
        Debug.trap("This vote had already been added to the indexed_by_question map");
      };
      
      if(_indexed_by_vote.has(vote_id)){
        Debug.trap("This vote had already been added to the indexed_by_vote map");
      };

      _indexed_by_question.set(question_id, Utils.append(votes, [vote_id]));
      _indexed_by_vote.set(vote_id, (question_id, votes.size()));
    };

  };

};