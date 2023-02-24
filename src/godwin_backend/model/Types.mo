import Trie "mo:base/Trie";
import Principal "mo:base/Principal";

import Map "mo:map/Map";
import Set "mo:map/Set";

import Duration "../utils/Duration";

module {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Time = Int;

  type Map<K, V> = Map.Map<K, V>;
  type Set<K> = Set.Set<K>;

  type Duration = Duration.Duration;

  public type UserParameters = {
    convictions_half_life: ?Duration;
  };

  public type SchedulerParameters = {
    interest_pick_rate: Duration;
    interest_duration: Duration;
    opinion_duration: Duration;
    categorization_duration: Duration;
    rejected_duration: Duration;
  };

  public type Parameters = {
    categories: [Category];
    users: UserParameters;
    scheduler: SchedulerParameters;
  };

  public type Decay = {
    lambda: Float;
    shift: Float; // Used to shift X so that the exponential does not underflow/overflow
  };

  public type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    date: Time;
    status_info: StatusInfo;
  };

  public type StatusInfo = {
    current: IndexedStatus;
    history: [IndexedStatus];
    iterations: [(Status, Nat)];
  };

  public type Status = {
    #VOTING: Poll;
    #CLOSED;
    #REJECTED;
    #TRASH;
  };

  public type Poll = {
    #INTEREST;
    #OPINION;
    #CATEGORIZATION;
  };

  public type IndexedStatus = {
    status: Status;
    date: Time;
    index: Nat;
  };

  public type VoteId = (Nat, Nat);

  public type Vote<T, A> = {
    question_id: Nat;
    iteration: Nat;
    date: Time; // @todo: redondant with IndexedStatus.date
    ballots: Map<Principal, Ballot<T>>;
    aggregate: A;
  };

  public type Ballot<T> = {
    date: Int;
    answer: T;
  };

  public type Category = Text;
  
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

  public type User = {
    principal: Principal;
    // Optional because we want the user to be able to log based solely on the II,
    // without requiring a user name.
    name: ?Text;  
    votes: Set<VoteId>;
    convictions: PolarizationMap;
  };

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

    // @todo: temporary

  public type CreateQuestionError = GetUserError or VerifyCredentialsError;
  
  public type CreateStatus = {
    #VOTING: {
      #INTEREST: { interest_score: Int; };
      #OPINION : { interest_score: Int; opinion_aggregate: Polarization; };
      #CATEGORIZATION : { interest_score: Int; opinion_aggregate: Polarization; categorization_aggregate: PolarizationArray; };
    };
    #CLOSED : { interest_score: Int; opinion_aggregate: Polarization; categorization_aggregate: PolarizationArray; };
    #REJECTED : { interest_score: Int; };
  };

};