import Types         "Types";
import Votes         "Votes";
import Decay         "Decay";
import Polarization  "representation/Polarization";
import Cursor        "representation/Cursor";

import WRef       "../../utils/wrappers/WRef";
import UtilsTypes "../../utils/Types";

import Map        "mo:map/Map";

import Principal  "mo:base/Principal";
import Result     "mo:base/Result";
import Option     "mo:base/Option";
import Debug      "mo:base/Debug";

module {

  type Time               = Int;
  type VoteId             = Types.VoteId;
  type Cursor             = Types.Cursor;

  // For convenience: from base module
  type Principal          = Principal.Principal;
  type Result<Ok, Err>    = Result.Result<Ok, Err>;
    
  type Map<K, V>          = Map.Map<K, V>;
  type WRef<T>            = WRef.WRef<T>;

  type Answer             = Types.OpinionAnswer;
  type Ballot             = Types.OpinionBallot;
  type Vote               = Types.OpinionVote;
  type Aggregate          = Types.OpinionAggregate;
  type IVotePolicy        = Types.IVotePolicy<Answer, Aggregate>;
  type PutBallotError     = Types.PutBallotError;
  type DecayParameters    = Types.DecayParameters;
  type RevealedBallot     = Types.RevealedBallot<Answer>;
  type GetVoteError       = Types.GetVoteError;
  type FindBallotError    = Types.FindBallotError;
  type RevealVoteError    = Types.RevealVoteError;

  type ScanLimitResult<K> = UtilsTypes.ScanLimitResult<K>;
  type Direction          = UtilsTypes.Direction;

  public type Register    = Votes.Register<Answer, Aggregate>;


  public func initRegister() : Register {
    Votes.initRegister<Answer, Aggregate>();
  };

  public func build(
    vote_register: Votes.Register<Answer, Aggregate>,
    vote_decay: WRef<DecayParameters>,
    late_ballot_decay: WRef<DecayParameters>
  ) : Opinions {
    Opinions(
      Votes.Votes<Answer, Aggregate>(
        vote_register,
        VotePolicy(),
        null
      ),
      vote_decay,
      late_ballot_decay);
  };

  public class Opinions(
    _votes: Votes.Votes<Answer, Aggregate>,
    _vote_decay: WRef<DecayParameters>,
    _late_ballot_decay: WRef<DecayParameters>
  ){

    public func getVoteDecay() : DecayParameters {
      _vote_decay.get();
    };

    public func getLateBallotDecay() : DecayParameters {
      _late_ballot_decay.get();
    };

    public func newVote(date: Time) : VoteId {
      _votes.newVote(date);
    };

    public func lockVote(id: VoteId, date: Time) {
      let vote = _votes.getVote(id);
      if (Option.isSome(vote.aggregate.is_locked)){
        Debug.trap("The vote is already locked");
      };
      vote.aggregate := { vote.aggregate with is_locked = ?Decay.computeDecay(getVoteDecay(), date); };
    };

    public func isLocked(id: VoteId) : ?Float {
      let vote = _votes.getVote(id);
      vote.aggregate.is_locked;
    };

    public func closeVote(id: VoteId, date: Time) : async*() {
      await* _votes.closeVote(id, date);
    };

    public func putBallot(principal: Principal, id: VoteId, cursor: Cursor, date: Time) : async* Result<(), PutBallotError> {
      let is_late = if (Option.isSome(isLocked(id))) { ?Decay.computeDecay(getLateBallotDecay(), date); } else { null; };
      await* _votes.putBallot(principal, id, { answer = { cursor; is_late; }; date; });
    };

    public func findVote(id: VoteId) : Result<Vote, GetVoteError> {
      _votes.findVote(id);
    };

    public func getVote(id: VoteId) : Vote {
      _votes.getVote(id);
    };

    public func findBallot(principal: Principal, id: VoteId) : Result<Ballot, FindBallotError> {
      _votes.findBallot(principal, id);
    };

    public func getVoterBallots(principal: Principal) : Map<VoteId, Ballot> {
      _votes.getVoterBallots(principal);
    };

    public func revealVote(id: VoteId) : Result<Vote, RevealVoteError> {
      _votes.revealVote(id);
    };

    public func revealBallot(caller: Principal, voter: Principal, vote_id: VoteId) : Result<RevealedBallot, FindBallotError> {
      _votes.revealBallot(caller, voter, vote_id);
    };

    public func revealBallots(caller: Principal, voter: Principal, direction: Direction, limit: Nat, previous_id: ?VoteId) : ScanLimitResult<RevealedBallot> {
      _votes.revealBallots(caller, voter, direction, limit, previous_id);
    };

  };

  class VotePolicy() : IVotePolicy {

    public func canPutBallot(vote: Vote, principal: Principal, ballot: Ballot) : Result<(), PutBallotError> {

      // Verify the ballot is valid
      if (not Cursor.isValid(ballot.answer.cursor)){
        return #err(#InvalidBallot);
      };

      switch((vote.aggregate.is_locked, ballot.answer.is_late)){
        case((null, ?late)) {    // Unlocked vote, late ballot
          Debug.trap("Unlocked votes cannot accept late ballots");
        };
        case((?locked, null)) {  // Locked vote, on-time ballot
          Debug.trap("Locked votes only accept late ballots");
        };
        case((?locked, ?late)) { // Locked vote, late ballot
          switch(Map.get(vote.ballots, Map.phash, principal)){
            case(null) {};
            case(?old) {
              // If the user had given an official vote (when the vote was not locked yet), he cannot update his ballot
              if (Option.isNull(old.answer.is_late)) { 
                return #err(#ChangeBallotNotAllowed);
              };
            };
          };
        };
        case(_) {};
      };

      #ok;
    };

    public func emptyAggregate() : Aggregate {
      { polarization = Polarization.nil(); is_locked = null; };
    };

    public func onPutBallot(aggregate: Aggregate, new_ballot: Ballot, old_ballot: ?Ballot) : Aggregate {
      if (Option.isSome(aggregate.is_locked)){
        return aggregate;
      };
      if (Option.isSome(new_ballot.answer.is_late)){
        Debug.trap("A late ballot should never alter to the opinion aggregate");
      };
      var polarization = aggregate.polarization;
      // Add the new ballot to the polarization
      polarization := Polarization.addCursor(polarization, new_ballot.answer.cursor);
      // If there was an old ballot, remove it from the polarization
      Option.iterate(old_ballot, func(ballot: Ballot) {
        polarization := Polarization.subCursor(polarization, ballot.answer.cursor);
      });
      { aggregate with polarization; };
    };

    public func onVoteClosed(aggregate: Aggregate, date: Time) : Aggregate {
      aggregate;
    };

    public func canRevealVote(vote: Vote) : Bool {
      vote.status == #CLOSED or vote.aggregate.is_locked != null;
    };

    public func canRevealBallot(vote: Vote, caller: Principal, voter: Principal) : Bool {
      // The opinion ballot can always be revealed
      true;
    };
  };

};