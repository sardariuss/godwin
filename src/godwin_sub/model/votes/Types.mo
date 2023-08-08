import PayTypes            "../token/Types";
import Types               "../../stable/Types";
import UtilsTypes          "../../utils/Types";

import Principal           "mo:base/Principal";
import Result              "mo:base/Result";

import Set                 "mo:map/Set";

module {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  
  // For convenience: from other modules
  type Set<K> = Set.Set<K>;
  type Time = Int;

  type Duration               = UtilsTypes.Duration;

  public type Category        = Types.Current.Category;
  public type Cursor          = Types.Current.Cursor;
  public type Polarization    = Types.Current.Polarization;
  public type CursorMap       = Types.Current.CursorMap;
  public type PolarizationMap = Types.Current.PolarizationMap;
  public type Interest        = Types.Current.Interest;
  public type DecayParameters = Types.Current.DecayParameters;
  public type Appeal          = Types.Current.Appeal;
  public type VoteId          = Types.Current.VoteId;
  public type VoteStatus      = Types.Current.VoteStatus;
  public type Vote<T, A>      = Types.Current.Vote<T, A>;
  public type Ballot<T>       = Types.Current.Ballot<T>;

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

  public type VoteHistory = [VoteId];
  public type VoterHistory = Set<VoteId>;

  public type OpinionAnswer = {
    cursor: Cursor;
    late_decay: ?Float;
  };
  
  public type OpinionAggregate = {
    polarization: Polarization;
    decay: ?Float;
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

  public type IVotersHistory = {
    addVote: (Principal, VoteId) -> ();
    getVoterHistory: (Principal) -> [VoteId];
  };

  public type IVotePolicy<T, A> = {
    isValidBallot: (Ballot<T>) -> Result<(), PutBallotError>; // @todo: have another type of error
    canVote: (Vote<T, A>, Principal) -> Result<(), PutBallotError>;
    emptyAggregate: (Time) -> A;
    addToAggregate: (A, Ballot<T>,  ?Ballot<T>) -> A;
    onStatusChanged: (VoteStatus, A, Time) -> A;
    canRevealBallot: (Vote<T, A>, Principal, Principal) -> Bool;
  };

  public type InterestBallot = Ballot<Interest>;
  public type OpinionBallot = Ballot<OpinionAnswer>;
  public type CategorizationBallot = Ballot<CursorMap>;

  public type InterestVote = Vote<Interest, Appeal>;
  public type OpinionVote = Vote<OpinionAnswer, OpinionAggregate>;
  public type CategorizationVote = Vote<CursorMap, PolarizationMap>;

  public type Voter = {
    interests: Set<VoteId>;
    opinions: Set<VoteId>;
    categorizations: Set<VoteId>;
  };

  public type RevealableBallot<T> = {
    vote_id: VoteId;
    date: Time;
    can_change: Bool;
    answer: RevealableAnswer<T>;
  };

  public type RevealableAnswer<T> = {
    #REVEALED: T;
    #HIDDEN;
  };

  public type BallotChangeAuthorization = {
    #BALLOT_CHANGE_AUTHORIZED;
    #BALLOT_CHANGE_FORBIDDEN;
  };

  public type ComputeSelectionScoreArgs = {
    last_pick_date_ns: Time;
    last_pick_score: Float;
    num_votes_opened: Nat;
    minimum_score: Float;
    pick_period: Time;
    current_time: Time;
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