import Register "register";
import Types "types";
import Pool "pool";
import Questions "questions";
import Categories "categories";
import Users "users";
import Convictions "convictions";

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
import Float "mo:base/Float";
import Buffer "mo:base/Buffer";

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
  type CategoryAggregationParameters = Types.CategoryAggregationParameters;
  type Conviction = Types.Conviction;
  type User = Types.User;

  private stable var admin_ = initializer;

  private stable var max_endorsement_ : Nat = 0;

  private stable var pools_parameters_ = {
    spawn = { ratio_max_endorsement = 0.5; time_elapsed_in_pool = 0; next_pool = #FISSION; };
    fission = { ratio_max_endorsement = 0.0; time_elapsed_in_pool = 1 * 24 * 60 * 60 * 1_000_000_000; next_pool = #ARCHIVE; };
    archive = { ratio_max_endorsement = 0.8; time_elapsed_in_pool = 3 * 24 * 60 * 60 * 1_000_000_000; next_pool = #FISSION; };
  };

  private stable var moderate_opinion_coef_ = 0.5;

  private stable var political_categories_ = Trie.empty<Dimension, Sides>();
  political_categories_ := Trie.put(political_categories_, Types.keyText("IDENTITY"), Text.equal, ("CONSTRUCTIVISM", "ESSENTIALISM")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("COOPERATION"), Text.equal, ("INTERNATIONALISM", "NATIONALISM")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("PROPERTY"), Text.equal, ("COMMUNISM", "CAPITALISM")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("ECONOMY"), Text.equal, ("REGULATION", "LAISSEZFAIRE")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("CULTURE"), Text.equal, ("PROGRESSIVISM", "CONSERVATISM")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("TECHNOLOGY"), Text.equal, ("ECOLOGY", "PRODUCTION")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("JUSTICE"), Text.equal, ("REHABILITATION", "PUNITION")).0;
  political_categories_ := Trie.put(political_categories_, Types.keyText("CHANGE"), Text.equal, ("REVOLUTION", "REFORM")).0;

  private stable var category_aggregation_params_ = {
    direction_threshold = 0.65;
    dimension_threshold = 0.35;
  };

  private stable var users_ = Users.empty();

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
          Result.mapOk<(), (), CategoryError>(Categories.verifyCategory(political_categories_, category), func () {
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

  public shared func run() {
    var max_endorsement = max_endorsement_;
    for ((_, question) in Questions.iter(questions_)) {
      let question_endorsement = Register.getTotalForBallot(endorsements_, question.id, Types.hashEndorsement, Types.equalEndorsement, #ENDORSE);
      switch (Pool.updateCurrentPool(question, pools_parameters_, question_endorsement, max_endorsement_)){
        case(null){};
        case(?updated_question){
          questions_ := Questions.replaceQuestion(questions_, updated_question).0;
          onPoolChanged(updated_question);
        };
      };
      if (max_endorsement < question_endorsement) {
        max_endorsement := question_endorsement;
      };
    };
    max_endorsement_ := max_endorsement;
  };

  func onPoolChanged(question: Question) {
    switch(Pool.getCurrentPool(question)){
      case(#SPAWN){};
      case(#FISSION){};
      case(#ARCHIVE){
        let categories = Categories.computeCategoriesAggregation(political_categories_, category_aggregation_params_, categories_, question.id);
        // @todo: verify if new computed categories are the same as the old ones
        var users_to_update = Trie.empty<Principal, User>();
        for ((principal, user) in Users.iter(users_)){
          switch(Register.getBallot(opinions_, principal, question.id)){
            case(null){};
            case(?opinion){
              users_to_update := Trie.put(users_to_update, Types.keyPrincipal(user.principal), Principal.equal, Users.setConvictionToUpdate(user)).0;
            };
          };
        };
        users_ := Trie.merge(users_, users_to_update, Principal.equal);
      };
    };
  };

  // Watchout: O(n)
  func computeUserConvictions(principal: Principal) : Trie<Dimension, Conviction> {
    var convictions = Trie.empty<Dimension, Conviction>();
    for ((question_id, opinion) in Trie.iter(Register.getUserBallots(opinions_, principal))){
      switch(Questions.getQuestion(questions_, question_id)){
        case(#err(_)){};
        case(#ok(question)){
          for (category in Array.vals(question.categories)){
            convictions := Convictions.addConviction(convictions, category, opinion, moderate_opinion_coef_);
          };
        };
      }
    };
    convictions;
  };

};
