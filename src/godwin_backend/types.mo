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
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;
  type Time = Time.Time;

  public type Question = {
    id: Nat;
    date: Time;
    author: Principal;
    title: Text;
    text: Text;
    selected: ?Selection;
  };

  public type Selection = {
    date: Time;
    categorization: Categorization;
  };

  public type Categorization = {
    date: Time;
    status: CategorizationStatus;
  };

  public type CategorizationStatus = {
    #TO_CATEGORIZE;
    #CATEGORIZED;
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
  public func hashEndorsement(e : Endorsement) : Hash { Int.hash(0); };

  public type Endorsement = {
    #ENDORSE;
  };

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

  public func toTextOpinion(opinion: Opinion) : Text {
    switch(opinion){
      case(#ABS_AGREE){ "ABS_AGREE"; };
      case(#RATHER_AGREE){ "RATHER_AGREE"; };
      case(#NEUTRAL){ "NEUTRAL"; };
      case(#RATHER_DISAGREE){ "RATHER_DISAGREE"; };
      case(#ABS_DISAGREE){ "ABS_DISAGREE"; };
    };
  };

  public func hashOpinion(opinion: Opinion) : Hash.Hash { 
    Text.hash(toTextOpinion(opinion));
  };

  public func equalOpinion(a: Opinion, b:Opinion) : Bool {
    a == b;
  };

  public type Opinion = {
    #ABS_AGREE;
    #RATHER_AGREE;
    #NEUTRAL;
    #RATHER_DISAGREE;
    #ABS_DISAGREE;
  };

  public type SelectionParams = {
    time_interval: Time;
    number_questions: Nat;
  };

  public type CategorizationParams = {
    time_interval: Time;
    number_questions: Nat;
    min_time_elapsed: Time;
  };
}