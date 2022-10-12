import Questions "questions/questions";
import Endorsements "votes/endorsements";
import Opinions "votes/opinions";
import Categorizations "votes/categorizations";
import Types "types";
import Users "users";
import Scheduler "scheduler";
import Utils "utils";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";

shared({ caller = admin_ }) actor class Godwin(parameters: Types.InputParameters) = {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;

  // For convenience: from types module
  type Question = Types.Question;
  type Endorsement = Types.Endorsement;
  type Opinion = Types.Opinion;
  type User = Types.User;
  type CategorizationArray = Types.CategorizationArray; 
  type Categorization = Types.Categorization; 

  // Members
  var users_ = Users.empty();
  var questions_ = Questions.empty();
  var endorsements_ = Endorsements.empty();
  var opinions_ = Opinions.empty();
  var categorizations_ = Categorizations.empty();
  var scheduler_ = Scheduler.Scheduler(Utils.toSchedulerParams(parameters.scheduler), Time.now());
  stable var categories_definition_ = Utils.toCategoriesDefinition(parameters.categories_definition);

  // For upgrades
  stable var users_register_ = Users.emptyRegister();
  stable var questions_register_ = Questions.emptyRegister();
  stable var endorsements_register_ = Endorsements.emptyRegister();
  stable var opinions_register_ = Opinions.emptyRegister();
  stable var categorizations_register_ = Categorizations.emptyRegister();
  stable var scheduler = scheduler_.getParams();
  stable var scheduler_last_selection_date = scheduler_.getLastSelectionDate();

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public shared query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    Utils.getQuestion(questions_, question_id);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    questions_.createQuestion(caller, title, text);
  };

  type EndorsementError = {
    #QuestionNotFound;
  };

  public shared query func getEndorsement(principal: Principal, question_id: Nat) : async Result<?Endorsement, EndorsementError> {
    Result.mapOk<Question, ?Endorsement, EndorsementError>(Utils.getQuestion(questions_, question_id), func(question) {
      endorsements_.getForUserAndQuestion(principal, question_id);
    });
  };

  public shared({caller}) func setEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Utils.getQuestion(questions_, question_id), func(question) {
      endorsements_.put(caller, question_id);
      // Update the question endorsements
      let updated_question = {
        id = question.id;
        author = question.author;
        title = question.title;
        text = question.text;
        date = question.date;
        endorsements = endorsements_.getTotalForQuestion(question.id);
        selection_stage = question.selection_stage;
        categorization_stage = question.categorization_stage;
      };
      questions_.replaceQuestion(updated_question);
    });
  };

  public shared({caller}) func removeEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Utils.getQuestion(questions_, question_id), func(question) {
      endorsements_.remove(caller, question_id);
      // Update the question endorsements
      let updated_question = {
        id = question.id;
        author = question.author;
        title = question.title;
        text = question.text;
        date = question.date;
        endorsements = endorsements_.getTotalForQuestion(question.id);
        selection_stage = question.selection_stage;
        categorization_stage = question.categorization_stage;
      };
      questions_.replaceQuestion(updated_question);
    });
  };

  type OpinionError = {
    #QuestionNotFound;
    #WrongSelectionStage;
  };

  public shared query func getOpinion(principal: Principal, question_id: Nat) : async Result<?Opinion, OpinionError> {
    Result.mapOk<Question, ?Opinion, OpinionError>(Utils.getQuestion(questions_, question_id), func(question) {
      opinions_.getForUserAndQuestion(principal, question_id);
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, opinion: Opinion) : async Result<(), OpinionError> {
    Result.chain<Question, (), OpinionError>(Utils.getQuestion(questions_, question_id), func(question) {
      Result.mapOk<(), (), OpinionError>(Utils.verifyCurrentSelectionStage(question, [#SELECTED, #ARCHIVED]), func() {
        opinions_.put(caller, question_id, opinion);
      })
    });
  };

  type CategorizationError = {
    #InsufficientCredentials;
    #InvalidCategory;
    #CategoriesMissing;
    #QuestionNotFound;
    #WrongCategorizationStage;
  };

  public shared({caller}) func setCategorization(question_id: Nat, input_categorization: CategorizationArray) : async Result<(), CategorizationError> {
    Result.chain<(), (), CategorizationError>(verifyCredentials(caller), func () {
      Result.chain<Question, (), CategorizationError>(Utils.getQuestion(questions_, question_id), func(question) {
        Result.chain<(), (), CategorizationError>(Utils.verifyCategorizationStage(question, [#ONGOING]), func() { 
          Result.mapOk<Categorization, (), CategorizationError>(Utils.getVerifiedCategorization(categories_definition_, input_categorization), func (categorization: Categorization) {
            categorizations_.put(caller, question_id, categorization);
          })
        })
      })
    });
  };

  type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials(caller: Principal) : Result<(), VerifyCredentialsError> {
    if (caller != admin_) { #err(#InsufficientCredentials); }
    else { #ok; };
  };

  public shared func run() {
    let time_now = Time.now();
    scheduler_.selectQuestion(questions_, time_now);
    scheduler_.archivedQuestion(questions_, time_now);
    scheduler_.closeCategorization(questions_, users_, opinions_, categorizations_, time_now);
  };

  public type GetOrCreateUserError = {
    #IsAnonymous;
  };

  public shared func getOrCreateUser(principal: Principal) : async Result<User, GetOrCreateUserError> {
    Utils.getOrCreateUser(users_, principal);
  };

  public shared query func getUser(principal: Principal) : async ?User {
    users_.getUser(principal);
  };

  public shared func updateConvictions(principal: Principal) : async Result<User, GetOrCreateUserError> {
    // By design, we want everybody that connects on the platform to directly be able to ask questions, vote
    // and so on before "creating" a categorization (User). So here we have to create it if not already created.
    Result.mapOk<User, User, GetOrCreateUserError>(Utils.getOrCreateUser(users_, principal), func(user){
      users_.updateConvictions(user, questions_, opinions_);
    });
  };

  system func preupgrade(){
    users_register_ := users_.getRegister();
    questions_register_ := questions_.getRegister();
    endorsements_register_ := endorsements_.getRegister();
    opinions_register_ := opinions_.getRegister();
    categorizations_register_ := categorizations_.getRegister();
    scheduler := scheduler_.getParams();
    scheduler_last_selection_date := scheduler_.getLastSelectionDate();
  };

  system func postupgrade(){
    users_ := Users.Users(users_register_);
    users_register_ := Users.emptyRegister();
    questions_ := Questions.Questions(questions_register_);
    questions_register_ := Questions.emptyRegister();
    endorsements_ := Endorsements.Endorsements(endorsements_register_);
    endorsements_register_ := Endorsements.emptyRegister();
    opinions_ := Opinions.Opinions(opinions_register_);
    opinions_register_ := Opinions.emptyRegister();
    categorizations_ := Categorizations.Categorizations(categorizations_register_);
    categorizations_register_ := Categorizations.emptyRegister();
    scheduler_ := Scheduler.Scheduler(scheduler, scheduler_last_selection_date);
  };

};
