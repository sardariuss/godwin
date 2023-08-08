import Types         "Types";
import Votes         "Votes";
import Decay         "Decay";
import Polarization  "representation/Polarization";
import Cursor        "representation/Cursor";

import WRef          "../../utils/wrappers/WRef";
import UtilsTypes    "../../utils/Types";

import Map           "mo:map/Map";

import Principal     "mo:base/Principal";
import Result        "mo:base/Result";
import Option        "mo:base/Option";
import Debug         "mo:base/Debug";

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
  type IVotersHistory     = Types.IVotersHistory;
  type VoteStatus         = Types.VoteStatus;
  type PutBallotError     = Types.PutBallotError;
  type DecayParameters    = Types.DecayParameters;
  type RevealableBallot     = Types.RevealableBallot<Answer>;
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
    voters_history: IVotersHistory,
    vote_decay: WRef<DecayParameters>,
    late_ballot_decay: WRef<DecayParameters>
  ) : Opinions {
    Opinions(
      Votes.Votes<Answer, Aggregate>(
        vote_register,
        voters_history,
        VotePolicy(vote_decay),
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
      _votes.lockVote(id, date);
    };

    public func closeVote(id: VoteId, date: Time) : async*() {
      await* _votes.closeVote(id, date);
    };

    public func putBallot(principal: Principal, id: VoteId, cursor: Cursor, date: Time) : async* Result<(), PutBallotError> {
      let late_decay = switch(getVote(id).status){
        case(#LOCKED) { ?Decay.computeDecay(_late_ballot_decay.get(), date); };
        case(_) { null; };
      };
      await* _votes.putBallot(principal, id, { answer = { cursor; late_decay; }; date; });
    };

    public func canVote(vote_id: VoteId, principal: Principal) : Result<(), PutBallotError> {
      _votes.canVote(vote_id, principal);
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

    public func revealBallot(caller: Principal, voter: Principal, vote_id: VoteId) : Result<RevealableBallot, FindBallotError> {
      _votes.revealBallot(caller, voter, vote_id);
    };

    public func hasBallot(principal: Principal, vote_id: VoteId) : Bool {
      _votes.hasBallot(principal, vote_id);
    };

  };

  class VotePolicy(_vote_decay: WRef<DecayParameters>) : IVotePolicy {

    public func isValidBallot(ballot: Ballot) : Result<(), PutBallotError> {
      if (not Cursor.isValid(ballot.answer.cursor)){
        return #err(#InvalidBallot);
      };
      #ok;
    };

    public func canVote(vote: Vote, principal: Principal) : Result<(), PutBallotError> {

      // If the vote is locked and the user voted when it was open, forbid the change
      if (vote.status == #LOCKED){
        switch(Map.get(vote.ballots, Map.phash, principal)){
          case(null) {};
          case(?ballot) {
            if (Option.isNull(ballot.answer.late_decay)) { 
              return #err(#ChangeBallotNotAllowed);
            };
          };
        };
      };

      #ok;
    };

    public func emptyAggregate(date: Time) : Aggregate {
      { polarization = Polarization.nil(); decay = null; };
    };

    public func addToAggregate(aggregate: Aggregate, new_ballot: Ballot, old_ballot: ?Ballot) : Aggregate {
      if (Option.isSome(aggregate.decay)){
        return aggregate;
      };
      if (Option.isSome(new_ballot.answer.late_decay)){
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

    public func onStatusChanged(status: VoteStatus, aggregate: Aggregate, date: Time) : Aggregate {
      if (status == #LOCKED){
        return { aggregate with decay = ?Decay.computeDecay(_vote_decay.get(), date); };
      };
      aggregate;
    };

    public func canRevealBallot(vote: Vote, caller: Principal, voter: Principal) : Bool {
      // The opinion ballot can always be revealed
      true;
    };
  };

};