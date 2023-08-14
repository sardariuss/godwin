import Types               "Types";
import VoteTypes           "votes/Types";
import PayTypes            "token/Types";
import Categories          "Categories";
import Categorizations     "votes/Categorizations";
import Interests           "votes/Interests";
import Opinions            "votes/Opinions";

import Utils               "../utils/Utils";

import Principal           "mo:base/Principal";
import Result              "mo:base/Result";
import Trie                "mo:base/Trie";

import Map                 "mo:map/Map";

module {

  type Time                 = Int;
  type Principal            = Principal.Principal;
  type Result<Ok, Err>      = Result.Result<Ok, Err>;
  type Map<K, V>            = Map.Map<K, V>;

  type VoteId               = VoteTypes.VoteId;
  type RevealableBallot<T>  = VoteTypes.RevealableBallot<T>;
  type Ballot<T>            = VoteTypes.Ballot<T>;
  type GetVoteError         = VoteTypes.GetVoteError;
  type FindBallotError      = VoteTypes.FindBallotError;
  type RevealVoteError      = VoteTypes.RevealVoteError;
  type PutBallotError       = VoteTypes.PutBallotError;
  type Category             = VoteTypes.Category;
  type VoteKind             = VoteTypes.VoteKind;
  type Interest             = VoteTypes.Interest;
  type Cursor               = VoteTypes.Cursor;
  type CursorMap            = VoteTypes.CursorMap;
  type InterestVote         = VoteTypes.InterestVote;
  type OpinionVote          = VoteTypes.OpinionVote;
  type CategorizationVote   = VoteTypes.CategorizationVote;
  type InterestBallot       = VoteTypes.InterestBallot;
  type OpinionBallot        = VoteTypes.OpinionBallot;
  type CategorizationBallot = VoteTypes.CategorizationBallot;
  type OpinionAnswer        = VoteTypes.OpinionAnswer;
  type Appeal               = VoteTypes.Appeal;
  type OpinionAggregate     = VoteTypes.OpinionAggregate;
  type Polarization         = VoteTypes.Polarization;
  type PolarizationMap      = VoteTypes.PolarizationMap;

  type TransactionsRecord   = PayTypes.TransactionsRecord;

  type InterestVotes        = Interests.Interests;
  type OpinionVotes         = Opinions.Opinions;
  type CategorizationVotes  = Categorizations.Categorizations;

  type Vote<T, A>           = Types.Vote<T, A>;
  type CursorArray          = Types.CursorArray;
  type PolarizationArray    = Types.PolarizationArray;
  type KindAggregate        = Types.KindAggregate;
  type KindRevealableBallot = Types.KindRevealableBallot;
  type KindBallot           = Types.KindBallot;
  type KindAnswer           = Types.KindAnswer;
  type KindVote             = Types.KindVote;

  public class VoteFacade(
    _interest_votes: InterestVotes,
    _opinion_votes: OpinionVotes,
    _categorization_votes: CategorizationVotes,
  ){

    public func canVote(vote_kind: VoteKind, vote_id: VoteId, principal: Principal) : Result<(), PutBallotError> {
      switch(vote_kind){
        case (#INTEREST)       { _interest_votes.canVote(vote_id, principal);      };
        case (#OPINION)        { _opinion_votes.canVote(vote_id, principal);       };
        case (#CATEGORIZATION) { _categorization_votes.canVote(vote_id, principal);};
      };
    };

    public func putBallot(vote_kind: VoteKind, principal: Principal, id: VoteId, date: Time, answer: KindAnswer) : async* Result<(), PutBallotError> {
      switch(vote_kind, answer){
        case (#INTEREST,       #INTEREST(ans)      ) { await* _interest_votes.putBallot(principal, id, date, ans);                    };
        case (#OPINION,        #OPINION(ans)       ) { await* _opinion_votes.putBallot(principal, id, date, ans);                     };
        case (#CATEGORIZATION, #CATEGORIZATION(ans)) { await* _categorization_votes.putBallot(principal, id, date, toCursorMap(ans)); };
        case (_)                                     { #err(#BallotKindMismatch);                                                     };
      };
    };

    public func findVote(vote_kind: VoteKind, id: VoteId) : Result<KindVote, GetVoteError> {
      switch(vote_kind){
        case (#INTEREST)       { Result.mapOk(_interest_votes.findVote(id),       toInterestKindVote      ) };
        case (#OPINION)        { Result.mapOk(_opinion_votes.findVote(id),        toOpinionKindVote       ) };
        case (#CATEGORIZATION) { Result.mapOk(_categorization_votes.findVote(id), toCategorizationKindVote) };
      };
    };

    public func getVote(vote_kind: VoteKind, id: VoteId) : KindVote {
      switch(vote_kind){
        case (#INTEREST)       { toInterestKindVote      (_interest_votes.getVote(id));      };
        case (#OPINION)        { toOpinionKindVote       (_opinion_votes.getVote(id));       };
        case (#CATEGORIZATION) { toCategorizationKindVote(_categorization_votes.getVote(id));};
      };
    };
    
    public func findBallot(vote_kind: VoteKind, principal: Principal, id: VoteId) : Result<KindBallot, FindBallotError> {
      switch(vote_kind){
        case (#INTEREST)       { Result.mapOk(_interest_votes.findBallot(principal, id),       toInterestKindBallot      ); };
        case (#OPINION)        { Result.mapOk(_opinion_votes.findBallot(principal, id),        toOpinionKindBallot       ); };
        case (#CATEGORIZATION) { Result.mapOk(_categorization_votes.findBallot(principal, id), toCategorizationKindBallot); };
      };
    };

    public func getVoterBallots(vote_kind: VoteKind, voter: Principal) : Map<VoteId, KindBallot> {
      switch(vote_kind){
        case (#INTEREST)       { Map.map(_interest_votes.getVoterBallots(voter),       Map.nhash, func(id: VoteId, b: InterestBallot)       : KindBallot { toInterestKindBallot(b);       }); };
        case (#OPINION)        { Map.map(_opinion_votes.getVoterBallots(voter),        Map.nhash, func(id: VoteId, b: OpinionBallot)        : KindBallot { toOpinionKindBallot(b);        }); };
        case (#CATEGORIZATION) { Map.map(_categorization_votes.getVoterBallots(voter), Map.nhash, func(id: VoteId, b: CategorizationBallot) : KindBallot { toCategorizationKindBallot(b); }); };
      };
    };

    public func hasBallot(vote_kind: VoteKind, principal: Principal, vote_id: VoteId) : Bool {
      switch(vote_kind){
        case (#INTEREST)       { _interest_votes.hasBallot(principal, vote_id);       };
        case (#OPINION)        { _opinion_votes.hasBallot(principal, vote_id);        };
        case (#CATEGORIZATION) { _categorization_votes.hasBallot(principal, vote_id); };
      };
    };

    public func revealVote(vote_kind: VoteKind, id: VoteId) : Result<KindVote, RevealVoteError> {
      switch(vote_kind){
        case (#INTEREST)       { Result.mapOk(_interest_votes.revealVote(id),       toInterestKindVote      ); };
        case (#OPINION)        { Result.mapOk(_opinion_votes.revealVote(id),        toOpinionKindVote       ); };
        case (#CATEGORIZATION) { Result.mapOk(_categorization_votes.revealVote(id), toCategorizationKindVote); };
      };
    };

    public func revealAggregate(vote_kind: VoteKind, id: VoteId) : Result<KindAggregate, RevealVoteError> {
      switch(vote_kind){
        case (#INTEREST)       { Result.mapOk(_interest_votes.revealVote(id),       toInterestKindAggregate      ); };
        case (#OPINION)        { Result.mapOk(_opinion_votes.revealVote(id),        toOpinionKindAggregate       ); };
        case (#CATEGORIZATION) { Result.mapOk(_categorization_votes.revealVote(id), toCategorizationKindAggregate); };
      };
    };

    public func revealBallot(vote_kind: VoteKind, caller: Principal, voter: Principal, vote_id: VoteId) : Result<KindRevealableBallot, FindBallotError> {
      switch(vote_kind){
        case (#INTEREST)       { Result.mapOk(_interest_votes.revealBallot(caller, voter, vote_id),       toInterestKindRevealableBallot      ); };
        case (#OPINION)        { Result.mapOk(_opinion_votes.revealBallot(caller, voter, vote_id),        toOpinionKindRevealableBallot       ); };
        case (#CATEGORIZATION) { Result.mapOk(_categorization_votes.revealBallot(caller, voter, vote_id), toCategorizationKindRevealableBallot); };
      };
    };

    public func findBallotTransactions(vote_kind: VoteKind, principal: Principal, id: VoteId) : ?TransactionsRecord {
      switch(vote_kind){
        case (#INTEREST)       { _interest_votes.findBallotTransactions(principal, id);       };
        case (#OPINION)        { _opinion_votes.findBallotTransactions(principal, id);        };
        case (#CATEGORIZATION) { _categorization_votes.findBallotTransactions(principal, id); };
      };
    };

    func toInterestKindBallot(b: InterestBallot) : KindBallot {
      #INTEREST(b);
    };

    func toOpinionKindBallot(b: OpinionBallot) : KindBallot {
      #OPINION(b);
    };

    func toCategorizationKindBallot(b: CategorizationBallot) : KindBallot {
      #CATEGORIZATION({ date = b.date; answer = toCursorArray(b.answer); });
    };

    func toInterestKindVote(v: InterestVote) : KindVote {
      #INTEREST({ id = v.id; aggregate = v.aggregate; ballots = Utils.trieToArray(v.ballots); });
    };

    func toOpinionKindVote(v: OpinionVote) : KindVote {
      #OPINION({ id = v.id;  aggregate = v.aggregate; ballots = Utils.trieToArray(v.ballots); });
    };

    func toCategorizationKindVote(v: CategorizationVote) : KindVote {
      #CATEGORIZATION({ 
        id = v.id;
        aggregate = toPolarizationArray(v.aggregate);
        ballots = Utils.trieToArray(Trie.mapFilter<Principal, Ballot<CursorMap>, Ballot<CursorArray>>(
          v.ballots, func(p: Principal, b: Ballot<CursorMap>) : ?Ballot<CursorArray> { 
            ?{ date = b.date; answer = toCursorArray(b.answer); };
          }
        ));
      });
    };

    func toInterestKindRevealableBallot(b: RevealableBallot<Interest>) : KindRevealableBallot {
      #INTEREST(b);
    };

    func toOpinionKindRevealableBallot(b: RevealableBallot<OpinionAnswer>) : KindRevealableBallot {
      #OPINION(b);
    };

    func toCategorizationKindRevealableBallot(b: RevealableBallot<CursorMap>) : KindRevealableBallot {
      #CATEGORIZATION({ b with answer = switch(b.answer){
        case(#REVEALED(ans)) { #REVEALED(toCursorArray(ans)) };
        case(#HIDDEN)        { #HIDDEN                       };
      }});
    };

    func toInterestKindAggregate(v: InterestVote) : KindAggregate {
      #INTEREST(v.aggregate);
    };

    func toOpinionKindAggregate(v: OpinionVote) : KindAggregate {
      #OPINION(v.aggregate);
    };

    func toCategorizationKindAggregate(v: CategorizationVote) : KindAggregate {
      #CATEGORIZATION(toPolarizationArray(v.aggregate));
    };
    
    func toCursorMap(array: CursorArray) : CursorMap {
      Utils.arrayToTrie(array, Categories.key, Categories.equal);
    };

    func toPolarizationArray(map: PolarizationMap) : PolarizationArray {
      Utils.trieToArray(map);
    };

    func toCursorArray(map: CursorMap) : CursorArray {
      Utils.trieToArray(map);
    };

  };

};