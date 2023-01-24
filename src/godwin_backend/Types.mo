import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Nat32 "mo:base/Nat32";

import Map "mo:map/Map";

module {

  // For convenience: from base module
  type Key<K> = Trie.Key<K>;
  type Trie<K, V> = Trie.Trie<K, V>;
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
    iterations: [(QuestionStatus, Nat)];
  };

  public type QuestionStatus = {
    #VOTING: Poll;
    #CLOSED;
    #REJECTED;
  };

  public type Poll = {
    #INTEREST;
    #OPINION;
    #CATEGORIZATION;
  };

  public func statusToText(status: QuestionStatus) : Text {
    switch(status){
      case(#VOTING(#INTEREST))       { "VOTING(INTEREST)"; };
      case(#VOTING(#OPINION))        { "VOTING(OPINION)"; };
      case(#VOTING(#CATEGORIZATION)) { "VOTING(CATEGORIZATION)"; };
      case(#CLOSED)                  { "CLOSED"; };
      case(#REJECTED)                { "REJECTED"; };
    };
  };

  public type IndexedStatus = {
    status: QuestionStatus;
    date: Time;
    index: Nat;
  };

  public type Category = Text;

  public func keyText(t: Text) : Key<Text> { { key = t; hash = Text.hash(t); } };
  public func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Nat32.fromNat(n); } };
  public func keyPrincipal(p: Principal) : Key<Principal> {{ key = p; hash = Principal.hash(p); };};

  func hashStatus(a: QuestionStatus) : Nat { Map.thash.0(statusToText(a)); };
  public func equalStatus(a: QuestionStatus, b: QuestionStatus) : Bool { Map.thash.1(statusToText(a), statusToText(b)); };
  public let status_hash : Map.HashUtils<QuestionStatus> = ( func(a) = hashStatus(a), func(a, b) = equalStatus(a, b));
  
  public type Interest = {
    #UP;
    #DOWN;
  };

  public type Appeal = {
    ups: Nat;
    downs: Nat;
    score: Int;
  };

  public type User = {
    principal: Principal;
    // Optional because we want the user to be able to log based solely on the II,
    // without requiring a user name.
    name: ?Text;  
    convictions: PolarizationMap;
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

  public type InterestBallot = Ballot<Interest>;
  public type OpinionBallot = Ballot<Cursor>;
  public type CategorizationBallot = Ballot<CursorMap>;

  public type TypedBallot = {
    #INTEREST: Ballot<Interest>;
    #OPINION: Ballot<Cursor>;
    #CATEGORIZATION: Ballot<CursorMap>;
  };

  public type TypedAnswer = {
    #INTEREST: Interest;
    #OPINION: Cursor;
    #CATEGORIZATION: CursorMap;
  };

  public type InterestVote =  Vote<Interest, Appeal>;
  public type OpinionVote =  Vote<Cursor, Polarization>;
  public type CategorizationVote =  Vote<CursorMap, PolarizationMap>;

  public type TypedVote = {
    #INTEREST: InterestVote;
    #OPINION: OpinionVote;
    #CATEGORIZATION: CategorizationVote;
  };

  // @todo: temporary

//  public type CreateQuestionError = {
//    #PrincipalIsAnonymous;
//    #InsufficientCredentials;
//  };
//  public type CreateQuestionStatus = {
//    #INTEREST: { interest_score: Int; };
//    #OPEN: {
//      #OPINION : { interest_score: Int; opinion_aggregate: Polarization; };
//      #CATEGORIZATION : { interest_score: Int; opinion_aggregate: Polarization; categorization_aggregate: PolarizationArray; };
//    };
//    #CLOSED : { interest_score: Int; opinion_aggregate: Polarization; categorization_aggregate: PolarizationArray; };
//    #REJECTED : { interest_score: Int; };
//  };

  public type VoteStatus = {
    #OPEN;
    #CLOSED;
  };

  public type Ballot<T> = {
    date: Int;
    answer: T;
  };

  public type Vote<T, A> = {
    question_id: Nat;
    iteration: Nat;
    date: Time;
    status: VoteStatus;
    ballots: Map.Map<Principal, Ballot<T>>;
    aggregate: A;
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

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public type OpenQuestionError = {
    #PrincipalIsAnonymous;
  };
  
  public type ReopenQuestionError = {
    #PrincipalIsAnonymous;
    #QuestionNotFound;
    #InvalidStatus;
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

  public type PutBallotError = {
    #PrincipalIsAnonymous;
    #QuestionNotFound;
    #InvalidStatus;
  };

  public type RemoveBallotError = {
    #PrincipalIsAnonymous;
    #QuestionNotFound;
    #NotAuthorized;
    #InvalidStatus;
  };

  public type GetBallotError = {
    #PrincipalIsAnonymous;
    #QuestionNotFound;
    #InvalidIteration;
  };

  public type SetPickRateError = VerifyCredentialsError;
  public type SetDurationError = VerifyCredentialsError;

};