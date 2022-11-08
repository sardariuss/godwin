import Question "questions/question";
import Questions "questions/questions";
import Endorsements "votes/endorsements";
import Opinions "votes/opinions";
import Categorizations "votes/categorizations";
import Cursor "representation/cursor";
import Types "types";
import Users "users";
import Utils "utils";
import Scheduler "scheduler";

import Result "mo:base/Result";
import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Text "mo:base/Text";
import TrieSet "mo:base/TrieSet";

shared({ caller = admin_ }) actor class Godwin(parameters: Types.Parameters) = {

  // For convenience: from base module
  type Result<Ok, Err> = Result.Result<Ok, Err>;
  type Principal = Principal.Principal;
  // For convenience: from types module
  type Question = Types.Question;
  type Endorsement = Types.Endorsement;
  type Cursor = Types.Cursor;
  type User = Types.User;
  type SchedulerParams = Types.SchedulerParams;
  type Category = Types.Category;
  type CategoryCursorArray = Types.CategoryCursorArray;
  type CategoryCursorTrie = Types.CategoryCursorTrie;

  // Members
  var users_ = Users.empty();
  var questions_ = Questions.empty();
  var endorsements_ = Endorsements.empty();
  var opinions_ = Opinions.empty();
  var categorizations_ = Categorizations.empty(TrieSet.fromArray(parameters.categories, Text.hash, Text.equal));
  var scheduler_ = Scheduler.Scheduler({ params = parameters.scheduler; last_selection_date = Time.now(); });

  // For upgrades
  stable var users_shareable_ = users_.share();
  stable var questions_shareable_ = questions_.share();
  stable var endorsements_shareable_ = endorsements_.share();
  stable var opinions_shareable_ = opinions_.share();
  stable var categorizations_shareable_ = categorizations_.share();
  stable var scheduler_shareable_ = scheduler_.share();

  public func getSchedulerParams() : async SchedulerParams {
    scheduler_.share().params;
  };

  public func getCategories() : async [Category] {
    TrieSet.toArray(categorizations_.share().categories);
  };

  public shared({caller}) func setSchedulerParams(scheduler_params : SchedulerParams) : async Result<(), VerifyCredentialsError> {
    Result.mapOk<(), (), VerifyCredentialsError>(verifyCredentials(caller), func () {
      scheduler_.setParams(scheduler_params);
    });
  };

  public type GetQuestionError = {
    #QuestionNotFound;
  };

  public shared query func getQuestion(question_id: Nat) : async Result<Question, GetQuestionError> {
    Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound);
  };

  public shared({caller}) func createQuestion(title: Text, text: Text) : async Question {
    questions_.createQuestion(caller, Time.now(), title, text);
  };

  public type EndorsementError = {
    #QuestionNotFound;
  };

  public shared query func getEndorsement(principal: Principal, question_id: Nat) : async Result<?Endorsement, EndorsementError> {
    Result.mapOk<Question, ?Endorsement, EndorsementError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
      endorsements_.getForUserAndQuestion(principal, question_id);
    });
  };

  public shared({caller}) func setEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
      endorsements_.put(caller, question_id);
      questions_.replaceQuestion(Question.updateTotalEndorsements(question, endorsements_.getTotalForQuestion(question.id)));
    });
  };

  public shared({caller}) func removeEndorsement(question_id: Nat) : async Result<(), EndorsementError> {
    Result.mapOk<Question, (), EndorsementError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
      endorsements_.remove(caller, question_id);
      questions_.replaceQuestion(Question.updateTotalEndorsements(question, endorsements_.getTotalForQuestion(question.id)));
    });
  };

  public type OpinionError = {
    #InvalidOpinion;
    #QuestionNotFound;
    #WrongSelectionStage;
  };

  public shared query func getOpinion(principal: Principal, question_id: Nat) : async Result<?Cursor, OpinionError> {
    Result.mapOk<Question, ?Cursor, OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
      opinions_.getForUserAndQuestion(principal, question_id);
    });
  };

  public shared({caller}) func setOpinion(question_id: Nat, cursor: Cursor) : async Result<(), OpinionError> {
    Result.chain<Cursor, (), OpinionError>(Result.fromOption(Cursor.verifyIsValid(cursor), #InvalidOpinion), func(cursor) {
      Result.chain<Question, (), OpinionError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        let verify_result = Result.fromOption(Question.verifyCurrentSelectionStage(question, [#SELECTED, #ARCHIVED]), #WrongSelectionStage);
        Result.mapOk<Question, (), OpinionError>(verify_result, func(question) {
          opinions_.put(caller, question_id, cursor);
        })
      })
    });
  };

  public type CategorizationError = {
    #InsufficientCredentials;
    #InvalidCategorization;
    #QuestionNotFound;
    #WrongCategorizationStage;
  };

  public shared({caller}) func setCategorization(question_id: Nat, cursor_array: CategoryCursorArray) : async Result<(), CategorizationError> {
    Result.chain<(), (), CategorizationError>(verifyCredentials(caller), func () {
      Result.chain<Question, (), CategorizationError>(Result.fromOption(questions_.findQuestion(question_id), #QuestionNotFound), func(question) {
        let verify_result = Result.fromOption(Question.verifyCategorizationStage(question, [#ONGOING]), #WrongCategorizationStage);
        Result.chain<Question, (), CategorizationError>(verify_result, func(question) {
          let verified = Result.fromOption(categorizations_.verifyBallot(Utils.arrayToTrie(cursor_array, Types.keyText, Text.equal)), #InvalidCategorization);
          Result.mapOk<CategoryCursorTrie, (), CategorizationError>(verified, func(cursor_trie: CategoryCursorTrie) {
            categorizations_.put(caller, question_id, cursor_trie);
          })
        })
      })
    });
  };

  // @todo: call in a heartbeat
  public shared func run() {
    let time_now = Time.now();
    ignore scheduler_.selectQuestion(questions_, time_now);
    ignore scheduler_.archiveQuestion(questions_, opinions_, time_now);
    ignore scheduler_.closeCategorization(questions_, users_, opinions_, categorizations_, time_now);
  };

  public type GetUserError = {
    #IsAnonymous;
  };

  public shared func findUser(principal: Principal) : async Result<User, GetUserError> {
    Result.fromOption(users_.findUser(principal), #IsAnonymous);
  };

  public shared func updateConvictions(principal: Principal) : async Result<?User, GetUserError> {
    Result.mapOk<User, ?User, GetUserError>(Result.fromOption(users_.findUser(principal), #IsAnonymous), func(_){
      users_.updateConvictions(principal, questions_, opinions_);
    });
  };

  public type VerifyCredentialsError = {
    #InsufficientCredentials;
  };

  func verifyCredentials(caller: Principal) : Result<(), VerifyCredentialsError> {
    if (caller != admin_) { #err(#InsufficientCredentials); }
    else { #ok; };
  };

  system func preupgrade(){
    users_shareable_ := users_.share();
    questions_shareable_ := questions_.share();
    endorsements_shareable_ := endorsements_.share();
    opinions_shareable_ := opinions_.share();
    categorizations_shareable_ := categorizations_.share();
    scheduler_shareable_ := scheduler_.share();
  };

  system func postupgrade(){
    users_ := Users.Users(users_shareable_);
    questions_ := Questions.Questions(questions_shareable_);
    endorsements_ := Endorsements.Endorsements(endorsements_shareable_);
    opinions_ := Opinions.Opinions(opinions_shareable_);
    categorizations_ := Categorizations.Categorizations(categorizations_shareable_);
    scheduler_ := Scheduler.Scheduler(scheduler_shareable_);
  };

};
