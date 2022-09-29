import Questions "questions/questions";
import Votes "votes";
import Types "types";
import Users "users";
import Scheduler "scheduler";
import Utils "utils";

import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

shared({ caller = initializer }) actor class Godwin(parameters: Types.InputParameters) = {

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
  type AggregationParameters = Types.AggregationParameters;
  type User = Types.User;
  type VoteRegister<B> = Types.VoteRegister<B>;
  type Sides = Types.Sides;
  type Parameters = Types.Parameters;
  type InputCategorizationProfile = Types.InputCategorizationProfile; 
  type CategorizationProfile = Types.CategorizationProfile; 

  // Members
  private stable var admin_ = initializer;
  private stable var parameters_ = Utils.getParameters(parameters);
  private stable var last_selection_date_ = Time.now();
  private stable var users_ = Users.empty();
  private stable var questions_ = Questions.empty();
  private stable var endorsements_ = Votes.empty<Endorsement>();
  private stable var opinions_ = Votes.empty<Opinion>();

  public shared query func getParameters() : async Parameters {
    return parameters_;
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public shared query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    return Utils.getQuestion(questions_, question_id);
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
    Result.mapOk<Question, ?Endorsement, EndorsementError>(Utils.getQuestion(questions_, question_id), func(question) {
      Votes.getBallot(endorsements_, principal, question_id);
    });
  };

  public shared({caller}) func setEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Utils.getQuestion(questions_, question_id), func(question) {
      endorsements_ := Votes.putBallot(endorsements_, caller, question_id, Types.hashEndorsement, Types.equalEndorsement, #ENDORSE).0;
      // Update the question endorsements
      let updated_question = {
        id = question.id;
        author = question.author;
        title = question.title;
        text = question.text;
        date = question.date;
        endorsements = Votes.getTotalVotesForBallot(endorsements_, question.id, Types.hashEndorsement, Types.equalEndorsement, #ENDORSE);
        pool = question.pool;
        categorization = question.categorization;
      };
      questions_ := Questions.replaceQuestion(questions_, updated_question);
    });
  };

  public shared({caller}) func removeEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Utils.getQuestion(questions_, question_id), func(question) {
      endorsements_ := Votes.removeBallot(endorsements_, caller, question_id, Types.hashEndorsement, Types.equalEndorsement).0;
      // Update the question endorsements
      let updated_question = {
        id = question.id;
        author = question.author;
        title = question.title;
        text = question.text;
        date = question.date;
        endorsements = Votes.getTotalVotesForBallot(endorsements_, question.id, Types.hashEndorsement, Types.equalEndorsement, #ENDORSE);
        pool = question.pool;
        categorization = question.categorization;
      };
      questions_ := Questions.replaceQuestion(questions_, updated_question);
    });
  };

  type OpinionError = {
    #QuestionNotFound;
    #WrongPool;
  };

  public shared query func getOpinion(principal: Principal, question_id: Nat) : async Result<?Opinion, OpinionError> {
    Result.mapOk<Question, ?Opinion, OpinionError>(Utils.getQuestion(questions_, question_id), func(question) {
      Votes.getBallot(opinions_, principal, question_id);
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, opinion: Opinion) : async Result<(), OpinionError> {
    Result.chain<Question, (), OpinionError>(Utils.getQuestion(questions_, question_id), func(question) {
      Result.mapOk<(), (), OpinionError>(Utils.verifyCurrentPool(question, [#REWARD, #ARCHIVE]), func() {
        opinions_ := Votes.putBallot(opinions_, caller, question_id, Types.hashOpinion, Types.equalOpinion, opinion).0;
      })
    });
  };

  type CategorizationError = {
    #InsufficientCredentials;
    #InvalidCategory;
    #CategoriesMissing;
    #QuestionNotFound;
    #WrongCategorizationState;
  };

  // @todo: replace [OrientedCategory] by CategorizationProfile
  public shared({caller}) func setCategorization(question_id: Nat, input_categorization: InputCategorizationProfile) : async Result<(), CategorizationError> {
    Result.chain<(), (), CategorizationError>(verifyCredentials_(caller), func () {
      Result.chain<Question, (), CategorizationError>(Utils.getQuestion(questions_, question_id), func(question) {
        Result.chain<CategorizationProfile, (), CategorizationError>(Utils.getVerifiedCategorizationProfile(parameters_.categories_definition, input_categorization), func (categorization: CategorizationProfile) {
          Result.mapOk<Trie<Principal, [OrientedCategory]>, (), CategorizationError>(Utils.getCategorizations(question), func(categorizations: Trie<Principal, [OrientedCategory]>) {
              // Update the question categorizations
              let updated_question = {
                id = question.id;
                author = question.author;
                title = question.title;
                text = question.text;
                date = question.date;
                endorsements = question.endorsements;
                pool = question.pool;
                categorization = {
                  current = {
                    categorization = #ONGOING(Trie.put(categorizations, Types.keyPrincipal(caller), Principal.equal, []).0); // @todo: put categorization
                    date = question.categorization.current.date;
                  };
                  history = question.categorization.history;
                };
              };
              questions_ := Questions.replaceQuestion(questions_, updated_question);
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
    };
  };

  public shared func run() {
    let time_now = Time.now();
    // To reward
    switch(Scheduler.selectQuestion(questions_, last_selection_date_, parameters_.selection_interval, time_now)){
      case(null){};
      case(?question){
        questions_ := Questions.replaceQuestion(questions_, question);
        last_selection_date_ := time_now;
      };
    };
    // To archive
    switch(Scheduler.archiveQuestion(questions_, parameters_.reward_duration, time_now)){
      case(null){};
      case(?question){
        questions_ := Questions.replaceQuestion(questions_, question);
      };
    };
    // Categorization to close
    switch(Scheduler.closeCategorization(questions_, parameters_.categorization_duration, time_now, parameters_.categories_definition, parameters_.aggregation_parameters)){
      case(null){};
      case(?question){
        questions_ := Questions.replaceQuestion(questions_, question);
        // The users that gave their opinion on this questions have to have their convictions updated
        users_ := Trie.merge(users_, Users.pruneConvictions(users_, opinions_, question), Principal.equal);
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

  public shared func computeUserConvictions(principal: Principal) : async Result<User, GetOrCreateUserError> {
    // By design, we want everybody that connects on the platform to directly be able to ask questions, vote
    // and so on before "creating" a profile (User). So here we have to create it if not already created.
    Result.mapOk<User, User, GetOrCreateUserError>(getOrCreateUser_(principal), func(user){
      let updated_user = Users.computeUserConvictions(user, questions_, opinions_, parameters_.moderate_opinion_coef);
      users_ := Trie.put(users_, Types.keyPrincipal(principal), Principal.equal, updated_user).0;
      updated_user;
    });
  };

};
