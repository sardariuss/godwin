import Register "register";

import RBT "mo:stableRBT/StableRBTree";
import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import Option "mo:base/Option";

shared({ caller = initializer }) actor class Godwin() = {

  type SelectionStatus = {
    #TO_CATEGORIZE;
    #CATEGORIZED;
  };
  
  type QuestionStatus = {
    #CREATED;
    #SELECTED: SelectionStatus;
  };

  type Question = {
    id: Nat;
    author: Principal;
    title: Text;
    text: Text;
    status: QuestionStatus;
  };

  type Dimension = Text;
  type Sides = (Text, Text);

  type Direction = {
    #LR;
    #RL;
  };

  type Category = {
    dimension: Dimension;
    direction: Direction;
  };

  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;

  // For convenience
  type Register<B> = Register.Register<B>;

  func keyText(t: Text) : Key<Text> { { key = t; hash = Text.hash(t) } };
  func keyNat(n: Nat) : Key<Nat> { { key = n; hash = Int.hash(n) } };
  func hashEndorsement(e : Endorsement) : Hash { Int.hash(0); };

  type Endorsement = {
    #ENDORSE;
  };

  func equalEndorsement(a: Endorsement, b: Endorsement) : Bool { 
    a == b;
  };

  func toTextDir(direction: Direction) : Text {
    switch(direction){
      case(#LR){ "LR" };
      case(#RL){ "RL" };
    };
  };

  func hashCategory(c: Category) : Hash {
    Text.hash(c.dimension # toTextDir(c.direction));
  };

  func equalCategory(a: Category, b: Category) : Bool {
    (a.dimension == b.dimension) and (a.direction == b.direction);
  };

  func toTextOpinion(opinion: Opinion) : Text {
    switch(opinion){
      case(#ABS_AGREE){ "ABS_AGREE"; };
      case(#RATHER_AGREE){ "RATHER_AGREE"; };
      case(#NEUTRAL){ "NEUTRAL"; };
      case(#RATHER_DISAGREE){ "RATHER_DISAGREE"; };
      case(#ABS_DISAGREE){ "ABS_DISAGREE"; };
    };
  };

  func hashOpinion(opinion: Opinion) : Hash.Hash { 
    return Text.hash(toTextOpinion(opinion));
  };

  func equalOpinion(a: Opinion, b:Opinion) : Bool {
    return a == b;
  };

  type Opinion = {
    #ABS_AGREE;
    #RATHER_AGREE;
    #NEUTRAL;
    #RATHER_DISAGREE;
    #ABS_DISAGREE;
  };

  private stable var admin_ = initializer;

  private stable var opinion_parameters_ = Trie.empty<Opinion, Float>();
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #ABS_AGREE; hash = hashOpinion(#ABS_AGREE) }, equalOpinion, 1.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #RATHER_AGREE; hash = hashOpinion(#RATHER_AGREE) }, equalOpinion, 0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #NEUTRAL; hash = hashOpinion(#NEUTRAL) }, equalOpinion, 0.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #RATHER_DISAGREE; hash = hashOpinion(#RATHER_DISAGREE) }, equalOpinion, -0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #ABS_DISAGREE; hash = hashOpinion(#ABS_DISAGREE) }, equalOpinion, -1.0).0;

  private stable var political_categories_ = Trie.empty<Dimension, Sides>();
  political_categories_ := Trie.put(political_categories_, keyText("IDENTITY"), Text.equal, ("CONSTRUCTIVISM", "ESSENTIALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("COOPERATION"), Text.equal, ("INTERNATIONALISM", "NATIONALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("PROPERTY"), Text.equal, ("COMMUNISM", "CAPITALISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("ECONOMY"), Text.equal, ("REGULATION", "LAISSEZFAIRE")).0;
  political_categories_ := Trie.put(political_categories_, keyText("CULTURE"), Text.equal, ("PROGRESSIVISM", "CONSERVATISM")).0;
  political_categories_ := Trie.put(political_categories_, keyText("TECHNOLOGY"), Text.equal, ("ECOLOGY", "PRODUCTION")).0;
  political_categories_ := Trie.put(political_categories_, keyText("JUSTICE"), Text.equal, ("REHABILITATION", "PUNITION")).0;
  political_categories_ := Trie.put(political_categories_, keyText("CHANGE"), Text.equal, ("REVOLUTION", "REFORM")).0;

  private stable var questions_ = RBT.init<Nat, Question>();
  private stable var question_index_ : Nat = 0;

  private stable var endorsements_ = Register.empty<Endorsement>();

  private stable var opinions_ = Register.empty<Opinion>();

  private stable var categories_ = Register.empty<Category>();

  public func getQuestion(question_id: Nat) : async ?Question {
    return RBT.get<Nat, Question>(questions_, Nat.compare, question_id);
  };

  public func getQuestions() : async RBT.ScanLimitResult<Nat, Question> {
    return RBT.scanLimit<Nat, Question>(questions_, Nat.compare, 0, 10, #fwd, 10);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    let question = {
      id = question_index_;
      author = caller;
      title = title;
      text = text;
      status = #CREATED;
    };
    questions_ := RBT.put(questions_, Nat.compare, question_index_, question);
    question_index_ := question_index_ + 1;
    return question;
  };

  type GetQuestionError = {
    #QuestionNotFound;
  };
  
  func getQuestion_(question_id: Nat) : Result<Question, GetQuestionError> {
    switch(RBT.get<Nat, Question>(questions_, Nat.compare, question_id)){
      case(null){
        return #err(#QuestionNotFound);
      };
      case(?question){
        return #ok(question);
      };
    };
  };

  type VerifyStatusError = {
    #WrongStatus;
  };

  func verifyQuestionStatus_(question: Question, list_status: [QuestionStatus]) : Result<(), VerifyStatusError> {
    switch(Array.find<QuestionStatus>(list_status, func(status) { status == question.status; })){
      case(null){
        return #err(#WrongStatus);
      };
      case(?status){
        return #ok;
      };
    };
  };

  type EndorsementError = {
    #QuestionNotFound;
  };

  public shared({caller}) func getEndorsement(question_id: Nat) : async Result<?Endorsement, EndorsementError> {
    Result.mapOk<Question, ?Endorsement, EndorsementError>(getQuestion_(question_id), func(question) {
      Register.getBallot(endorsements_, caller, question_id);
    });
  };

  public shared({caller}) func setEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(getQuestion_(question_id), func(question) {
      endorsements_ := Register.putBallot(endorsements_, caller, question_id, hashEndorsement, equalEndorsement, #ENDORSE).0;
    });
  };

  public shared({caller}) func removeEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(getQuestion_(question_id), func(question) {
      endorsements_ := Register.removeBallot(endorsements_, caller, question_id, hashEndorsement, equalEndorsement).0;
    });
  };

  type OpinionError = {
    #QuestionNotFound;
    #WrongStatus;
  };

  public shared({caller}) func getOpinion(question_id: Nat) : async Result<?Opinion, OpinionError> {
    Result.mapOk<Question, ?Opinion, OpinionError>(getQuestion_(question_id), func(question) {
      Register.getBallot(opinions_, caller, question_id);
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, opinion: Opinion) : async Result<(), OpinionError> {
    Result.chain<Question, (), OpinionError>(getQuestion_(question_id), func(question) {
      Result.mapOk<(), (), OpinionError>(verifyQuestionStatus_(question, [#SELECTED(#TO_CATEGORIZE), #SELECTED(#CATEGORIZED)]), func() {
        opinions_ := Register.putBallot(opinions_, caller, question_id, hashOpinion, equalOpinion, opinion).0;
      })
    });
  };

  type CategoryError = {
    #InsufficientCredentials;
    #CategoryNotFound;
    #QuestionNotFound;
    #WrongStatus;
  };

  public shared({caller}) func getCategory(question_id: Nat) : async Result<?Category, CategoryError> {
    Result.mapOk<Question, ?Category, CategoryError>(getQuestion_(question_id), func(question) {
      Register.getBallot(categories_, caller, question_id);
    });
  };

  public shared({caller}) func setCategory(question_id: Nat, category: Category) : async Result<(), CategoryError> {
    Result.chain<(), (), CategoryError>(verifyCredentials_(caller), func () {
      Result.chain<Question, (), CategoryError>(getQuestion_(question_id), func(question) {
        Result.chain<(), (), CategoryError>(verifyQuestionStatus_(question, [#SELECTED(#TO_CATEGORIZE)]), func() {
          Result.mapOk<(), (), CategoryError>(verifyCategory_(category), func () {
            categories_ := Register.putBallot(categories_, caller, question_id, hashCategory, equalCategory, category).0;
          })
        })
      })
    });
  };

  type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials_(caller: Principal) : Result<(), VerifyCredentialsError> {
    if (caller != admin_) {
      return #err(#InsufficientCredentials);
    };
    return #ok;
  };

  type VerifyCategoryError = {
    #CategoryNotFound;
  };

  func verifyCategory_(category: Category) : Result<(), VerifyCategoryError> {
    switch(Trie.get(political_categories_, keyText(category.dimension), Text.equal)){
      case(null){
        return #err(#CategoryNotFound);
      };
      case(?category){
        return #ok;
      };
    };
  };

};
