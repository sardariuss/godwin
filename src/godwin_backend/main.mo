import Votes "votes";
import Types "types";
import Pool "pool";
import Questions "questions";
import Categories "categories";
import Users "users";
import Convictions "convictions";

import Array "mo:base/Array";
import Trie "mo:base/Trie";
import Text "mo:base/Text";
import Result "mo:base/Result";
import Principal "mo:base/Principal";

shared({ caller = initializer }) actor class Godwin(install_arguments: Types.InstallArguments) = {

  // For convenience: from base module
  type Trie<K, V> = Trie.Trie<K, V>;
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;

  // For convenience: from types module
  type Question = Types.Question;
  type Category = Types.Category;
  type Direction = Types.Direction;
  type OrientedCategory = Types.OrientedCategory;
  type Endorsement = Types.Endorsement;
  type Opinion = Types.Opinion;
  type Pool = Types.Pool;
  type PoolParameters = Types.PoolParameters;
  type AggregationParameters = Types.AggregationParameters;
  type Conviction = Types.Conviction;
  type User = Types.User;
  type VoteRegister<B> = Types.VoteRegister<B>;
  type Sides = Types.Sides;

  private stable var admin_ = initializer;
  private stable var max_endorsement_ : Nat = 0;
  private stable var parameters_ = {
    moderate_opinion_coef = install_arguments.moderate_opinion_coef;
    pools_parameters = install_arguments.pools_parameters;
    categories_definition = Categories.fromArray(install_arguments.categories_definition);
    aggregation_parameters = install_arguments.aggregation_parameters;
  };
  private stable var users_ = Users.empty();
  private stable var questions_ = Questions.empty();
  private stable var endorsements_ = Votes.empty<Endorsement>();
  private stable var opinions_ = Votes.empty<Opinion>();
  private stable var categories_ = Votes.empty<OrientedCategory>();

  public shared query func getCategories() : async Trie<Category, Sides> {
    return parameters_.categories_definition;
  };

  public shared query func getQuestion(question_id: Nat) : async Result<Question, Questions.GetQuestionError> {
    return Questions.getQuestion(questions_, question_id);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    let (questions, question) = Questions.createQuestion(questions_, caller, title, text);
    questions_ := questions;
    question;
  };

  type EndorsementError = {
    #QuestionNotFound;
  };

  public shared query func getEndorsement(principal: Principal, question_id: Nat) : async Result<?Endorsement, EndorsementError> {
    Result.mapOk<Question, ?Endorsement, EndorsementError>(Questions.getQuestion(questions_, question_id), func(question) {
      Votes.getBallot(endorsements_, principal, question_id);
    });
  };

  public shared({caller}) func setEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Questions.getQuestion(questions_, question_id), func(question) {
      endorsements_ := Votes.putBallot(endorsements_, caller, question_id, Types.hashEndorsement, Types.equalEndorsement, #ENDORSE).0;
    });
  };

  public shared({caller}) func removeEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Questions.getQuestion(questions_, question_id), func(question) {
      endorsements_ := Votes.removeBallot(endorsements_, caller, question_id, Types.hashEndorsement, Types.equalEndorsement).0;
    });
  };

  type OpinionError = {
    #QuestionNotFound;
    #WrongPool;
  };

  public shared query func getOpinion(principal: Principal, question_id: Nat) : async Result<?Opinion, OpinionError> {
    Result.mapOk<Question, ?Opinion, OpinionError>(Questions.getQuestion(questions_, question_id), func(question) {
      Votes.getBallot(opinions_, principal, question_id);
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, opinion: Opinion) : async Result<(), OpinionError> {
    Result.chain<Question, (), OpinionError>(Questions.getQuestion(questions_, question_id), func(question) {
      Result.mapOk<(), (), OpinionError>(Pool.verifyCurrentPool(question, [#FISSION, #ARCHIVE]), func() {
        opinions_ := Votes.putBallot(opinions_, caller, question_id, Types.hashOpinion, Types.equalOpinion, opinion).0;
      })
    });
  };

  type OrientedCategoryError = {
    #InsufficientCredentials;
    #CategoryNotFound;
    #QuestionNotFound;
    #WrongPool;
  };

  public shared query func getOrientedCategory(principal: Principal, question_id: Nat) : async Result<?OrientedCategory, OrientedCategoryError> {
    Result.mapOk<Question, ?OrientedCategory, OrientedCategoryError>(Questions.getQuestion(questions_, question_id), func(question) {
      Votes.getBallot(categories_, principal, question_id);
    });
  };

  public shared({caller}) func setOrientedCategory(question_id: Nat, category: OrientedCategory) : async Result<(), OrientedCategoryError> {
    Result.chain<(), (), OrientedCategoryError>(verifyCredentials_(caller), func () {
      Result.chain<Question, (), OrientedCategoryError>(Questions.getQuestion(questions_, question_id), func(question) {
        Result.chain<(), (), OrientedCategoryError>(Pool.verifyCurrentPool(question, [#FISSION]), func() {
          Result.mapOk<(), (), OrientedCategoryError>(Categories.verifyOrientedCategory(parameters_.categories_definition, category), func () {
            categories_ := Votes.putBallot(categories_, caller, question_id, Types.hashOrientedCategory, Types.equalOrientedCategory, category).0;
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
      let question_endorsement = Votes.getTotalVotesForBallot(endorsements_, question.id, Types.hashEndorsement, Types.equalEndorsement, #ENDORSE);
      switch (Pool.updateCurrentPool(question, parameters_.pools_parameters, question_endorsement, max_endorsement_)){
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
    switch(question.pool.current.pool){
      case(#SPAWN){};
      case(#FISSION){};
      case(#ARCHIVE){
        let categories = Categories.computeCategoriesAggregation(parameters_.categories_definition, parameters_.aggregation_parameters, categories_, question.id);
        // @todo: check if the old categories were the same
        // Update the question with the new categories
        questions_ := Questions.updateCategories(questions_, question, categories).0;
        // The users that gave their opinion on this questions have to have their convictions updated
        var users_to_update = Trie.empty<Principal, User>();
        for ((principal, user) in Users.iter(users_)){
          switch(Votes.getBallot(opinions_, principal, question.id)){
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

  public type GetOrCreateUserError = {
    #IsAnonymous;
  };

  func getOrCreateUser_(principal: Principal) : Result<User, GetOrCreateUserError> {
    if (Principal.isAnonymous(principal)){
      #err(#IsAnonymous);
    } else {
      switch(Users.getUser(users_, principal)){
        case(?user){
          #ok(user);
        };
        case(null){
          let new_user = Users.newUser(principal);
          users_ := Users.putUser(users_, new_user).0;
          #ok(new_user);
        };
      };
    };
  };

  public shared func getOrCreateUser(principal: Principal) : async Result<User, GetOrCreateUserError> {
    getOrCreateUser_(principal);
  };

  public shared query func getUser(principal: Principal) : async ?User {
    Users.getUser(users_, principal);
  };

  // Watchout: O(n)
  public shared func computeUserConvictions(principal: Principal) : async Result<User, GetOrCreateUserError> {
    Result.mapOk<User, User, GetOrCreateUserError>(getOrCreateUser_(principal), func(user){
      if (user.convictions.to_update){
        var convictions = Trie.empty<Category, Conviction>();
        for ((question_id, opinion) in Trie.iter(Votes.getUserBallots(opinions_, principal))){
          switch(Questions.getQuestion(questions_, question_id)){
            case(#err(_)){};
            case(#ok(question)){
              for (category in Array.vals(question.categories)){
                convictions := Convictions.addConviction(convictions, category, opinion, parameters_.moderate_opinion_coef);
              };
            };
          }
        };
        let updated_user = Users.setConvictions(user, convictions);
        users_ := Trie.put(users_, Types.keyPrincipal(principal), Principal.equal, updated_user).0;
        updated_user;
      } else {
        user;
      }
    });
  };

};
