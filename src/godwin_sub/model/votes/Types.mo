import RepresentationTypes "representation/Types";
import PayTypes            "../token/Types";
import UtilsTypes          "../../utils/Types";

import Trie                "mo:base/Trie";
import Principal           "mo:base/Principal";
import Result              "mo:base/Result";

import Map                 "mo:map/Map";
import Set                 "mo:map/Set";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  // For convenience: from other modules
  type Map<K, V> = Map.Map<K, V>;
  type Set<K> = Set.Set<K>;
  type Time = Int;

  type Duration               = UtilsTypes.Duration;

  public type Category        = RepresentationTypes.Category;
  public type Cursor          = RepresentationTypes.Cursor;
  public type Polarization    = RepresentationTypes.Polarization;
  public type CursorMap       = RepresentationTypes.CursorMap;
  public type PolarizationMap = RepresentationTypes.PolarizationMap;
  
  public type Interest = {
    #UP;
    #DOWN;
  };

  public type InterestMomentumArgs = {
    last_pick_date : Time;
    last_pick_score: Float;
    num_votes_opened: Nat;
    minimum_score: Float;
  };

  public type DecayParameters = {
    half_life: Duration;
    lambda: Float;
    shift: Float; // Used to shift X so that the exponential does not underflow/overflow
  };

  public type Appeal = {
    ups: Nat;
    downs: Nat;
    score: Float;
    last_score_switch: ?Time;
  };

  public type VoteId = Nat;
  public let voteHash = Map.nhash;

  public type VoteHistory = [VoteId];
  public type VoterHistory = Set<VoteId>;

  public type Status = {
    #OPEN;
    #CLOSED;
  };

  public type Vote<T, A> = {
    id: VoteId;
    var status: Status;
    ballots: Map<Principal, Ballot<T>>;
    var aggregate: A;
    var decay: Float;
  };

  public type Ballot<T> = {
    date: Time;
    answer: T;
  };

  public type InterestBallot = Ballot<Interest>;
  public type OpinionBallot = Ballot<Cursor>;
  public type CategorizationBallot = Ballot<CursorMap>;

  public type InterestVote = Vote<Interest, Appeal>;
  public type OpinionVote = Vote<Cursor, Polarization>;
  public type CategorizationVote = Vote<CursorMap, PolarizationMap>;

  public type Voter = {
    interests: Set<VoteId>;
    opinions: Set<VoteId>;
    categorizations: Set<VoteId>;
  };

  public type RevealedBallot<T> = {
    vote_id: VoteId;
    date: Time;
    answer: ?T;
    transactions_record: ?PayTypes.TransactionsRecord;
  };

  public type BallotChangeAuthorization = {
    #BALLOT_CHANGE_AUTHORIZED;
    #BALLOT_CHANGE_FORBIDDEN;
  };

  public type RevealBallotAuthorization = {
    #REVEAL_BALLOT_ALWAYS;
    #REVEAL_BALLOT_VOTE_CLOSED;
  };

  public type PrincipalError = {
    #PrincipalIsAnonymous;
  };

  public type FindVoteError = {
    #QuestionNotFound;
    #IterationOutOfBounds;
  };

  public type FindQuestionIterationError = {
    #VoteNotFound;
  };

  public type OpenVoteError = PayTypes.TransferFromMasterError;

  public type GetVoteError = {
    #VoteNotFound;
  };

  public type RevealVoteError = {
    #VoteNotFound;
    #VoteOpen;
  };

  public type CloseVoteError = {
    #AlreadyClosed;
    #VoteNotFound;
    #NoSubacountLinked;
  };

  public type FindBallotError = {
    #BallotNotFound;
    #VoteNotFound;
  };

  public type AddBallotError = {
    #PrincipalIsAnonymous;
    #VoteClosed;
    #InvalidBallot;
  };

  public type RemoveBallotError = {
    #PrincipalIsAnonymous;
    #VoteNotFound;
    #VoteClosed;
    #ChangeBallotNotAllowed;
  };

  public type PutBallotError = AddBallotError or {
    #VoteLocked;
    #VoteNotFound;
    #ChangeBallotNotAllowed;
    #NoSubacountLinked;
    #PayinError: PayTypes.TransferFromMasterError;
  };

};