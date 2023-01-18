import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";

import Map "mo:map/Map";

module {

  // For convenience: from base module
  type Key<K> = Trie.Key<K>;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Set<K> = TrieSet.Set<K>;
  type Principal = Principal.Principal;
  type Time = Int;

  public type Duration = {
    #DAYS: Nat;
    #HOURS: Nat;
    #MINUTES: Nat;
    #SECONDS: Nat;
    #NS: Nat; // To be able to ease the tests on the scheduler
  };

  public type UserParameters = {
    convictions_half_life: ?Duration;
  };

  public type SchedulerParameters = {
    selection_rate: Duration;
    status_durations: [(Status, Duration)];
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

  public type Status = {
    #CANDIDATE;
    #OPEN: {
      #OPINION;
      #CATEGORIZATION;
    };
    #CLOSED;
    #REJECTED;
  };

  public func statusToNat(status: Status) : Nat {
    switch(status){
      case(#CANDIDATE)             { 0; };
      case(#OPEN(#OPINION))        { 1; };
      case(#OPEN(#CATEGORIZATION)) { 2; };
      case(#CLOSED)                { 3; };
      case(#REJECTED)              { 4; };
    };
  };

  public type QuestionStatus = {
    #CANDIDATE: Vote<Interest, InterestAggregate>;
    #OPEN: { stage: VotingStage; iteration: Iteration; };
    #CLOSED: Time;
    #REJECTED: Time;
  };

  public type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    date: Time;
    status: QuestionStatus;
    interests_history: [Vote<Interest, InterestAggregate>];
    vote_history: [Iteration];
  };

  public type VotingStage = {
    #OPINION;
    #CATEGORIZATION;
  };

  public type Iteration = {
    opinion: Vote<Cursor, Polarization>;
    categorization: Vote<CategoryCursorTrie, CategoryPolarizationTrie>;
  };

  public type Vote<B, A> = {
    date: Int;
    ballots: Trie<Principal, B>;
    aggregate: A;
  };

  public type Category = Text;

  public func keyText(t: Text) : Key<Text> { { key = t; hash = Text.hash(t); } };
  public func keyNat32(n: Nat32) : Key<Nat32> { { key = n; hash = n; } };
  public func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Nat32.fromNat(n); } };
  public func keyPrincipal(p: Principal) : Key<Principal> {{ key = p; hash = Principal.hash(p); };};

  let { nhash } = Map;
  func hashStatus(a: Status) : Nat { nhash.0(statusToNat(a)); };
  func equalStatus(a: Status, b: Status) : Bool { nhash.1(statusToNat(a), statusToNat(b)); };
  public let statushash : Map.HashUtils<Status> = ( func(a) = hashStatus(a), func(a, b) = equalStatus(a, b));
  
  public type Interest = {
    #UP;
    #DOWN;
  };

  public type InterestAggregate = {
    ups: Nat;
    downs: Nat;
    score: Int;
  };

  public type User = {
    principal: Principal;
    // Optional because we want the user to be able to log based solely on the II,
    // without requiring a user name.
    name: ?Text;  
    convictions: CategoryPolarizationTrie;
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
  public type CategoryCursorTrie = Trie<Category, Cursor>;
  public type CategoryCursorArray = [(Category, Cursor)];
  
  // Mapping of <key=Category, value=Polarization>, used to represent a question political affinity
  public type CategoryPolarizationTrie = Trie<Category, Polarization>;
  public type CategoryPolarizationArray = [(Category, Polarization)];

  // @todo: temporary
  public type CreateQuestionStatus = {
    #CANDIDATE: { interest_score: Int; };
    #OPEN: {
      #OPINION : { interest_score: Int; opinion_aggregate: Polarization; };
      #CATEGORIZATION : { interest_score: Int; opinion_aggregate: Polarization; categorization_aggregate: CategoryPolarizationArray; };
    };
    #CLOSED : { interest_score: Int; opinion_aggregate: Polarization; categorization_aggregate: CategoryPolarizationArray; };
    #REJECTED : { interest_score: Int; };
  };

  public type Timestamp<T> = {
    elem: T;
    date: Time;
  };

  public type Ref<V> = {
    var v: V;
  };

  public func initRef<V>(value: V) : Ref<V> {
    { var v = value; };
  };

  public type AddCategoryError = {
    #InsufficientCredentials;
    #CategoryAlreadyExists;
  };

  public type RemoveCategoryError = {
    #InsufficientCredentials;
    #CategoryDoesntExist;
  };

  public type SetSchedulerParamError = {
    #InsufficientCredentials;
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public type CreateQuestionError = {
    #PrincipalIsAnonymous;
    #InsufficientCredentials;
  };

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
  };

  public type InterestError = {
    #PrincipalIsAnonymous;
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public type OpinionError = {
    #PrincipalIsAnonymous;
    #InvalidOpinion;
    #QuestionNotFound;
    #InvalidVotingStage;
  };

  public type CategorizationError = {
    #PrincipalIsAnonymous;
    #InvalidVotingStage;
    #InvalidCategorization;
    #QuestionNotFound;
  };

  public type SetUserNameError = {
    #PrincipalIsAnonymous;
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  public type GetUserError = {
    #PrincipalIsAnonymous;
  };

};