import Types             "Types";
import QuestionVoteJoins "QuestionVoteJoins";

import Map               "mo:map/Map";

import Utils             "../../utils/Utils";
import UtilsTypes        "../../utils/Types";

import Option            "mo:base/Option";

module {

  type VoteId             = Types.VoteId;
  type QuestionId         = Nat;
  type Map<K, V>          = Map.Map<K, V>;

  type ScanLimitResult<K> = UtilsTypes.ScanLimitResult<K>;
  type Direction          = UtilsTypes.Direction;

  type QuestionVoteJoins  = QuestionVoteJoins.QuestionVoteJoins;

  type QuestionVotes  = (QuestionId, Map<Nat, VoteId>);

  public class VotersHistory(
    _register: Map<Principal, Map<QuestionId, Map<Nat, VoteId>>>,
    _question_vote_joins: QuestionVoteJoins
  ){

    public func addVote(voter: Principal, vote_id: VoteId) {
      let voter_history = getVoterHistory(voter);
      let (question_id, iteration) = _question_vote_joins.getQuestionIteration(vote_id);
      let question_votes = Option.get(Map.get(voter_history, Map.nhash, question_id), Map.new<Nat, VoteId>(Map.nhash));
      // Add the vote to the question
      Map.set(question_votes, Map.nhash, iteration, vote_id);
      // Add the question to the voter history
      Map.set(voter_history, Map.nhash, question_id, question_votes);
      // Update the register
      Map.set(_register, Map.phash, voter, voter_history);
    };

    public func getVoterHistory(voter: Principal) : Map<QuestionId, Map<Nat, VoteId>> {
      Option.get(Map.get(_register, Map.phash, voter), Map.new<QuestionId, Map<Nat, VoteId>>(Map.nhash));
    };

    public func scanVoterHistory(voter: Principal, direction: Direction, limit: Nat, previous_id: ?QuestionId) : ScanLimitResult<QuestionVotes> {
      Utils.mapScanLimit(getVoterHistory(voter), Map.nhash, direction, limit, previous_id);
    };

  };

};