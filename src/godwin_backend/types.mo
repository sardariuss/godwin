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

  public type SchedulerParams = {
    selection_rate: Time;
    selection_duration: Time;
    categorization_duration: Time;
  };

  public type InputSchedulerParams = {
    selection_rate: Duration;
    selection_duration: Duration;
    categorization_duration: Duration;
  };

  public type InputParameters = {
    scheduler: InputSchedulerParams;
    categories_definition: InputCategoriesDefinition;
  };

  public type Parameters = {
    scheduler: SchedulerParams;
    categories_definition: CategoriesDefinition;
  };

  public type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    date: Time;
    endorsements: Nat;
    selection_stage: StageHistory<SelectionStage>;
    categorization_stage: StageHistory<CategorizationStage>;
  };

  public type StageRecord<S> = {
    timestamp: Time;
    stage: S;
  };

  public type StageHistory<S> = [StageRecord<S>];

  public type Category = Text;

  public type Sides = {
    left: Text;
    right: Text;
  };

  public type InputCategoriesDefinition = [(Category, Sides)];
  
  public type CategoriesDefinition = Trie<Category, Sides>;

  public func keyText(t: Text) : Key<Text> { { key = t; hash = Text.hash(t) } };
  public func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Int.hash(n) } };
  public func keyPrincipal(p: Principal) : Key<Principal> {{ key = p; hash = Principal.hash(p); };};
  
  public type Endorsement = {
    #ENDORSE;
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

  public type OpinionsTotal = {
    agree: Float;
    neutral: Float;
    disagree: Float;
  };

  public type SelectionStage = {
    #CREATED;
    #SELECTED;
    #ARCHIVED: OpinionsTotal;
  };

  public type SelectionStageEnum = {
    #CREATED;
    #SELECTED;
    #ARCHIVED;
  };

  public type CategorizationArray = [(Category, Float)];

  public type Categorization = Trie<Category, Float>;

  public type CategorizationStage = {
    #PENDING;
    #ONGOING;
    #DONE: CategorizationArray;
  };

  public type CategorizationStageEnum = {
    #PENDING;
    #ONGOING;
    #DONE;
  };

  public type User = {
    principal: Principal;
    name: ?Text;
    convictions: {
      to_update: Bool;
      categorization: CategorizationArray;
    };
  };

};