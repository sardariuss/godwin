import Trie "mo:base/Trie";
import Principal "mo:base/Principal";
import Result "mo:base/Result";

import ICRC1 "mo:icrc1/ICRC1";

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

  type TransferFromUserError = ICRC1.TransferError or CredentialErrors;

  public type Master = actor {
    transferToSubGodwin: shared(Principal, ICRC1.Balance, Blob) -> async Result<(), TransferFromUserError>;
  };

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
    status_info: StatusInfo;
  };

  public type StatusInfo = {
    status: Status;
    iteration: Nat;
    date: Time;
  };

  public type StatusData = {
    #CANDIDATE: { vote_interest:       Vote<Interest, Appeal>;              };
    #OPEN:      { vote_opinion:        Vote<Cursor, Polarization>;
                  vote_categorization: Vote<CursorMap, PolarizationMap>;    };
    #CLOSED:    ();
    #REJECTED:  ();
    #TRASH:     ();
  };

  public type StatusHistory = Map<Status, [Time]>;

  public type UserHistory = {
    convictions: PolarizationMap;
    votes: Set<VoteId>;
  };

  public type Status = {
    #CANDIDATE;
    #OPEN;
    #CLOSED;
    #REJECTED;
    #TRASH;
  };

  public type VoteId = (Nat, Nat);

  public type Vote<T, A> = {
    question_id: Nat;
    ballots: Map<Principal, Ballot<T>>;
    aggregate: A;
  };

  public type PublicVote<T, A> = {
    question_id: Nat;
    ballots: [(Principal, Ballot<T>)];
    aggregate: A;
  };

  public type Ballot<T> = {
    date: Int;
    answer: T;
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

  public type GetUserError = {
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

  public type OpenQuestionError = GetUserError;
  
  public type ReopenQuestionError = GetUserError or GetQuestionError or {
    #InvalidStatus;
  };

  public type SetUserNameError = GetUserError;

  public type SetPickRateError = VerifyCredentialsError;

  public type SetDurationError = VerifyCredentialsError;

  public type GetUserConvictionsError = GetUserError;

  public type GetUserVotesError = GetUserError;

  public type GetAggregateError = GetQuestionError or {
    #NotAllowed;
  };

  public type GetBallotError = GetQuestionError or {
    #NotAllowed;
  };

  public type RevealBallotError = GetUserError or GetQuestionError or {
    #InvalidPoll;
  };

  public type PutBallotError = GetUserError or GetQuestionError or {
    #InvalidPoll;
    #InvalidBallot;
  };

  public type PutFreshBallotError = GetUserError or GetQuestionError or {
    #InvalidPoll;
    #AlreadyVoted;
    #InvalidBallot;
  };

};