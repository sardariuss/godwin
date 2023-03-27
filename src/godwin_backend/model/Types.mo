import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

//import ICRC1 "mo:icrc1/ICRC1";

import Map "mo:map/Map";
import Set "mo:map/Set";

import Duration "../utils/Duration";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Time = Int;
  type Result<Ok, Err> = Result.Result<Ok, Err>;

  type Map<K, V> = Map.Map<K, V>;
  type Set<K> = Set.Set<K>;

  type Duration = Duration.Duration;

  public type HistoryParameters = {
    convictions_half_life: ?Duration;
  };

  public type SchedulerParameters = {
    interest_pick_rate: Duration;
    interest_duration: Duration;
    opinion_duration: Duration;
    rejected_duration: Duration;
  };

  type CredentialErrors = {
    #NotAllowed;
  };

//  type TransferFromUserError = ICRC1.TransferError or CredentialErrors;

//  public type Master = actor {
//    transferToSubGodwin: shared(Principal, ICRC1.Balance, Blob) -> async Result<(), TransferFromUserError>;
//  };

  public type Parameters = {
    categories: CategoryArray;
    history: HistoryParameters;
    scheduler: SchedulerParameters;
  };

  public type Decay = {
    lambda: Float;
    shift: Float; // Used to shift X so that the exponential does not underflow/overflow
  };

  public type Question = {
    id: Nat;
    author: Principal;
    text: Text;
    date: Time;
  };

  public type StatusHistory = Map<Status, [Time]>;

  public type User = {
    convictions: PolarizationMap;
    opinions: Set<Nat>;
  };

  public type Status = {
    #CANDIDATE;
    #OPEN;
    #CLOSED;
    #REJECTED;
  };

  public type StatusInfo = {
    status: Status;
    iteration: Nat;
    date: Time;
  };

  public type StatusData = {
    var current: StatusInfo;
    history: Map<Status, [Time]>;
  };

  public type VoteStatus = {
    #OPEN;
    #CLOSED;
  };

  public type Vote<T, A> = {
    id: Nat;
    var status: VoteStatus;
    ballots: Map<Principal, Ballot<T>>;
    var aggregate: A;
  };

  public type PublicVote<T, A> = {
    id: Nat;
    status: VoteStatus;
    ballots: [(Principal, Ballot<T>)];
    aggregate: A;
  };

  public type Ballot<T> = {
    date: Int;
    answer: T;
  };

  public type VoteHistory = {
    current: ?Nat;
    history: [Nat];
  };

  public type Category = Text;
  
  public type CategoryArray = [(Category, CategoryInfo)];

  public type CategoryInfo = {
    left: CategorySide;
    right: CategorySide;
  };

  public type CategorySide = {
    name: Text;
    symbol: Text;
    color: Text;
  };
  
  public type Interest = {
    #UP;
    #DOWN;
  };

  public type Appeal = {
    ups: Nat;
    downs: Nat;
    score: Int;
  };

  // Cursor used for voting, shall be between -1 and 1, where usually:
  //  -1 means voting totally for A
  //   0 means voting totally neutral
  //   1 means voting totally for B
  //  in between values mean voting for A or B with more or less reserve.
  //
  // Example: cursor of 0.5, which means voting for B with some reserve.
  // -1                            0                             1
  // [-----------------------------|--------------()-------------]
  //
  public type Cursor = Float;

  // Polarization, used mainly to store the result of a vote.
  // Polarizations are never normalized in the backend in order to not
  // loosing its magnitude (which can represent different things, usually
  // how many people voted).
  //
  // Example: { left = 13; center = 8; right = 36; }
  // [$$$$$$$$$$$$$|@@@@@@@@|&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&]
  //     left        center                 right 
  // 
  public type Polarization = {
    left: Float;
    center: Float;
    right: Float;
  };

  // Mapping of <key=Category, value=Cursor>, used to vote to determine a question political affinity
  public type CursorMap = Trie<Category, Cursor>;
  public type CursorArray = [(Category, Cursor)];
  
  // Mapping of <key=Category, value=Polarization>, used to represent a question political affinity
  public type PolarizationMap = Trie<Category, Polarization>;
  public type PolarizationArray = [(Category, Polarization)];

  public type PrincipalError = {
    #PrincipalIsAnonymous;
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  public type AddCategoryError = VerifyCredentialsError or {
    #CategoryAlreadyExists;
  };

  public type RemoveCategoryError = VerifyCredentialsError or {
    #CategoryDoesntExist;
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public type OpenQuestionError = PrincipalError;
  
  public type ReopenQuestionError = PrincipalError or GetQuestionError or {
    #InvalidStatus;
  };

  public type SetUserNameError = PrincipalError;

  public type SetPickRateError = VerifyCredentialsError;

  public type SetDurationError = VerifyCredentialsError;

  public type GetUserConvictionsError = PrincipalError;

  public type GetUserVotesError = PrincipalError;

  public type GetVoteError = {
    #VoteIsOpen;
    #VoteNotFound;
    #QuestionVoteLinkNotFound;
    #QuestionVoteLinkNotFound2;
  };

  public type CloseVoteError = {
    #AlreadyClosed;
    #VoteNotFound;
  };

  public type GetAggregateError = GetVoteError or {
    #NotAllowed;
  };

  public type GetBallotError = GetVoteError or {
    #NotAllowed;
    #BallotNotFound;
  };

  public type PutBallotError = PrincipalError or GetVoteError or {
    #InvalidPoll;
    #VoteClosed;
    #InvalidBallot;
    #AlreadyVoted;
  };

};