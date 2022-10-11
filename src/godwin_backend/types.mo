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
    categories_definition: InputCategoriesDefinition;
  };

  public type Parameters = {
    selection_interval: Time;
    reward_duration: Time;
    categorization_duration: Time;
    categories_definition: CategoriesDefinition;
  };

  public type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    date: Time;
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

  public type InputCategoriesDefinition = [(Category, Sides)];
  
  public type CategoriesDefinition = Trie<Category, Sides>;

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

  public type AgreementDegree = {
    #ABSOLUTE;
    #MODERATE;
  };

  public type Opinion = {
    #AGREE: AgreementDegree;
    #NEUTRAL;
    #DISAGREE: AgreementDegree;
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

  public type InputProfile = [(Category, Float)];

  public type Profile = Trie<Category, Float>;

  public type Categorization = {
    #PENDING;
    #ONGOING;
    #DONE: Profile;
  };

  public func toTextCategorization(categorization: Categorization) : Text {
    switch(categorization){
      case(#PENDING){ "PENDING"; };
      case(#ONGOING){ "ONGOING"; };
      case(#DONE(profile)){ "DONE"; };
    };
  };

  public func hashCategorization(categorization: Categorization) : Hash.Hash { 
    Text.hash(toTextCategorization(categorization));
  };

  public func equalCategorization(a: Categorization, b:Categorization) : Bool {
    a == b;
  };

  public type DatedCategorization = {
    date: Time;
    categorization: Categorization;
  };

  public func toTextPool(pool: Pool) : Text {
    switch(pool){
      case(#SPAWN){ "SPAWN"; };
      case(#REWARD){ "REWARD"; };
      case(#ARCHIVE){ "ARCHIVE"; }; // @todo: put the opinion votes aggregation in archive ?
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

  public type User = {
    principal: Principal;
    name: ?Text;
    convictions: {
      to_update: Bool;
      profile: Profile;
    };
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