import Register "register";
import Types "types";
import Pool "pool";
import Questions "questions";

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
import Time "mo:base/Time";
import Iter "mo:base/Iter";
import Order "mo:base/Order";

shared({ caller = initializer }) actor class Godwin() = {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Key<K> = Trie.Key<K>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  type Hash = Hash.Hash;
  type Register<B> = Register.Register<B>;
  type Time = Time.Time;
  type Order = Order.Order;

  // For convenience: from types module
  type Question = Types.Question;
  type Dimension = Types.Dimension;
  type Sides = Types.Sides;
  type Direction = Types.Direction;
  type Category = Types.Category;
  type Endorsement = Types.Endorsement;
  type Opinion = Types.Opinion;
  type Pool = Types.Pool;
  type PoolParameters = Types.PoolParameters;

  private stable var admin_ = initializer;

  private stable var max_endorsement_ : Nat = 0;

  private stable var change_pool_parameters_ = Trie.empty<Pool, PoolParameters>();
  change_pool_parameters_ := Trie.put(change_pool_parameters_, { key = #SPAWN; hash = Types.hashPool(#SPAWN) }, Types.equalPool, {
    ratio_max_endorsement = 0.5; time_elapsed_in_pool = 0; next_pool = #FISSION;}).0;
  change_pool_parameters_ := Trie.put(change_pool_parameters_, { key = #FISSION; hash = Types.hashPool(#FISSION) }, Types.equalPool, {
    ratio_max_endorsement = 0.0; time_elapsed_in_pool = 1 * 24 * 60 * 60 * 1_000_000_000; next_pool = #ARCHIVE; }).0;
  change_pool_parameters_ := Trie.put(change_pool_parameters_, { key = #ARCHIVE; hash = Types.hashPool(#ARCHIVE) }, Types.equalPool, {
    ratio_max_endorsement = 0.8; time_elapsed_in_pool = 3 * 24 * 60 * 60 * 1_000_000_000; next_pool = #FISSION; }).0;

  private stable var opinion_parameters_ = Trie.empty<Opinion, Float>();
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #ABS_AGREE; hash = Types.hashOpinion(#ABS_AGREE) }, Types.equalOpinion, 1.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #RATHER_AGREE; hash = Types.hashOpinion(#RATHER_AGREE) }, Types.equalOpinion, 0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #NEUTRAL; hash = Types.hashOpinion(#NEUTRAL) }, Types.equalOpinion, 0.0).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #RATHER_DISAGREE; hash = Types.hashOpinion(#RATHER_DISAGREE) }, Types.equalOpinion, -0.5).0;
  opinion_parameters_ := Trie.put(opinion_parameters_, { key = #ABS_DISAGREE; hash = Types.hashOpinion(#ABS_DISAGREE) }, Types.equalOpinion, -1.0).0;

  private stable var political_categories_ = Trie.empty<Dimension, Sides>();
  political_categories_ := Trie.put(political_categories_, Types.keyText("IDENTITY"), Text.equal, ("CONSTRUCTIVISM", "ESSENTIALISM")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("COOPERATION"), Text.equal, ("INTERNATIONALISM", "NATIONALISM")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("PROPERTY"), Text.equal, ("COMMUNISM", "CAPITALISM")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("ECONOMY"), Text.equal, ("REGULATION", "LAISSEZFAIRE")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("CULTURE"), Text.equal, ("PROGRESSIVISM", "CONSERVATISM")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("TECHNOLOGY"), Text.equal, ("ECOLOGY", "PRODUCTION")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("JUSTICE"), Text.equal, ("REHABILITATION", "PUNITION")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("CHANGE"), Text.equal, ("REVOLUTION", "REFORM")).0;

  private stable var questions_ = Questions.empty();

  private stable var endorsements_ = Register.empty<Endorsement>();

  private stable var opinions_ = Register.empty<Opinion>();

  private stable var categories_ = Register.empty<Category>();

  public shared func getQuestion(question_id: Nat) : async Result<Question, Questions.GetQuestionError> {
    return Questions.getQuestion(questions_, question_id);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async () {
    questions_ := Questions.createQuestion(questions_, caller, title, text).0;
  };

  type EndorsementError = {
    #QuestionNotFound;
  };

  public shared({caller}) func getEndorsement(question_id: Nat) : async Result<?Endorsement, EndorsementError> {
    Result.mapOk<Question, ?Endorsement, EndorsementError>(Questions.getQuestion(questions_, question_id), func(question) {
      Register.getBallot(endorsements_, caller, question_id);
    });
  };

  public shared({caller}) func setEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Questions.getQuestion(questions_, question_id), func(question) {
      endorsements_ := Register.putBallot(endorsements_, caller, question_id, Types.hashEndorsement, Types.equalEndorsement, #ENDORSE).0;
    });
  };

  public shared({caller}) func removeEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Questions.getQuestion(questions_, question_id), func(question) {
      endorsements_ := Register.removeBallot(endorsements_, caller, question_id, Types.hashEndorsement, Types.equalEndorsement).0;
    });
  };

  type OpinionError = {
    #QuestionNotFound;
    #WrongPool;
  };

  public shared({caller}) func getOpinion(question_id: Nat) : async Result<?Opinion, OpinionError> {
    Result.mapOk<Question, ?Opinion, OpinionError>(Questions.getQuestion(questions_, question_id), func(question) {
      Register.getBallot(opinions_, caller, question_id);
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, opinion: Opinion) : async Result<(), OpinionError> {
    Result.chain<Question, (), OpinionError>(Questions.getQuestion(questions_, question_id), func(question) {
      Result.mapOk<(), (), OpinionError>(Pool.verifyCurrentPool(question, [#FISSION, #ARCHIVE]), func() {
        opinions_ := Register.putBallot(opinions_, caller, question_id, Types.hashOpinion, Types.equalOpinion, opinion).0;
      })
    });
  };

  type CategoryError = {
    #InsufficientCredentials;
    #CategoryNotFound;
    #QuestionNotFound;
    #WrongPool;
  };

  public shared({caller}) func getCategory(question_id: Nat) : async Result<?Category, CategoryError> {
    Result.mapOk<Question, ?Category, CategoryError>(Questions.getQuestion(questions_, question_id), func(question) {
      Register.getBallot(categories_, caller, question_id);
    });
  };

  public shared({caller}) func setCategory(question_id: Nat, category: Category) : async Result<(), CategoryError> {
    Result.chain<(), (), CategoryError>(verifyCredentials_(caller), func () {
      Result.chain<Question, (), CategoryError>(Questions.getQuestion(questions_, question_id), func(question) {
        Result.chain<(), (), CategoryError>(Pool.verifyCurrentPool(question, [#FISSION]), func() {
          Result.mapOk<(), (), CategoryError>(verifyCategory_(category), func () {
            categories_ := Register.putBallot(categories_, caller, question_id, Types.hashCategory, Types.equalCategory, category).0;
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
      #err(#InsufficientCredentials);
    } else {
      #ok;
    }
  };

  type VerifyCategoryError = {
    #CategoryNotFound;
  };

  func verifyCategory_(category: Category) : Result<(), VerifyCategoryError> {
    switch(Trie.get(political_categories_, Types.keyText(category.dimension), Text.equal)){
      case(null){
        #err(#CategoryNotFound);
      };
      case(?category){
        #ok;
      };
    };
  };

  public shared func update() {
    var max_endorsement = max_endorsement_;
    Iter.iterate<(Nat, Question)>(Questions.iter(questions_), func((_, question), _) {
      let question_endorsement = Register.getTotalForBallot(endorsements_, question.id, Types.hashEndorsement, Types.equalEndorsement, #ENDORSE);
      switch (Pool.updateCurrentPool(question, change_pool_parameters_, question_endorsement, max_endorsement_)){
        case(#err(_)){};
        case(#ok(updated_question)){
          switch(updated_question){
            case(null){};
            case(?question){
              questions_ := Questions.replaceQuestion(questions_, question).0;
            };
          };
        };
      };
      if (max_endorsement < question_endorsement) {
        max_endorsement := question_endorsement;
      };
    });
    max_endorsement_ := max_endorsement;
  };

};
