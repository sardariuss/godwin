import RBT "mo:stableRBT/StableRBTree";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Int "mo:base/Int";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Time "mo:base/Time";

module {

  // For convenience: from base module
  type Key<K> = Trie.Key<K>;
  type Trie<K, V> = Trie.Trie<K, V>;
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;
  type Time = Time.Time;

  public type Duration = {
    #DAYS: Nat;
    #HOURS: Nat;
    #MINUTES: Nat;
    #SECONDS: Nat;
  };

  public type InputParameters = {
    selection_interval: Duration;
    reward_duration: Duration;
    categorization_duration: Duration;
    moderate_opinion_coef: Float;
    categories_definition: CategoriesDefinition;
    aggregation_parameters: AggregationParameters;
  };

  public type Parameters = {
    selection_interval: Time;
    reward_duration: Time;
    categorization_duration: Time;
    moderate_opinion_coef: Float;
    categories_definition: CategoriesDefinition;
    aggregation_parameters: AggregationParameters;
  };

  func toTime(duration: Duration) : Time {
    switch(duration) {
      case(#DAYS(days)){ days * 24 * 60 * 60 * 1_000_000_000; };
      case(#HOURS(hours)){ hours * 60 * 60 * 1_000_000_000; };
      case(#MINUTES(minutes)){ minutes * 60 * 1_000_000_000; };
      case(#SECONDS(seconds)){ seconds * 1_000_000_000; };
    };
  };

  public func getParameters(input: InputParameters) : Parameters {
    {
      selection_interval = toTime(input.selection_interval);
      reward_duration = toTime(input.reward_duration);
      categorization_duration = toTime(input.categorization_duration);
      moderate_opinion_coef = input.moderate_opinion_coef;
      categories_definition = input.categories_definition;
      aggregation_parameters = input.aggregation_parameters;
    }
  };

  public type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    endorsements: Nat;
    pool: {
      current: DatedPool;
      history: PoolHistory;
    };
    categorization: {
      current: DatedCategorization;
      history: CategorizationHistory;
    };
  };

  public type PoolHistory = [DatedPool];
  public type CategorizationHistory = [DatedCategorization];

  public type DatedPool = {
    date: Time;
    pool: Pool;
  };

  public type Category = Text;

  public type Sides = {
    left: Text;
    right: Text;
  };

  public type CategoryDefinition = {
    category: Category;
    sides: Sides;
  };

  public type CategoriesDefinition = [CategoryDefinition];

  public type Direction = {
    #LR;
    #RL;
  };

  public type OrientedCategory = {
    category: Category;
    direction: Direction;
  };

  public func keyText(t: Text) : Key<Text> { { key = t; hash = Text.hash(t) } };
  public func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Int.hash(n) } };
  public func keyPrincipal(p: Principal) : Key<Principal> {{ key = p; hash = Principal.hash(p); };};
  
  public type Endorsement = {
    #ENDORSE;
  };

  public func hashEndorsement(e : Endorsement) : Hash { Int.hash(0); };

  public func equalEndorsement(a: Endorsement, b: Endorsement) : Bool { 
    a == b;
  };

  public func toTextDir(direction: Direction) : Text {
    switch(direction){
      case(#LR){ "LR" };
      case(#RL){ "RL" };
    };
  };

  public func hashOrientedCategory(c: OrientedCategory) : Hash {
    Text.hash(c.category # toTextDir(c.direction));
  };

  public func equalOrientedCategory(a: OrientedCategory, b: OrientedCategory) : Bool {
    (a.category == b.category) and (a.direction == b.direction);
  };

   public type AgreementDegree = {
    #ABSOLUTE;
    #MODERATE;
  };

  public type Opinion = {
    #AGREE: AgreementDegree;
    #NEUTRAL;
    #DISAGREE: AgreementDegree;
  };

  public type Conviction = {
    left: Float;
    center: Float;
    right: Float;
  };

  public func toTextOpinion(opinion: Opinion) : Text {
    switch(opinion){
      case(#AGREE(conviction)){
        switch(conviction){
          case(#ABSOLUTE){"ABS_AGREE";};
          case(#MODERATE){"RATHER_AGREE";};
        };
      };
      case(#NEUTRAL){"NEUTRAL";};
      case(#DISAGREE(conviction)){
        switch(conviction){
          case(#ABSOLUTE){"ABS_DISAGREE";};
          case(#MODERATE){"RATHER_DISAGREE";};
        };
      };
    };
  };

  public func hashOpinion(opinion: Opinion) : Hash.Hash { 
    Text.hash(toTextOpinion(opinion));
  };

  public func equalOpinion(a: Opinion, b:Opinion) : Bool {
    a == b;
  };

  public func keyOpinion(opinion: Opinion) : Key<Opinion> {
    return { key = opinion; hash = hashOpinion(opinion); }
  };

  public type Pool = {
    #SPAWN;
    #REWARD;
    #ARCHIVE;
  };

  public type Categorization = {
    #PENDING;
    #ONGOING;
    #DONE: [OrientedCategory];
  };

  public type DatedCategorization = {
    date: Time;
    categorization: Categorization;
  };

  public func toTextPool(pool: Pool) : Text {
    switch(pool){
      case(#SPAWN){ "SPAWN"; };
      case(#REWARD){ "REWARD"; };
      case(#ARCHIVE){ "ARCHIVE"; };
    };
  };

  public func hashPool(pool: Pool) : Hash.Hash { 
    Text.hash(toTextPool(pool));
  };

  public func equalPool(a: Pool, b:Pool) : Bool {
    a == b;
  };

  public func keyPool(pool: Pool) : Key<Pool> {
    return { key = pool; hash = hashPool(pool); }
  };

  public type AggregationParameters = {
    direction_threshold: Float;
    category_threshold: Float;
  };

  public type User = {
    principal: Principal;
    name: ?Text;
    convictions: {
      to_update: Bool;
      array: ArrayConvictions;
    };
  };

  public type ArrayConvictions = [CategoryConviction];

  public type CategoryConviction = {
    category: Category;
    conviction: Conviction;
  };

  public type VoteRegister<B> = {
    // map<user, map<item, ballot>>
    ballots: Trie<Principal, Trie<Nat, B>>;
    // map<item, map<ballot, sum>>
    totals: Trie<Nat, TotalVotes<B>>;
  };

  public type TotalVotes<B> = {
    all: Nat;
    per_ballot: Trie<B, Nat>;
  };

  public type OrderBy = {
    #ID;
    #AUTHOR;
    #TITLE;
    #TEXT;
    #ENDORSEMENTS;
    #CREATION_DATE;
    #POOL_DATE;
    #CATEGORIZATION_DATE;
  };

  public type QueryQuestionsResult = { ids: [Nat]; next_id: ?Nat };

};