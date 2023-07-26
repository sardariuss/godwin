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
    last_pick_date_ns : Time;
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
    negative_score_date: ?Time;
    hot_timestamp: Float;
    hotness: Float;
  };

  public type ScoreAndHotness = {
    score: Float;
    hotness: Float;
  };

  public type InterestVoteClosure = {
    #SELECTED;
    #TIMED_OUT;
    #CENSORED;
  };

  public type InterestDistribution = {
    shares: {
      up:   Float;
      down: Float;
    };
    reward_ratio: Float;
  };

  public type VoteId = Nat;
  public let voteHash = Map.nhash;

  public type VoteHistory = [VoteId];
  public type VoterHistory = Set<VoteId>;

  public type VoteStatus = {
    #OPEN;
    #LOCKED;
    #CLOSED;
  };

  public type Vote<T, A> = {
    id: VoteId;
    var status: VoteStatus;
    ballots: Map<Principal, Ballot<T>>;
    var aggregate: A;
  };

  public type Ballot<T> = {
    date: Time;
    answer: T;
  };

  public type IVotersHistory = {
    addVote: (Principal, VoteId) -> ();
    getVoterHistory: (Principal) -> [VoteId];
  };

  public type IVotePolicy<T, A> = {
    canPutBallot: (Vote<T, A>, Principal, Ballot<T>) -> Result<(), PutBallotError>;
    emptyAggregate: (Time) -> A;
    addToAggregate: (A, Ballot<T>,  ?Ballot<T>) -> A;
    onStatusChanged: (VoteStatus, A, Time) -> A;
    canRevealBallot: (Vote<T, A>, Principal, Principal) -> Bool;
  };

  public type InterestBallot = Ballot<Interest>;
  public type OpinionAnswer = {
    cursor: Cursor;
    late_decay: ?Float;
  };
  public type OpinionBallot = Ballot<OpinionAnswer>;
  public type OpinionAggregate = {
    polarization: Polarization;
    decay: ?Float;
  };
  public type CategorizationBallot = Ballot<CursorMap>;

  public type InterestVote = Vote<Interest, Appeal>;
  public type OpinionVote = Vote<OpinionAnswer, OpinionAggregate>;
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
  };

  public type BallotChangeAuthorization = {
    #BALLOT_CHANGE_AUTHORIZED;
    #BALLOT_CHANGE_FORBIDDEN;
  };

  public type VoteKind = {
    #INTEREST;
    #OPINION;
    #CATEGORIZATION;
  };

  public type VoteLink = {
    vote_kind: VoteKind;
    vote_id: Nat;
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