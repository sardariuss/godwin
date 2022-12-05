import Trie "mo:base/Trie";
import TrieSet "mo:base/TrieSet";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

module {

  // For convenience: from base module
  type Key<K> = Trie.Key<K>;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Set<K> = TrieSet.Set<K>;
  type Principal = Principal.Principal;
  type Time = Time.Time;

  public type Duration = {
    #DAYS: Nat;
    #HOURS: Nat;
    #MINUTES: Nat;
    #SECONDS: Nat;
    #NS: Nat; // To be able to ease the test on the scheduler
  };

  public type SchedulerParams = {
    selection_rate: Duration;
    selection_duration: Duration;
    categorization_duration: Duration;
  };

  public type Parameters = {
    scheduler: SchedulerParams;
    categories: [Category];
  };

  public type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    date: Time;
//    votes: {
//      current: Iteration;
//      history: [Iteration];
//    };
    interests: InterestAggregate;
    selection_stage: StageHistory<SelectionStage>;
    categorization_stage: StageHistory<CategorizationStage>;
  };

  public type VoteType = {
    #INTEREST;
    #OPINION;
    #CATEGORIZATION;
    #NONE;
  };
  
  public type Iteration = {
    id: Nat;
    question_id: Nat;
    opening_date: Int;
    closing_date: ?Int;
    current: VoteType;
    interest: Vote<Interest, InterestAggregate>;
    opinion: Vote<Cursor, Polarization>;
    categorization: Vote<CategoryCursorTrie, CategoryPolarizationTrie>;
  };

  public type VoteState = {
    #PENDING;
    #OPEN;
    #CLOSED;
  };

  public type Vote<B, A> = {
    state: VoteState;
    ballots: Trie<Principal, B>;
    aggregate: A;
  };

  public type StageRecord<S> = {
    timestamp: Time;
    stage: S;
  };

  public type StageHistory<S> = [StageRecord<S>];

  public type Category = Text;

  public func keyText(t: Text) : Key<Text> { { key = t; hash = Text.hash(t) } };
  public func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Int.hash(n) } };
  public func keyPrincipal(p: Principal) : Key<Principal> {{ key = p; hash = Principal.hash(p); };};
  
  public type Interest = {
    #UP;
    #DOWN;
  };

  public type InterestAggregate = {
    ups: Nat;
    downs: Nat;
    score: Int;
  };

  public type SelectionStage = {
    #CREATED;
    #SELECTED;
    #ARCHIVED: Polarization;
  };

  // The enum is required to be able to compare stages to not have to give
  // a Polarization for the #ARCHIVED stage
  public type SelectionStageEnum = {
    #CREATED;
    #SELECTED;
    #ARCHIVED;
  };

  public type CategorizationStage = {
    #PENDING;
    #ONGOING;
    #DONE: CategoryPolarizationArray;
  };

  // The enum is required to be able to compare stages to not have to give
  // a CategoryPolarizationArray for the #DONE stage
  public type CategorizationStageEnum = {
    #PENDING;
    #ONGOING;
    #DONE;
  };

  public type User = {
    principal: Principal;
    // Optional because we want the user to be able to log based solely on the II,
    // without requiring a user name.
    name: ?Text;  
    // Convictions: political profile (left/center/right for every categories based on user's answers)
    convictions: {
      to_update: Bool;
      array: CategoryPolarizationArray;
    };
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

};