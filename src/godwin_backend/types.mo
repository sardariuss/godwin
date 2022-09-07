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

  public type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    categories: [Category];
    pool_history: PoolHistory;
  };

  public type PoolHistory = [DatedPool];

  public type DatedPool = {
    date: Time;
    pool: Pool;
  };

  public type Dimension = Text;
  public type Sides = (Text, Text);

  public type Direction = {
    #LR;
    #RL;
  };

  public type Category = {
    dimension: Dimension;
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

  public func hashCategory(c: Category) : Hash {
    Text.hash(c.dimension # toTextDir(c.direction));
  };

  public func equalCategory(a: Category, b: Category) : Bool {
    (a.dimension == b.dimension) and (a.direction == b.direction);
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
    return { key = opinion; hash = hashOpinion(opinion);}
  };

  public type Pool = {
    #SPAWN;
    #FISSION;
    #ARCHIVE;
  };

  public func toTextPool(pool: Pool) : Text {
    switch(pool){
      case(#SPAWN){ "SPAWN"; };
      case(#FISSION){ "FISSION"; };
      case(#ARCHIVE){ "ARCHIVE"; };
    };
  };

  public func hashPool(pool: Pool) : Hash.Hash { 
    Text.hash(toTextPool(pool));
  };

  public func equalPool(a: Pool, b:Pool) : Bool {
    a == b;
  };

  public type PoolParameters = {
    ratio_max_endorsement: Float;
    time_elapsed_in_pool: Time;
    next_pool: Pool;
  };

  public type PoolsParameters = {
    spawn: PoolParameters;
    fission: PoolParameters;
    archive: PoolParameters;
  };

  public type CategoryAggregationParameters = {
    direction_threshold: Float;
    dimension_threshold: Float;
  };

  public type User = {
    principal: Principal;
    name: ?Text;
    convictions: {
      to_update: Bool;
      trie: Trie<Dimension, Conviction>;
    };
  };

  public type Register<B> = {
    // map<user, map<item, ballot>>
    ballots: Trie<Principal, Trie<Nat, B>>;
    // map<item, map<ballot, sum>>
    totals: Trie<Nat, Totals<B>>;
  };

  public type Totals<B> = {
    all: Nat;
    per_ballot: Trie<B, Nat>;
  };

};